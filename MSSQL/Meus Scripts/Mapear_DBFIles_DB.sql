SET NOCOUNT ON
DECLARE @DBNAME varchar(100) = 'DBA'

SELECT
	DB_NAME(dbid) AS DatabaseName,
	name AS DatafileName,
	LEFT(filename,LEN(filename)-CHARINDEX('\',REVERSE(filename))+1) AS DatafilePath,
	LEFT(filename,1) AS DiskVolume,
	RIGHT(filename,CHARINDEX('\',REVERSE(filename))-1) AS OSFilename,
	RIGHT(filename,3) AS OSFileType	
FROM sys.sysaltfiles
WHERE dbid = DB_ID(@DBNAME)
--FOR XML PATH --- Gerar em XML


--- Gerar código de Restore
/*

SELECT
	'RESTORE DATABASE ['+@DBNAME+'] FROM DISK = ''PATH'' WITH'
UNION ALL
SELECT
	'	MOVE '''+name+''' TO '''+RIGHT(filename,CHARINDEX('\',REVERSE(filename)))+''','
FROM sys.sysaltfiles
WHERE dbid = DB_ID(@DBNAME)
UNION ALL
SELECT
	'STATS = 10, RECOVERY, REPLACE'
UNION ALL
SELECT
	'GO'

*/