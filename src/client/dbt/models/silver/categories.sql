select *
from read_csv('{{ var('RAW_CATEGORIES') }}', filename = true)