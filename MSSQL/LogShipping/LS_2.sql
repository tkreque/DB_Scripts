declare 
	@sql varchar(max),
	@db varchar(100) = 'PPI_teste'
	

select @sql = '
	/* Execute the script on this order */
	---- EXECUTE ON PRIMARY SERVER ::1
	USE [master]
	GO
	
	EXEC sp_delete_log_shipping_primary_secondary '''+name+''',''MSSQL-DBSQL-MIA'','''+name+'''
	GO
	
	---- EXECUTE ON SECONDAREY SERVER ::2
	EXEC (''use [master]; exec sp_delete_log_shipping_secondary_database '''''+name+''''' '') AT [MSSQL-DBSQL-MIA]
	GO
	
	---- EXECUTE ON PRIMARY SERVER ::3
	EXEC sp_delete_log_shipping_primary_database '''+name+'''
	GO
	
	USE [msdb]
	GO
	
	DELETE FROM log_shipping_monitor_secondary WHERE primary_database = '''+name+'''
	GO
	
	USE [master]
	GO
	
	EXEC sp_delete_log_shipping_alert_job
	GO

	---- EXECUTE ON PRIMARY SERVER	::4
	BACKUP LOG ['+name+'] TO DISK = ''\\MSSQL-DBSQL-MIA\log\LASTLOG_'+name+'.trn'' WITH FORMAT, INIT 
	GO	
	
	---- EXECUTE ON SECONDARY SERVER ::5	
	EXEC (''USE [master]; RESTORE LOG ['+name+'] FROM DISK = ''''H:\bkp\log\LASTLOG_'+name+'.trn'''' WITH RECOVERY'') AT [MSSQL-DBSQL-MIA]
	GO
	
	---- EXECUTE ON PRIMARY SERVER	::6
        ALTER DATABASE ['+name+'] SET OFFLINE WITH ROLLBACK IMMEDIATE
        GO
        ALTER DATABASE ['+name+'] SET ONLINE
        GO
	ALTER DATABASE ['+name+'] SET READ_ONLY
	GO
	
	/* End of Script */
'
from sys.databases
where name = @db

print @sql


/*
--- ACTIVATE JOBS
SELECT '
USE msdb
GO
EXEC sp_update_job @job_name = '''+name+''', @enabled = 1
GO'
FROM msdb.dbo.sysjobs
WHERE enabled = 0
*/
