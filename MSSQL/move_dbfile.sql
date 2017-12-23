/*
R:\MSSQL10_50.SQL01\MSSQL\DATA - G:\MSSQL10_50.SQL01\MSSQL\DATA
S:\MSSQL10_50.SQL01\MSSQL\DATA - F:\MSSQL10_50.SQL01\MSSQL\DATA
T:\MSSQL10_50.SQL01\MSSQL\LOG - H:\MSSQL10_50.SQL01\MSSQL\LOG
*/
SET NOCOUNT ON
DECLARE @db VARCHAR(100) = 'WidgetsTerra'

SELECT '
ALTER DATABASE ['+@db+'] SET OFFLINE
GO
'		
SELECT
'
--'+physical_name+'
ALTER DATABASE ['+@db+'] MODIFY FILE ( 
	NAME = '''+name+''', 
	FILENAME = '''+RIGHT(physical_name,CHARINDEX('\',REVERSE(physical_name)))+''') 
GO 

EXEC xp_cmdshell ''robocopy '+REVERSE(RIGHT(REVERSE(physical_name),(LEN(physical_name)-CHARINDEX('\', REVERSE(physical_name),1))))+'  '+RIGHT(physical_name,CHARINDEX('\',REVERSE(physical_name))-1)+'''
GO
'
FROM sys.master_files 
WHERE database_id = DB_ID(@db); 
SELECT '
ALTER DATABASE ['+@db+'] SET ONLINE
GO
EXEC sp_helpdb '+@db+'
GO
'		


