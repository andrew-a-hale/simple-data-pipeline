select *
from read_csv('{{ env_var('DATA_LAKE_DIR') }}/bronze/categories/**/*.csv', filename = true)