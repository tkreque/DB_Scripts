--- INDEXES FRAGMENTADOS

CREATE TABLE #defrag (
    DB VARCHAR(MAX)
   ,Tabela VARCHAR(MAX)
   ,[Index] VARCHAR(MAX)
   ,AvgFragmentation FLOAT
   ,[PageCount] INT
)
DECLARE @sql VARCHAR(MAX) = '
USE [?];

DECLARE @DB INT = DB_ID() --Declaração de variável para adaptação do script a bases com compatibility level 80 (SQL2000)
INSERT INTO #defrag
SELECT DB_NAME(@DB) AS [Database], 
dbschemas.[name] + ''.'' + dbtables.[name] AS [Table], 
dbindexes.[name] AS [Index],
indexstats.avg_fragmentation_in_percent,
indexstats.page_count
FROM sys.dm_db_index_physical_stats(@DB, NULL, NULL, NULL, NULL) AS indexstats
INNER JOIN sys.tables dbtables ON dbtables.[object_id] = indexstats.[object_id]
INNER JOIN sys.schemas dbschemas ON dbtables.[schema_id] = dbschemas.[schema_id]
INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
                                   AND indexstats.index_id = dbindexes.index_id
WHERE indexstats.database_id = @DB
  AND indexstats.page_count >= 100
  AND indexstats.avg_fragmentation_in_percent >= 10
  AND indexstats.index_type_desc <> ''HEAP''
ORDER BY indexstats.avg_fragmentation_in_percent DESC'
exec master.sys.sp_MSforeachdb @sql

SELECT * FROM #defrag
DROP TABLE #defrag
GO

--- STATISTICS
CREATE TABLE #stats (
    DB VARCHAR(MAX)
   ,Tabela VARCHAR(MAX)
   ,Estatistica VARCHAR(MAX)
   ,RowModCtrl INT	
   ,UpdateDate VARCHAR(MAX)
)
DECLARE @sql VARCHAR(MAX) = '
USE [?];

INSERT INTO #stats
SELECT DB_NAME(DB_ID()) AS DatabaseName
      ,OBJECT_NAME(s.object_id) AS ObjectName
      ,s.name AS StatisticName
	  ,si.rowmodctr AS RowModCtr
	  --STATS_DATE(s.object_id, s.stats_id) AS StatisticUpdateDate
      ,CONVERT(VARCHAR(20), STATS_DATE(s.object_id, s.stats_id), 103) + '' '' + CONVERT(VARCHAR(20), STATS_DATE(s.object_id, s.stats_id), 108) AS StatisticUpdateDate
FROM sys.stats AS s
INNER JOIN sys.objects AS o ON o.object_id = s.object_id
                           AND o.type = ''U''
INNER JOIN sys.sysindexes AS si ON si.name = s.name
                                AND si.rowmodctr > 0
WHERE DATEDIFF(DAY, STATS_DATE(s.object_id, s.stats_id), GETDATE()) > 1
ORDER BY STATS_DATE(s.object_id, s.stats_id)'
exec master.sys.sp_MSforeachdb @sql

SELECT * FROM #stats
DROP TABLE #stats
GO

--- HEAP TABLE
CREATE TABLE #heap (
  DB VARCHAR(MAX)
   ,Tabela VARCHAR(MAX)
)
DECLARE @sql VARCHAR(MAX) = '
USE [?];

DECLARE @DB INT = DB_ID() 
INSERT INTO #heap
SELECT DB_NAME(@DB) AS [Database]
      ,t.name AS Tabela 
FROM sys.indexes AS i
INNER JOIN sys.tables AS t ON t.[object_id] = i.[object_id]
WHERE i.type = 0
  AND t.type = ''U'' '
exec master.sys.sp_MSforeachdb @sql

SELECT * FROM #heap
DROP TABLE #heap
GO

--- MISSING INDEXES 
CREATE TABLE #idx (
    DB VARCHAR(MAX)
   ,Tabela VARCHAR(MAX)
   ,Quantidade INT
)
DECLARE @sql VARCHAR(MAX) = '
USE [?];

DECLARE @DB INT = DB_ID() 
INSERT INTO #idx
SELECT DB_NAME(@DB) AS [Database]
      ,OBJECT_NAME(MID.object_id) AS Tabela
      ,COUNT(*) AS Quantidade
FROM sys.dm_db_missing_index_group_stats AS MIGS 
     INNER JOIN sys.dm_db_missing_index_groups AS MIG 
         ON MIGS.group_handle = MIG.index_group_handle 
     INNER JOIN sys.dm_db_missing_index_details AS MID 
         ON MIG.index_handle = MID.index_handle 
WHERE database_id = @DB
      AND MIGS.last_user_seek >= DATEDIFF(month, GetDate(), -1) 
GROUP BY MID.object_id '
exec master.sys.sp_MSforeachdb @sql
SELECT * FROM #idx
DROP TABLE #idx
GO

--- DUPLICATE INDEXES 
CREATE TABLE #idx (
    DB VARCHAR(MAX)
   ,Tabela VARCHAR(MAX)
   ,[Index] VARCHAR(MAX)
   ,Duplicidade VARCHAR(MAX)
)
DECLARE @sql VARCHAR(MAX) = '
USE [?];

-- exact duplicates
with indexcols
as (
select

object_id as id
, index_id as indid
, name
, (
select
case keyno
when 0 then null
else colid
end as [data()]
from sys.sysindexkeys as k
where k.id = i.object_id
and k.indid = i.index_id
order by
keyno
, colid
for xml path('''')
) as cols
, (
select
case keyno
when 0 then colid
else null
end as [data()]
from sys.sysindexkeys as k
where k.id = i.object_id
and k.indid = i.index_id
order by
colid
for xml path('''')) as inc
from sys.indexes as i)
INSERT INTO #idx
select
DB_NAME       (db_id()) as ''Database'',
object_schema_name(c1.id) + ''.'' + object_name(c1.id) as ''table''
, c1.name as ''index''
, c2.name as ''exactduplicate''
from indexcols as c1
join indexcols as c2
on c1.id = c2.id
and c1.indid < c2.indid
and c1.cols = c2.cols
and c1.inc = c2.inc'

exec master.sys.sp_MSforeachdb @sql
SELECT * FROM #idx
DROP TABLE #idx
GO

--- NON-USED INDEXES 
CREATE TABLE #idx (
    DB VARCHAR(MAX)
   ,Tabela VARCHAR(MAX)
   ,TipoObjeto VARCHAR(MAX)
   ,[Index] VARCHAR(MAX)
   ,TipoIndice VARCHAR(MAX)
)
DECLARE @sql VARCHAR(MAX) = '
USE [?];

INSERT INTO #idx
SELECT DB_NAME(DB_ID()) AS [Database] 
      ,SCH.name + ''.'' + OBJ.name AS ObjectName 
      ,OBJ.type_desc AS ObjectType 
      ,IDX.name AS IndexName 
      ,IDX.type_desc AS IndexType 
FROM sys.indexes AS IDX 
GO