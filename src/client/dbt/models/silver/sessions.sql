select *
from read_csv('{{ var('RAW_SESSIONS') }}', filename = true)