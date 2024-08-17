{{ config(
    location=env_var('DATA_LAKE_DIR') ~ '/silver/classifications.parquet'
  )
}}

select
  season_id
  , event_id
  , category_id
  , session_id
  , name as rider_name
  , number as rider_number
  , pos as rider_position
  , pts as rider_points
from {{ source('bronze', 'classifications') }}
