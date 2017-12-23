USE [master]
GO

SELECT 
	database_name AS [Database Name], 
	name AS [Program Name], 
	CASE type 
		WHEN 'D' THEN 'Backup Full' 
		ELSE 'Backup Log' 
	END AS [Backup Type],
	recovery_model AS [Database Recovery Model],
	backup_finish_date AS [Last Backup Date]
FROM msdb..backupset
WHERE backup_set_id IN (
	SELECT MAX(tbs.backup_set_id)
	FROM sys.databases tdb
		INNER JOIN msdb..backupset tbs ON tdb.name = tbs.database_name	
	WHERE tbs.type='D'
	GROUP BY tdb.name
) OR backup_set_id IN (
	SELECT MAX(tbs.backup_set_id)
	FROM sys.databases tdb
		INNER JOIN msdb..backupset tbs ON tdb.name = tbs.database_name	
	WHERE tbs.type='L'
	GROUP BY tdb.name
)
ORDER BY database_name, type

