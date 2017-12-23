/*

(Thiago Leite) 10.09.2010 - Executar o print antes de executar o comando

--- Histórico de alterações ---
Thiago Reque - 19/03/2012
  - Alterado o comando de UPDATE para casos de bases Case Sensitive;


*/


USE [master]
GO
IF (SELECT OBJECT_ID('sp_RebuildIndexesOnline'))>0
	DROP PROCEDURE sp_RebuildIndexesOnline
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_RebuildIndexesOnline] (
	@maxfrag float = 15.0
	, @mindensity float = 75.0
	, @databasename varchar(255)
	, @online varchar(3) = 'ON'
	, @fullprocess varchar(3) = 'ON')
AS 
/*
Created by Lara Rubbelke
7/29/2007

ap_RebuildIndexes is a process which will assess
the level of fragmentation of all indexes in a 
database and reorganize those indexes which fall 
outside the specified parameters.

ap_RebuildIndexes accepts the following parameters:
@maxfrag	The maximum level of acceptable fragmentation 
@mindensity	The minimum level of acceptable density
@databasename	The database to assess and reorganize
@online		Pass 'ON' to issue the reoganization ONLINE 
			Pass 'OFF' to issue the normal reorganization
@fullprocess	Pass 'ON' to defragment all indexes
			Pass 'OFF' to only defragment indexes which may
			process with the ONLINE option.  Note:  Some
			indexes may not process ONLINE. A partitioned index
			or a clustered index with LOB data or a non-clustered
			index which includes a column with LOB data will not be 
			processed ONLINE.  
No indexes will be defragmented if the procedure is executed 
with @online = 'OFF' and @fullprocess = 'OFF'.

This procedure assumes that a partitioned index will not
be processed ONLINE.  If an index is partitioned, the following
options are available:
	1.  Rebuild or reorganize the entire index ONLINE or offline
	2.  Reorganize each index partition ONLINE
	3.  Rebuild each index partition offline

Example:
EXEC ap_RebuildIndexes @maxfrag=15.0, @mindensity=90.0
		, @databasename='AdventureWorks', @online='ON'
		, @fullprocess='OFF'
*/
SET NOCOUNT ON;
DECLARE @schemaname sysname;
DECLARE @objectname sysname;
DECLARE @indexname sysname;
DECLARE @indexid int; 
DECLARE @Alloc_unit_type_desc varchar(18);
DECLARE @currentfrag float;
DECLARE @currentdensity float;
DECLARE @partitionnum varchar(10);
DECLARE @partitioncount bigint;
DECLARE @indextype varchar(18);
DECLARE @onlinestatus varchar(3);
DECLARE @updatecommand varchar(max);
DECLARE @command varchar(max);

-- ensure the temporary table does not exist
IF (SELECT object_id('tempdb..#work_to_do')) IS NOT NULL
	DROP TABLE #work_to_do;

--Create the temporary table.  We are using a 
--temporary table (versus a table variable)
--since we need to pass this table into dynamic SQL.
CREATE TABLE #work_to_do(
	IndexID int not null
	, IndexName varchar(255) null
	, TableName varchar(255) null
	, Tableid int not null
	, SchemaName varchar(255) null
	, IndexType varchar(18) not null
	, Alloc_unit_type_desc varchar(18) not null
	, PartitionNumber varchar(18) not null
	, PartitionCount int null
	, CurrentDensity float not null
	, CurrentFragmentation float not null
);

--Select indexes which fall within the specified parameters
--and have a minimum of 8 data pages.
INSERT INTO #work_to_do(
	IndexID, Tableid,  IndexType, Alloc_unit_type_desc, PartitionNumber, CurrentDensity, CurrentFragmentation
	)
	SELECT
		fi.index_id 
		, fi.object_id 
		, fi.index_type_desc AS IndexType
		, Alloc_unit_type_desc
		, cast(fi.partition_number as varchar(10)) AS PartitionNumber
		, fi.avg_page_space_used_in_percent AS CurrentDensity
		, fi.avg_fragmentation_in_percent AS CurrentFragmentation
	FROM sys.dm_db_index_physical_stats(db_id(@databasename), NULL, NULL, NULL, 'SAMPLED') AS fi 
	WHERE	(fi.avg_fragmentation_in_percent >= @maxfrag 
	OR		fi.avg_page_space_used_in_percent < @mindensity)
	AND		page_count> 8
	AND		fi.index_id > 0
	AND		fi.Alloc_unit_type_desc <> 'LOB_DATA'

--Assign the index names, schema names, table names and partition counts
--Denote any clustered or non-clustered index which contains 
--data types not supported with ONLINE index rebuild 
SET @updatecommand = 'UPDATE #work_to_do SET TableName = o.name, SchemaName = s.name, IndexName = i.Name 
	,PartitionCount = (SELECT COUNT(*) pcount
		FROM ' 
		+ QUOTENAME(@databasename) + '.sys.partitions p
		where  p.object_id = w.Tableid 
		AND p.index_id = w.Indexid)
	, Alloc_unit_type_desc = CASE
	WHEN EXISTS(SELECT * FROM ' + QUOTENAME(@databasename) + '.sys.columns c
		WHERE w.TableID = c.object_id
		AND w.IndexType = ''CLUSTERED INDEX''
		AND (system_type_id in (34, 35, 99, 241)
		OR (system_type_id in (165, 167, 231) AND max_length = -1)))
		THEN ''LOB_DATA''
	WHEN EXISTS(SELECT * FROM ' + QUOTENAME(@databasename) + '.sys.index_columns ic
		INNER JOIN ' + QUOTENAME(@databasename) + '.sys.columns c
		ON ic.column_id = c.column_id
		AND ic.object_id = c.object_id
		WHERE w.tableid = ic.object_id
		AND w.indexid = ic.index_id
		AND w.indextype = ''NONCLUSTERED INDEX''
		AND (system_type_id in (34, 35, 99, 241)
		OR (system_type_id in (165, 167, 231) AND max_length = -1)))
	THEN ''LOB_DATA''
	ELSE Alloc_unit_type_desc END
	FROM ' 
	+ QUOTENAME(@databasename) + '.sys.objects o INNER JOIN '
	+ QUOTENAME(@databasename) + '.sys.schemas s ON o.schema_id = s.schema_id 
	INNER JOIN #work_to_do w ON o.object_id = w.tableid INNER JOIN '
	+ QUOTENAME(@databasename) + '.sys.indexes i ON w.tableid = i.object_id and w.indexid = i.index_id';

	EXEC(@updatecommand)
