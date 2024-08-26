from pyspark.sql import SparkSession
from pyspark.sql.functions import col

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
    .getOrCreate()
)

TYPES = ["seasons", "events", "categories", "sessions", "classifications"]

def read_bronze_layer(session, type):
    assert type in TYPES
    return (
        session.read
        .option("header", True)
        .option("recursiveFileLookup", True)
        .csv(f"../data-lake/bronze/{type}/") 
    )

def write_to_dest_layer(session, df, type):
    (
        df.writeTo(f"silver.{type}")
        .using("iceberg")
        .tableProperty("write.merge.isolation-level", "snapshot")
        .createOrReplace()
    )


# Write-Audit-Publish (WAP) Pattern
## Write to silver
spark.sql("create database if not exists silver")

seasons = read_bronze_layer(spark, "seasons")
write_to_dest_layer(spark, seasons, "seasons")

events = read_bronze_layer(spark, "events")
write_to_dest_layer(spark, events, "events")

categories = read_bronze_layer(spark, "categories")
write_to_dest_layer(spark, categories, "categories")

sessions = read_bronze_layer(spark, "sessions")
write_to_dest_layer(spark, sessions, "sessions")

classifications = read_bronze_layer(spark, "classifications")
write_to_dest_layer(spark, classifications, "classifications")

## Write to gold
spark.sql("create database if not exists gold")
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
    .createOrReplace()
)

## Audit


## Publish

