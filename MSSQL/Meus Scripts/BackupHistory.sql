USE msdb
GO

/*
Definir o @threshold para o número de dias a avaliar.
*/
DECLARE @threshold INT = 30

SELECT 
	CONVERT(DATETIME,backup_start_date) AS Start_date,
	CONVERT(DATETIME,backup_finish_date) AS Finish_date,
	Database_name,
	Name,
	BackupType = CASE type WHEN 'D' THEN 'FULL'
		WHEN 'L' THEN 'LOG'
		WHEN 'I' THEN 'DIFERENTIAL'
		END
FROM msdb.dbo.backupset
WHERE CONVERT(DATE,backup_start_date) BETWEEN CONVERT(DATE,GETDATE()-@threshold) AND CONVERT(DATE,GETDATE())
ORDER BY backup_start_date DESC
