# A Simple Data Pipeline

This project is simple mostly self-contained data pipeline with source (server)
and destination (client). This is a test-bed for testing data related tooling as
locally as possible but with a clear division between server and client.

## Getting Started

1. Install `duckdb`
2. Install `go`
3. Run `make [PORT=<port>]`
    - if port is missing defaults to 8888.
    - To test if the webserver is up use: `curl "localhost:8888/"` in another terminal.
4. Run `make kill-ws` to kill background webserver kill you are done

There are a few other commands in the Makefile to simplify testing.

## Server

The Server loosely emulates the MOTOGP API and is seeded by parquet files
directly from a public github repo. These files are quite small since this is
just a small subset of the results data and then is heavily compressed by the
parquet format.

## Client

Here is the data pipeline scripts that make use of the server live.

Here is a table of the implemented features in each:

| Feature | Bash Transform | Bash Full | Bash Minimal + dbt |
|---------|:------------:|:----:|:---:|
| Multicore | x | x | x |
| Logging | | x | |
| Metrics | | x | |
| Data Quality | | x | x |
| Incremental | | x | |
| Stateful | | x | |

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

### dbt

Placeholder

#### Data Storage

The data is stored as files intended for cheap blob storage and massively
parallel compute, instead of highly optimised file formats with index
maintenance.[^1]

[^1]: In recent years there has been a move to separate the databases into 3
separate components; Storage, Compute, and Catalog.
