FROM golang:bookworm AS builder

COPY . /app
WORKDIR /app

RUN apt update -y \
  && apt install -y python3 unzip python3-pip curl parallel jq \
  && wget https://github.com/duckdb/duckdb/releases/download/v1.0.0/duckdb_cli-linux-amd64.zip \
  && unzip duckdb_cli-linux-amd64.zip \
  && python3 -m pip install -r requirements.txt --break-system-packages \
  && go build -C /app/src/server router.go

WORKDIR /app

ENTRYPOINT ["make", "webserver"]
