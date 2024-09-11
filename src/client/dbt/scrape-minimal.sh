#!/bin/bash
cd $(dirname "$0")
PORT=$1

printf "STARTING PIPELINE\n"

# URL
export BASE_URL="localhost:$PORT"

# DATA LAKE PATHS
export DATA_LAKE=../data-lake
export BRONZE=$DATA_LAKE/bronze
export SILVER=$DATA_LAKE/silver
export GOLD=$DATA_LAKE/gold

# CREATE DIRECTORIES
[ ! -e $BRONZE/seasons ] && mkdir -p $BRONZE/seasons
[ ! -e $BRONZE/events ] && mkdir -p $BRONZE/events
[ ! -e $BRONZE/categories ] && mkdir -p $BRONZE/categories
[ ! -e $BRONZE/sessions ] && mkdir -p $BRONZE/sessions
[ ! -e $BRONZE/classifications ] && mkdir -p $BRONZE/classifications
[ ! -e $SILVER ] && mkdir -p $SILVER
[ ! -e $GOLD ] && mkdir -p $GOLD

# HELPERS
get_seasons() {
  SEASONS=$(
    curl -s "$BASE_URL/seasons" |
      jq -s -c '.[] | sort_by(-.year | tonumber)' |
      jq -c '.[] | {year: .year, id: .id}'
  )

  if [[ $(printf "$SEASONS" | wc -l) -eq 0 ]]; then
    exit 1
  fi

  printf "$SEASONS" | duckdb -c "COPY (SELECT * FROM read_json_auto('/dev/stdin')) TO '$BRONZE/seasons/seasons.csv'"
  printf "$SEASONS"
}

get_events() {
  EVENTS=$(
    curl -s "$BASE_URL/events?season_id=$1" |
      jq --arg SEASON_ID "$1" -c '.[] | {name: .name, sname: .short_name, id: .id, season_id: $SEASON_ID}'
  )

  if [[ $(printf "$EVENTS" | wc -l) -eq 0 ]]; then
    exit 1
  fi

  printf "$EVENTS" | duckdb -c "COPY (SELECT * FROM read_json_auto('/dev/stdin')) TO '$BRONZE/events' (FORMAT CSV, PARTITION_BY (season_id), OVERWRITE_OR_IGNORE)"
  printf "$EVENTS"
}

get_categories() {
  CATEGORIES=$(
    curl -s "$BASE_URL/categories?event_id=$2" |
      jq --arg SEASON_ID "$1" --arg EVENT_ID "$2" -c \
        '.[] | {name: .name, id: .id, season_id: $SEASON_ID, event_id: $EVENT_ID}'
  )

  if [[ $(printf "$CATEGORIES" | wc -l) -eq 0 ]]; then
    exit 1
  fi

  printf "$CATEGORIES" | duckdb -c "COPY (SELECT * FROM read_json_auto('/dev/stdin')) TO '$BRONZE/categories' (FORMAT CSV, PARTITION_BY (season_id, event_id), OVERWRITE_OR_IGNORE)"
  printf "$CATEGORIES"
}

get_sessions() {
  SESSIONS=$(
    curl -s "$BASE_URL/sessions?event_id=$2&category_id=$3" |
      jq -c --arg SEASON_ID "$1" --arg EVENT_ID "$2" --arg CATEGORY_ID "$3" \
        '.[] | {name: .name, id: .id, season_id: $SEASON_ID, event_id: $EVENT_ID, category_id: $CATEGORY_ID}'
  )

  if [[ $(printf "$SESSIONS" | wc -l) -eq 0 ]]; then
    exit 1
  fi

  printf "$SESSIONS" | duckdb -c "COPY (SELECT * FROM read_json_auto('/dev/stdin')) TO '$BRONZE/sessions' (FORMAT CSV, PARTITION_BY (season_id, event_id, category_id), OVERWRITE_OR_IGNORE)"
  printf "$SESSIONS"
}

get_classification() {
  CLASSIFICATION=$(
    curl -s "$BASE_URL/classification?session_id=$4" |
      jq -c --arg SEASON_ID "$1" --arg EVENT_ID "$2" --arg CATEGORY_ID "$3" --arg SESSION_ID "$4" \
        '.[] | {season_id: $SEASON_ID, event_id: $EVENT_ID, category_id: $CATEGORY_ID, session_id: $SESSION_ID, name: .name, number: .number, pos: .position, pts: .points}' |
      jq -r '"\(.season_id),\(.event_id),\(.category_id),\(.session_id),\(.name),\(.number),\(.pos),\(.pts)"'
  )

  if [[ $(printf "$CLASSIFICATION" | wc -l) -eq 0 ]]; then
    exit 1
  fi

  printf "$CLASSIFICATION" | duckdb -c "COPY (SELECT column0 AS season_id, column1 AS event_id, column2 AS category_id, column3 AS session_id, column4 AS name, column5 AS number, column6 AS pos, column7 AS pts FROM read_csv('/dev/stdin')) TO '$BRONZE/classifications' (FORMAT CSV, PARTITION_BY (season_id, event_id, category_id, session_id), OVERWRITE_OR_IGNORE)"
}

# EXPORTS FOR PARALLEL
export -f get_events
export -f get_categories
export -f get_sessions
export -f get_classification

curl -s $BASE_URL
while [[ $? -gt 0 ]]; do
  echo "waiting for webserver..."
  curl -s $BASE_URL
  sleep 5
done
echo "webserver is up!"

# BRONZE
get_seasons | jq -r '"\(.id)"' |
  parallel get_events | jq -r '"\(.season_id) \(.id)"' |
  parallel --colsep ' ' get_categories | jq -r '"\(.season_id) \(.event_id) \(.id)"' |
  parallel --colsep ' ' get_sessions | jq -r '"\(.season_id) \(.event_id) \(.category_id) \(.id)"' |
  parallel --colsep ' ' get_classification

# END
printf "COMPLETED\n"
