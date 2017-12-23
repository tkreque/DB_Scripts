select max(data)
from (
	select max(last_user_lookup) data
	from sys.dm_db_index_usage_stats
	union all
	select max(last_user_scan)
	from sys.dm_db_index_usage_stats
	union all
	select max(last_user_update)
	from sys.dm_db_index_usage_stats
	union all
	select max(last_user_seek)
	from sys.dm_db_index_usage_stats
) tbl