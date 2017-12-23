/*
TSMLDet_ar_201505 --ok
TSMLDet_br_201505 --ok
TSMLDet_cl_201505 --ok
TSMLDet_co_201505 --ok
TSMLDet_co_movistar_201505 --ok
TSMLDet_ec_201505 --ok
TSMLDet_ec_movistar_201505 --ok
TSMLDet_mx_201505 --ok
TSMLDet_mx_movistar_201505 --ok
TSMLDet_other_201505 --ok
TSMLDet_pe_201505 --ok
TSMLDet_pe_movistar_201505

*/

declare @db varchar(100) = 'TSDetail201510',
		@dest varchar(max) = 'W:\MSSQL10_50.SQL03\MSSQL\Data',
		@origin varchar(max) = 'Z:\MSSQL10_50.SQL03\MSSQL\Data',
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
	FILENAME = '''+@dest+RIGHT(physical_name,CHARINDEX('\',REVERSE(physical_name)))+''') 
GO 

EXEC xp_cmdshell ''robocopy '+@origin+' '+@dest+' '+RIGHT(physical_name,CHARINDEX('\',REVERSE(physical_name))-1)+'''
GO
EXEC xp_cmdshell ''rename '+physical_name+' OLD_'+RIGHT(physical_name,CHARINDEX('\',REVERSE(physical_name))-1)+' ''
GO

--- POS_MOVE
ALTER DATABASE ['+@db+'] SET ONLINE
GO
sp_helpdb ['+@db+']
GO
'
FROM sys.master_files 
WHERE database_id = DB_ID(@db) AND physical_name like @origin+'%' ; 


print(@sql)