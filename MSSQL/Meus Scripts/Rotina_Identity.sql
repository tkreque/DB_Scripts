USE DBA
GO

CREATE TABLE DBA.dbo.DBA_SNAP_IDENTITY (
	DATA DATE,
	DBNAME VARCHAR(max),
	OBJECT_ID INT,
	TBNAME VARCHAR(max),
	COLNAME VARCHAR(max),
	TYPENAME VARCHAR(50),
	LAST_VALUE BIGINT,
	MAX_VALUE BIGINT,
	REMAINING_VALUE BIGINT
	)
GO

CREATE PROCEDURE usp_track_identity
AS
DECLARE @sql VARCHAR(max)

SET @sql = '
USE [?]
INSERT INTO DBA.dbo.DBA_SNAP_IDENTITY (DATA,DBNAME,OBJECT_ID,TBNAME,COLNAME,TYPENAME,LAST_VALUE,MAX_VALUE)
SELECT 
	CONVERT(DATE,GETDATE()) AS data,
	DB_NAME() as dbname,
	obj.object_id, 
	obj.name AS tbname, 
	ident.name AS colname,
	types.name AS typename,
	CONVERT(BIGINT, ident.last_value) AS last_value,
	CONVERT(BIGINT, CASE types.name 
		WHEN ''int'' THEN 2147483647
		WHEN ''bigint'' THEN 9223372036854775807
		WHEN ''smallint'' THEN 32767
		WHEN ''tinyint'' THEN 255
	END ) AS max_value
FROM sys.identity_columns ident 
	INNER JOIN sys.all_objects obj 
		ON ident.object_id = obj.object_id
	INNER JOIN sys.systypes types
		ON types.xtype = ident.system_type_id
WHERE obj.type_desc = ''USER_TABLE'' AND ident.last_value IS NOT NULL AND db_name() NOT IN (''master'',''model'',''msdb'',''tempdb'')

UPDATE DBA.dbo.DBA_SNAP_IDENTITY SET REMAINING_VALUE = max_value-last_value
WHERE REMAINING_VALUE IS NULL AND DATA = CONVERT(DATE,getdate())'

EXEC sp_MSforeachdb @sql
GO

CREATE PROCEDURE usp_export_identity
AS
IF (
SELECT COUNT(1)
FROM DBA.dbo.DBA_SNAP_IDENTITY 
WHERE -- Threshold para Disaster --
	 remaining_value = 0
) > 0
	PRINT '3' -- Valor da coleta do iMon para Disaster
ELSE
IF (
SELECT COUNT(1)
FROM DBA.dbo.DBA_SNAP_IDENTITY 
WHERE -- Threshold para High --
	(typename = 'bigint' AND remaining_value < 2000000000) OR
	(typename = 'int' AND remaining_value < 50000000) OR 
	(typename = 'smallint' AND remaining_value < 5000 ) OR
	(typename = 'tinyint' AND remaining_value < 25 ) 
) > 0
	PRINT '2' -- Valor da coleta do iMon para High
ELSE
IF (
SELECT COUNT(1)
FROM DBA.dbo.DBA_SNAP_IDENTITY 
WHERE -- Threshold para Warning --
	(typename = 'bigint' AND remaining_value < 5000000000) OR
	(typename = 'int' AND remaining_value < 100000000) OR 
	(typename = 'smallint' AND remaining_value < 10000 ) OR
	(typename = 'tinyint' AND remaining_value < 50 ) 
) > 0
	PRINT '1' -- Valor da coleta do iMon para Warning
ELSE 
	PRINT '0' -- Valor da coleta do iMon para Normal

EXEC xp_cmdshell 'sqlcmd -h"-1" -Q "SET NOCOUNT ON EXEC DBA.dbo.usp_export_identity" -o "C:\SQL\MonitorIdentity.txt"'

GO
