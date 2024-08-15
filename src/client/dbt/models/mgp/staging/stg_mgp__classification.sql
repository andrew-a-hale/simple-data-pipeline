{{ config(location=env_var('DATA_LAKE_DIR') ~ '/silver/classifications.parquet') }}

select 
    season_id
    , event_id
    , category_id
    , session_id
    , name
    , number
    , pos as position
    , pts as points
from {{ source('bronze', 'classifications') }}