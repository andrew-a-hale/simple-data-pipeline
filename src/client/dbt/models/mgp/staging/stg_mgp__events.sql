{{ config(location=env_var('DATA_LAKE_DIR') ~ '/silver/events.parquet') }}

select *
from {{ source('bronze', 'events') }}
