USE [DBA]
GO

---- QUERY FOR BACKUP ALERT----
SELECT db.name AS [DATABASE]
		,'BACKUP LOG' AS [TYPE]
		,COALESCE(CONVERT(VARCHAR(12), DATEDIFF(HOUR,MAX(bs.backup_finish_date),GETDATE()), 101),'NONE') AS [LASTBACKUPHOURS]
	FROM sys.databases db 
		LEFT OUTER JOIN msdb.dbo.backupset bs
			ON bs.database_name = db.name
			AND bs.type = 'L'
	WHERE DATABASEPROPERTYEX(db.name, 'Status') = 'ONLINE'
		AND db.database_id > 4
		AND db.name <> 'DBA'
		AND db.recovery_model_desc in ('BULK LOGGED', 'FULL')
	GROUP BY db.name
		UNION ALL
		SELECT  db.name
		,'BACKUP FULL E DIFF'
		,COALESCE(CONVERT(VARCHAR(12), DATEDIFF(HOUR,MAX(bs.backup_finish_date),GETDATE()), 101),'NONE')
		FROM sys.databases db 
			LEFT OUTER JOIN msdb.dbo.backupset bs
				ON bs.database_name = db.name
				AND bs.type IN ('I', 'D')
		WHERE DATABASEPROPERTYEX(db.name, 'Status') = 'ONLINE'
			AND db.database_id > 4
			AND db.name <> 'DBA'
		GROUP BY db.name
GO