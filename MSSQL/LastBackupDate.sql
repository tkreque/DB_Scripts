/* 

Check when the last backup occurred

------------------------ CHANGE LOG ------------------------
2017-12-23 - Thiago Reque
  - Adjustments for add in Github
*/

SELECT '--- LAST FULL/DIFF BACKUP ---'
SELECT 
	T1.Name as DatabaseName, 
	COALESCE(Convert(varchar(12), MAX(T2.backup_finish_date), 101),'None') as LastBackupDate
FROM sys.databases T1 
	LEFT OUTER JOIN msdb.dbo.backupset T2
		ON T2.database_name = T1.name
WHERE T2.type = 'L' AND T1.recovery_model_desc = 'FULL'
GROUP BY T1.Name
ORDER BY T1.Name



----

SELECT '--- LAST LOG BACKUP ---' 
SELECT 
	db.name,
	db.recovery_model_desc,
	(SELECT MAX(backup_finish_date) FROM msdb..backupset WHERE database_name = db.name AND type = 'L')
FROM 
	sys.databases db
WHERE db.recovery_model_desc = 'FULL' AND db.database_id NOT IN (1,2,3,4)
GROUP BY db.name, db.recovery_model_desc
ORDER BY db.name