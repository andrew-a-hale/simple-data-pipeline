#!/bin/bash
set -e

cd $(dirname "$0")

printf "Downloading seed files...\n"

# setup
db_path='./data.db'
seed_path='./seed'
[ -e "$db_path" ] && rm "$db_path"
[ -e "$seed_path" ] && rm -rf "$seed_path"
mkdir -p "$seed_path"

# download seed files from github
wget -q -P $seed_path "https://github.com/andrew-a-hale/open-motogp/raw/master/data-lake/silver/seasons.parquet"
wget -q -P $seed_path "https://github.com/andrew-a-hale/open-motogp/raw/master/data-lake/silver/events.parquet"
wget -q -P $seed_path "https://github.com/andrew-a-hale/open-motogp/raw/master/data-lake/silver/categories.parquet"
wget -q -P $seed_path "https://github.com/andrew-a-hale/open-motogp/raw/master/data-lake/silver/sessions.parquet"
wget -q -P $seed_path "https://github.com/andrew-a-hale/open-motogp/raw/master/data-lake/silver/classifications.parquet"

printf "Creating data.db...\n"

# setup database
duckdb $db_path -c "create table seasons as select * from '$seed_path/seasons.parquet'"
duckdb $db_path -c "create table events as select * from '$seed_path/events.parquet'"
duckdb $db_path -c "create table categories as select * from '$seed_path/categories.parquet'"
duckdb $db_path -c "create table sessions as select * from '$seed_path/sessions.parquet'"
duckdb $db_path -c "create table classifications as select * from '$seed_path/classifications.parquet'"

# remove seed files
rm -rf $seed_path

printf "Seeding complete\n"

