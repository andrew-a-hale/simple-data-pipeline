{{ config(location=env_var('DATA_LAKE_DIR') ~ '/silver/sessions.parquet') }}

select *
from {{ source('bronze', 'sessions') }}