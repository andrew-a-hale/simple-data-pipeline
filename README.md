# A Simple Data Pipeline

This project is simple mostly self-contained data pipeline with source (server)
and destination (client). This is a test-bed for testing data related tooling
as locally as possible but with a clear division between server and client.

## Getting Started

0. Be in a unix-like environment
1. Install `duckdb`
2. Install `go`
3. Run `make [PORT=<port>]`
  - If port is missing defaults to 8889.
  - To test if the webserver is up use: `curl "localhost:8888/"` in another terminal.
  - If you want to run the dbt variant you will need to install `dbt` and `dbt-duckdb`
    1. Create a `venv` in the `dbt` folder
    2. Activate the virtual environment
    3. Run `make dbt`
  - If you want to run the spark + iceberg variant you will need to do the following:
    1. Create a `venv` in the `sparkberg` folder
    2. Activate the virtual environment
    3. Run `make sparkberg`
4. Run `make kill-ws` to kill background webserver kill you are done

There are a few other commands in the Makefile to simplify testing.

## Server

The Server loosely emulates the MOTOGP API and is seeded by parquet files
directly from a public github repo. These files are quite small since this is
just a small subset of the results data and then is heavily compressed by the
parquet format.

## Client

In the client folder are the data pipeline scripts that make use of the server.

Here is a table of the implemented features in each:

| Feature | Bash Transform | Bash Full | Bash Minimal + dbt | Bash Minimal + Spark + Iceberg |
|---------|:------------:|:----:|:---:|:--:|
| Multicore | x | x | x | x |
| Logging | | x | x | x |
| Metrics | | x | | |
| Data Quality | | x | x | x |
| Incremental | | x | | |
| Stateful | | x | | |
| ACID | | | | x |
| Time-Travel | | | | x |

### Bash

The client has 3 main parts:

1. Data Pipeline
2. `queue.db` to manage the state of the data pipeline
3. Data storage as a data-lake

#### Data Pipeline

The Data Pipeline is a collection of ideas about building pipelines with bash.
The two key takeaways should be `duckdb` is amazing and you can get a lot of
work done very efficiently with `bash`.

The key ideas are:

- Performance
- Composing simple commands like curl, jq, and parallel
- Data processing anywhere with `duckdb`
- Idempotency
- Simple logging, metrics, and data quality
- Incremental Data Pipeline

In the Bash Transform script State, Logging, Metrics and Data Quality are removed.

#### Data Storage

The data is stored as files intended for cheap blob storage and massively
parallel compute, instead of highly optimised file formats with index
maintenance used by tradition databases.[^1]

### dbt

`dbt` provides a nice frontend for `duckdb` allowing to structure our
transformation code is a sane way and get lineage, documentation, testing, and
logging with little investment.

With the `dbt-duckdb` extension we get the ability to create external
materialisations and use external sources. This allows us to use blob storage
as a database and duckdb as a compute engine.

Unfortunately `dbt-duckdb` does not yet support incremental and snapshot with
external materialisations, however this seems like a bad idea. As powerful as
this extension is we are missing nice features like time-travel and ACID. If
you are making a very simple data pipeline for immutable data, for example log
aggregation, this would be a cheap and simple approach.

### Iceberg

Iceberg has been a technology that has interested me for a long time. It
appears to be the most feature complete way to Tables in Blob Storage. It gives
is ACID-compliant, has time-travel, and easily allow for a Write-Audit-Publish
(WAP) pattern.

The WAP pattern is simple because Iceberg supports git-like branchs and
switching a branch is a metadata operation. Otherwise it feels like regular
spark.


[^1]: In recent years there has been a move to separate the databases into 3
separate components; Storage, Compute, and Catalog.
