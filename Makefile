PORT?=8888

default:
	./src/server/seed.sh
	./src/server/kill-ws.sh $(PORT) > /dev/null || true
	DB_PATH=data.db PORT=$(PORT) go run -C ./src/server/ router.go &
	./src/client/bash/scrape-minimal.sh

seed:
	./src/server/seed.sh

webserver:
	./src/server/kill-ws.sh $(PORT) > /dev/null || true
	DB_PATH=data.db PORT=$(PORT) go run -C ./src/server/ router.go &

kill-ws:
	./src/server/kill-ws.sh $(PORT)

bash-minimal:
	./src/client/bash/scrape-minimal.sh

bash-full:
	./src/client/bash/scrape.sh 0

bash-inc:
	./src/client/bash/scrape.sh 1000