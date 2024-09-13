PORT?=8889
DATA_LAKE_DIR?=../data-lake

default:
	./src/server/kill-ws.sh $(PORT) > /dev/null || true
	DB_PATH=./src/server/data.db PORT=$(PORT) ./src/server/router &
	./src/client/bash/scrape-transform.sh $(PORT)

webserver:
	./src/server/kill-ws.sh $(PORT) > /dev/null || true
	DB_PATH=./src/server/data.db PORT=$(PORT) ./src/server/router &
	./src/server/keep-alive.sh

build:
	go build -C ./src/server router.go ;

kill-ws:
	./src/server/kill-ws.sh $(PORT)

bash-transform:
	./src/client/bash/scrape-transform.sh $(PORT)

bash-full:
	./src/client/bash/scrape-full.sh 0 $(PORT)

bash-inc:
	./src/client/bash/scrape-full.sh 100 $(PORT)

dbt:
	./src/client/dbt/scrape-minimal.sh $(PORT)
	DATA_LAKE_DIR=$(DATA_LAKE_DIR) sqlfluff lint src/client/dbt/models
	cd src/client/dbt && DATA_LAKE_DIR=$(DATA_LAKE_DIR) dbt build

dbt-docs:
	cd src/client/dbt && DATA_LAKE_DIR=$(DATA_LAKE_DIR) dbt docs generate && dbt docs serve

sparkberg:
	./src/client/sparkberg/scrape-minimal.sh $(PORT)
	cd src/client/sparkberg && python mgp.py

nuke:
	rm -rf src/client/data-lake
