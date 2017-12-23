declare 
	@sql varchar(max),
	@db varchar(100) = 'dsadsdsa' --- DB NAME
	

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
	BACKUP LOG ['+name+'] TO DISK = ''\\MSSQL-DBSQL-MIA\BKP\LS\LASTLOG_'+name+'.trn'' WITH FORMAT, INIT 
	GO	
	
	---- EXECUTE ON PRIMARY SERVER	::5
	ALTER DATABASE ['+name+'] SET OFFLINE WITH ROLLBACK IMMEDIATE
	GO
	--ALTER DATABASE ['+name+'] SET ONLINE
	--GO
	--ALTER DATABASE ['+name+'] SET READ_ONLY
	--GO
		
	---- EXECUTE ON SECONDARY SERVER ::6	
	EXEC (''USE [master]; RESTORE LOG ['+name+'] FROM DISK = ''''O:\BKP\LS\LASTLOG_'+name+'.trn'''' WITH RECOVERY'') AT [MSSQL-DBSQL-MIA]
	GO
	
	---- EXECUTE ON SECONDARY SERVER ::7
    EXEC (''
        USE ['+name+'];

        DECLARE @DBUserName varchar(50)
        DECLARE @SysLoginName varchar(50)
        DECLARE SyncDBLogins CURSOR FOR 
          SELECT A.name DBUserName,        
                 B.loginname SysLoginName 
          FROM sysusers A      
               JOIN master.dbo.syslogins B      
                 ON A.name collate Latin1_General_CI_AS = B.Name  collate Latin1_General_CI_AS      
               JOIN master.dbo.sysdatabases C      
                 ON C.Name collate Latin1_General_CI_AS = '''''+name+''''' collate Latin1_General_CI_AS
          WHERE issqluser = 1       
           AND (A.sid IS NOT NULL       
            AND A.sid <> 0x0)       
            
            AND suser_sname(A.sid) IS NULL       
            AND (C.status & 32) =0 --Loading       
            AND (C.status & 64) =0 --pre recovery       
            AND (C.status & 128) =0 --recovering       
            AND (C.status & 256) =0 --not recovered       
            AND (C.status & 512) =0 --offline       
            AND (C.status & 1024) =0 --read only 
        ORDER BY A.name
        
        OPEN SyncDBLogins
        FETCH NEXT FROM SyncDBLogins 
        INTO @DBUserName, @SysLoginName QW
        
        WHILE @@FETCH_STATUS = 0 
        BEGIN    
            EXEC sp_change_users_login ''''update_one'''', @DBUserName, @SysLoginName    
            
            FETCH NEXT FROM SyncDBLogins    
            INTO @DBUserName, 
                 @SysLoginName 
        END
        
        CLOSE SyncDBLogins
        DEALLOCATE SyncDBLogins
'') AT [MSSQL-DBSQL-MIA]
	
        /* End of Script */
'
from sys.databases
where name = @db

print (@sql)