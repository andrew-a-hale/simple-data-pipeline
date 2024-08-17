{{ config(location=env_var('DATA_LAKE_DIR') ~ '/gold/mgp.parquet') }}

select
  seasons.year
  , events.name as event_name
  , events.sname as event_short_name
  , categories.name as category
  , sessions.name as session_name
  , classification.rider_name
  , classification.rider_number
  , classification.rider_position
  , classification.rider_points
from {{ ref('stg_mgp__classification') }} as classification
left join
  {{ ref('stg_mgp__seasons') }} as seasons
  on classification.season_id = seasons.id
left join
  {{ ref('stg_mgp__events') }} as events
  on classification.event_id = events.id
left join {{ ref('stg_mgp__categories') }} as categories
  on
    classification.category_id = categories.id
    and classification.event_id = categories.event_id
left join
  {{ ref('stg_mgp__sessions') }} as sessions
  on classification.session_id = sessions.id
