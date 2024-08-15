{{ config(location=env_var('DATA_LAKE_DIR') ~ '/gold/mgp.parquet') }}

SELECT
    seasons.year,
    events.name AS event_name,
    events.sname AS event_short_name,
    categories.name AS category,
    sessions.name AS session,
    classification.name AS rider_name,
    classification.number AS rider_number,
    classification.position,
    classification.points
FROM {{ ref('stg_mgp__classification') }} AS classification
LEFT JOIN {{ ref('stg_mgp__seasons') }} AS seasons ON seasons.id = classification.season_id
LEFT JOIN {{ ref('stg_mgp__events') }}AS events ON events.id = classification.event_id
LEFT JOIN {{ ref('stg_mgp__categories') }} AS categories
ON categories.id = classification.category_id AND categories.event_id = classification.event_id
LEFT JOIN {{ ref('stg_mgp__sessions') }} AS sessions ON sessions.id = classification.session_id