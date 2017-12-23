CREATE TABLE #Ttemp (
	Data DATETIME NULL,
	Nome VARCHAR(MAX) NULL
	)
	
INSERT INTO #Ttemp (Nome)
	EXEC XP_CMDSHELL 'dir D:\Backup_SQL\ /b'

	
UPDATE #Ttemp 
	SET Data = CONVERT(DATETIME, LEFT(Nome,8)) 
WHERE 
	Data IS NULL AND 
	Nome IS NOT NULL

DECLARE @texto VARCHAR(MAX) = ''

SELECT @texto = @texto + 'exec xp_cmdshell ''del D:\Backup_SQL\' + Nome + '''
'
FROM #Ttemp 
WHERE Data < GETDATE()-15

EXEC(@texto)

DROP TABLE #Ttemp