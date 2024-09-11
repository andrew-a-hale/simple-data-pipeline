from pyspark.sql import SparkSession
from pyspark.sql.functions import col, isnull

## TODO: consider expireSnapshots
## TODO: consider deleteOrphanFiles
## TODO: consider rewriteDataFiles
## TODO: consider rewriteManifests

TYPES = ["seasons", "events", "categories", "sessions", "classifications"]

class NullCheckError(Exception):
    def __init__(self):
        return super().__init__(self)

def check_nulls(session, table, dim):
    assert dim in ["year", "event", "category", "session"]
    df = (
        session.read
        .option("BRANCH", "audit_branch")
        .table(table)
        .filter(isnull(col(dim)))
    )

    if not df.isEmpty():
        raise NullCheckError(f"Error: Found Nulls in column {dim}")

def read_bronze_layer(session, type):
    assert type in TYPES
    return (
        session.read
        .option("header", True)
        .option("recursiveFileLookup", True)
        .csv(f"../data-lake/bronze/{type}/") 
    )

def write_to_silver_layer(session, df, type):
    assert type in TYPES
    (
        df.writeTo(f"silver.{type}")
        .using("iceberg")
        .tableProperty("write.merge.isolation-level", "snapshot")
        .createOrReplace()
    )

def move_from_bronze_to_silver(spark, type):
    write_to_silver_layer(spark, read_bronze_layer(spark, type), type)

def write_to_gold_layer(spark):
    (
        spark.sql("""\
    SELECT
        seasons.year,
        events.name AS event,
        events.sname AS event_short,
        categories.name AS category,
        sessions.name AS session,
        classifications.name AS rider_name,
        classifications.number AS rider_number,
        classifications.pos as position,
        classifications.pts as points
    FROM silver.classifications
    LEFT JOIN silver.seasons ON seasons.id = classifications.season_id
    LEFT JOIN silver.events ON events.id = classifications.event_id
    LEFT JOIN silver.categories ON categories.id = classifications.category_id AND categories.event_id = classifications.event_id
    LEFT JOIN silver.sessions ON sessions.id = classifications.session_id"""
        )
        .writeTo("gold.mgp")
        .using("iceberg")
        .tableProperty("write.merge.isolation-level", "snapshot")
        .tableProperty("write.wap.enabled", "true")
        .createOrReplace()
    )

# taken from https://medium.com/@gmurro/concurrent-writes-on-iceberg-tables-using-pyspark-fd30651b2c97
spark = (
    SparkSession.builder.master("local[*]")
    .appName("mgp")
    .config(
        "spark.jars.packages",
        "org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.5.0,org.apache.iceberg:iceberg-hive-runtime:1.5.0",
    )
    .config(
        "spark.sql.extensions",
        "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
    )
    .config(
        "spark.sql.catalog.spark_catalog", "org.apache.iceberg.spark.SparkCatalog"
    )
    .config("spark.sql.catalog.spark_catalog.type", "hadoop")
    .config("spark.sql.catalog.spark_catalog.warehouse", "../data-lake/iceberg")
    .config("spark.wap.branch", "audit_branch")
    .getOrCreate()
)

# Write-Audit-Publish (WAP) Pattern
## Write to silver
spark.sql("create database if not exists silver")
move_from_bronze_to_silver(spark, "seasons")
move_from_bronze_to_silver(spark, "events")
move_from_bronze_to_silver(spark, "categories")
move_from_bronze_to_silver(spark, "sessions")
move_from_bronze_to_silver(spark, "classifications")

## Write to gold
spark.sql("create database if not exists gold")
write_to_gold_layer(spark)

## Audit
dims = ["year", "event", "category", "session"]
for dim in dims:
    check_nulls(spark, "gold.mgp", dim)

## Publish
spark.sql("call spark_catalog.system.fast_forward('gold.mgp', 'main', 'audit_branch')")

## Cleanup
spark.conf.unset("spark.wap.branch")
spark.sql("alter table gold.mgp unset tblproperties ('write.wap.enabled')")
spark.sql("alter table gold.mgp drop branch `audit_branch`")
