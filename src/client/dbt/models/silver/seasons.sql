{{ config(location=env_var('DATA_LAKE_DIR') ~ '/silver/seasons.parquet') }}

select *
from {{ source('bronze', 'seasons') }}