PORT?=8888
DATA_LAKE_DIR?=../data-lake

default:
	./src/server/seed.sh
	./src/server/kill-ws.sh $(PORT) > /dev/null || true
	DB_PATH=data.db PORT=$(PORT) go run -C ./src/server/ router.go &
	./src/client/bash/scrape-transform.sh

seed:
	./src/server/seed.sh

webserver:
	./src/server/kill-ws.sh $(PORT) > /dev/null || true
	DB_PATH=data.db PORT=$(PORT) go run -C ./src/server/ router.go &

kill-ws:
	./src/server/kill-ws.sh $(PORT)

bash-transform:
	./src/client/bash/scrape-transform.sh

bash-full:
	./src/client/bash/scrape.sh 0

bash-inc:
	./src/client/bash/scrape.sh 1000

dbt:
	DATA_LAKE_DIR=$(DATA_LAKE_DIR) sqlfluff lint src/client/dbt/models
	cd src/client/dbt && DATA_LAKE_DIR=$(DATA_LAKE_DIR) dbt build

dbt-docs:
	cd src/client/dbt && DATA_LAKE_DIR=$(DATA_LAKE_DIR) dbt docs generate && dbt docs serve
