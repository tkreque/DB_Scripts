USE [<datanaseName>]
GO

SELECT
    DB_NAME() AS [DatabaseName],
    T3.name AS [TableName],
    T1.name AS [IndexName],
    T2.index_type_desc AS [IndexType],
    T1.rowcnt AS [RowCount],
    T2.avg_fragmentation_in_percent AS [AVG_FragmentationInPercent]
FROM
    sys.sysindexes T1
    INNER JOIN sys.dm_db_index_physical_stats(DB_ID(),NULL,NULL,NULL,NULL) T2
        ON T1.id = T2.object_id AND T1.indid = T2.index_id
    INNER JOIN sys.tables T3
        ON T2.object_id = T3.object_id
ORDER BY T2.avg_fragmentation_in_percent DESC
GO