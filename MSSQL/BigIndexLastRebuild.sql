/* 

Get the last rebuild time for big indexes

------------------------ CHANGE LOG ------------------------
2017-12-23 - Thiago Reque
  - Adjustments for add in Github
*/

CREATE TABLE #BIG_INDEX_LIST (
	DBName	nvarchar(256),
	TableName	nvarchar(256),
	avg_fragmentation_in_percent numeric (9,2),
	IndexName	nvarchar (256),
	SchemaName	nvarchar (256),
	is_partitioned	int,
	index_size_GB	numeric (9,2),
	last_rebuild	datetime
)
go

DECLARE @SQL VARCHAR (MAX)

SET @SQL = 'USE [?]
IF (db_name() NOT IN (
	select name
	from sys.databases 
	where compatibility_level < 90
	union
	select ''master'' union 
	select ''msdb'' union 
	select ''tempdb'' union 
	select ''model'' union 
	select ''DBA'')
)
EXEC(''USE [?]
		SELECT DB_NAME() DBName, OBJECT_NAME(IPS.object_id) AS [TableName], avg_fragmentation_in_percent, SI.name [IndexName],  
		schema_name(ST.schema_id) AS [SchemaName],
		CASE WHEN (SELECT COUNT(1) FROM sys.partitions P 
				   WHERE P.object_id = SI.object_id
					 AND P.index_id = SI.index_id) > 1 THEN 1 ELSE 0 END is_partitioned,
		(CASE WHEN (PS.index_id < 2) THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count)
			ELSE lob_used_page_count + row_overflow_used_page_count END)* 8/1024/1024.0 index_size,
		MAX(STATS_DATE(IPS.object_id, S.stats_id)) last_rebuild
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL , NULL) IPS 
JOIN sys.tables ST WITH (nolock) ON IPS.object_id = ST.object_id 
JOIN sys.indexes SI WITH (nolock) ON IPS.object_id = SI.object_id AND IPS.index_id = SI.index_id 
JOIN sys.dm_db_partition_stats PS ON IPS.object_id = PS.object_id AND IPS.index_id = PS.index_id
JOIN sys.stats S ON IPS.object_id = S.object_id
WHERE ST.is_ms_shipped = 0 AND SI.name IS NOT NULL 
AND avg_fragmentation_in_percent >= CONVERT(DECIMAL, 10)
AND (CASE WHEN (PS.index_id < 2) THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count)
			ELSE lob_used_page_count + row_overflow_used_page_count END)* 8/1024/1024 > 1
GROUP BY IPS.object_id, SI.index_id, SI.object_id, avg_fragmentation_in_percent, SI.name,  
		schema_name(ST.schema_id),
		(CASE WHEN (PS.index_id < 2) THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count)
			ELSE lob_used_page_count + row_overflow_used_page_count END)* 8/1024/1024.0
ORDER BY avg_fragmentation_in_percent DESC'') '

INSERT INTO #BIG_INDEX_LIST
EXEC sp_MSforeachdb @SQL

SELECT DBName,
	TableName,
	IndexName,
	avg_fragmentation_in_percent [%_fragmentation],
	CASE is_partitioned WHEN 0 THEN 'No' ELSE 'Yes' END is_partitioned,
	index_size_GB size_GB,
	CONVERT (VARCHAR, last_rebuild, 103) [last_rebuild]
FROM #BIG_INDEX_LIST

DROP TABLE #BIG_INDEX_LIST
