{{ config(location=env_var('DATA_LAKE_DIR') ~ '/silver/categories.parquet') }}

select *
from {{ source('bronze', 'categories') }}