--select * from #work_to_do
--return
--Declare the cursor for the list of tables, indexes 
--and partitions to be processed.
--Note: Reorganizing the clustered index will NOT require
--that the non-clustered indexes are reorganized.
DECLARE rebuildindex CURSOR FOR 
	SELECT	QUOTENAME(IndexName) AS IndexName
			, TableName
			, SchemaName
			, IndexType
			, Alloc_unit_type_desc
			, PartitionNumber
			, PartitionCount
			, CurrentDensity
			, CurrentFragmentation
	FROM	#work_to_do i 
	ORDER BY TableName, IndexID;

-- Open the cursor.
OPEN rebuildindex;

-- Loop through the tables, indexes and partitions.
FETCH NEXT
   FROM rebuildindex
   INTO @indexname, @objectname, @schemaname, @indextype, @Alloc_unit_type_desc, @partitionnum, @partitioncount, @currentdensity, @currentfrag;

WHILE @@FETCH_STATUS = 0
	BEGIN

--If the procedure was executed with ONLINE='ON', determine
--if there are any columns in the index with LOB data.  When 
--this criteria is met, the ONLINE status is set to OFF.
	SET @onlinestatus = 
		(SELECT CASE WHEN @Alloc_unit_type_desc = 'LOB_DATA' 
			THEN 'OFF'
			WHEN @indextype LIKE '%XML INDEX%'
			THEN 'OFF'
			ELSE @online
			END)

--Rebuild the index where ONLINE='ON' and the above rules are satisfied
--If the index does not satisfy the requirements for an ONLINE index
--defragmentation, the index will be defragmented with required locks
--if @fullprocess='ON'
	--Individual partitions on indexes with multiple partitions 
	--CAN NOT be REBUILT with the ONLINE feature.

	SELECT @command = 'ALTER INDEX ' + @indexname + ' ON ' + QUOTENAME(@databasename) +'.' + QUOTENAME(@schemaname) + '.' + QUOTENAME(@objectname);

	IF @onlinestatus = 'ON'
		BEGIN	
			IF @partitioncount = 1
				BEGIN
				SELECT @command = @command + ' REBUILD WITH (STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, ONLINE = ON, SORT_IN_TEMPDB = OFF, MAXDOP = 5)';
				END
			IF @partitioncount > 1
				BEGIN
				SELECT @command = @command + ' REORGANIZE PARTITION=' + @partitionnum;
				END
		PRINT 'Executed ' + @command;				
		EXEC (@command);
		END;
	ELSE
	IF @fullprocess = 'ON'
		BEGIN
	-- If the index is more heavily fragmented, issue a REBUILD.  Otherwise, REORGANIZE.
			IF @currentfrag < 30
				BEGIN;
				SELECT @command = @command + ' REORGANIZE';
				IF @partitioncount > 1
					SELECT @command = @command + ' PARTITION=' + @partitionnum;
				END;

			IF @currentfrag >= 30
				BEGIN;
				SELECT @command = @command + ' REBUILD';
				IF @partitioncount > 1
					SELECT @command = @command + ' PARTITION=' + @partitionnum;
				END;
		PRINT 'Executed ' + @command;				
		EXEC (@command);
		END;

		FETCH NEXT FROM rebuildindex INTO @indexname, @objectname, @schemaname, @indextype, @Alloc_unit_type_desc, @partitionnum, @partitioncount, @currentdensity, @currentfrag;
	END;
-- Close and deallocate the cursor.
CLOSE rebuildindex;
DEALLOCATE rebuildindex;
GO
EXEC master.sys.sp_MS_marksystemobject 'sp_RebuildIndexesOnline'
GO

USE DBA
GO


USE [DBA]
GO
IF (SELECT OBJECT_ID('usp_Maintenance_plan_indexes'))>0
	DROP PROC usp_Maintenance_plan_indexes
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Procedure para execução via Job
CREATE PROCEDURE [dbo].[usp_Maintenance_plan_indexes]
AS 
BEGIN
	--- REBUILD DE INDICES
	SET ARITHABORT ON

	DECLARE CR_DB CURSOR FOR 
	  SELECT NAME FROM master.dbo.sysdatabases WITH(NOLOCK)
	  WHERE NAME NOT IN ('TEMPDB')
		AND DATABASEPROPERTYEX(NAME, 'Updateability') = 'READ_WRITE' 
		AND DATABASEPROPERTYEX(NAME, 'status') = 'ONLINE' 
	  ORDER BY NAME

	DECLARE @NAME VARCHAR(256)	


	OPEN CR_DB

	FETCH NEXT FROM CR_DB
	INTO @NAME

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		
		EXEC master.dbo.sp_RebuildIndexesOnline 15, 75, @NAME, 'ON', 'ON'
		
		FETCH NEXT FROM CR_DB
		INTO @NAME	
	END

	CLOSE CR_DB
	DEALLOCATE CR_DB
END
