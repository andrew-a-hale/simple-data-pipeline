select 
    season_id
    , event_id
    , category_id
    , session_id
    , name
    , number
    , pos as position
    , pts as points
from read_csv('{{ var('RAW_CLASSIFICATIONS') }}', filename = true, nullstr = 'null')