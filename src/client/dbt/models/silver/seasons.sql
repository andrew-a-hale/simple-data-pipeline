select *
from read_csv('{{ var('RAW_SEASONS') }}', filename = true)