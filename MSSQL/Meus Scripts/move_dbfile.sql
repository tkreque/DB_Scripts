/*

*/

declare @db varchar(100) = 'TSMLDet_pe_movistar_201411',
		@sql varchar(max)
		
SELECT @sql =
'
--- PRE_MOVE
sp_helpdb ['+@db+']
GO
ALTER DATABASE ['+@db+'] SET OFFLINE
GO
ALTER DATABASE ['+@db+'] MODIFY FILE ( 
	NAME = '''+name+''', 
	FILENAME = ''K:\SQL04_TSML2_0_9_History\MSSQL10_50.SQL04\MSSQL\DATA'+RIGHT(physical_name,CHARINDEX('\',REVERSE(physical_name)))+''') 
GO 

--- POS_MOVE
ALTER DATABASE ['+@db+'] SET ONLINE
GO
sp_helpdb ['+@db+']
GO
'
FROM sys.master_files 
WHERE database_id = DB_ID(@db) AND physical_name like 'Y:\MSSQL10_50.SQL04\MSSQL\DATA\%' ; 


print(@sql)