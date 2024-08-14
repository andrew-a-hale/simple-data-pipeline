select 
    season_id
    , event_id
    , category_id
    , session_id
    , name
    , number
    , pos as position
    , pts as points
from read_csv('{{ env_var('DATA_LAKE_DIR') }}/bronze/classifications/**/*.csv', filename = true, nullstr = 'null')