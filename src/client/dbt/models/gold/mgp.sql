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
FROM {{ ref('classification') }} AS classification
LEFT JOIN {{ ref('seasons') }} AS seasons ON seasons.id = classification.season_id
LEFT JOIN {{ ref('events') }}AS events ON events.id = classification.event_id
LEFT JOIN {{ ref('categories') }} AS categories
ON categories.id = classification.category_id AND categories.event_id = classification.event_id
LEFT JOIN {{ ref('sessions') }} AS sessions ON sessions.id = classification.session_id