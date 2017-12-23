DECLARE @SQL1 VARCHAR(MAX),
	@SQL2 VARCHAR(MAX),
	@DB VARCHAR(100)

DECLARE CUR CURSOR FOR
	SELECT name FROM sys.databases WHERE name NOT IN ('master','model','tempdb','msdb') AND state = 0 AND is_read_only = 0
OPEN CUR ----- OPEN CURSOR
FETCH NEXT FROM CUR INTO @DB  

WHILE (@@FETCH_STATUS = 0)  
BEGIN  
SELECT @SQL1 = '
-- ****** Begin: Script to be run at Primary: [mssql-dbsql-poa] ******
DECLARE @LS_BackupJobId	AS uniqueidentifier 
DECLARE @LS_PrimaryId	AS uniqueidentifier 
DECLARE @SP_Add_RetCode	As int 


EXEC @SP_Add_RetCode = master.dbo.sp_add_log_shipping_primary_database 
		@database = N'''+@DB+''' 
		,@backup_directory = N''\\MSSQL-DBSQL-MIA\log'' 
		,@backup_share = N''\\MSSQL-DBSQL-MIA\log'' 
		,@backup_job_name = N''LSBackup_'+@DB+''' 
		,@backup_retention_period = 1440
		,@backup_compression = 2
		,@monitor_server = N''mssql-dbsql-mia'' 
		,@monitor_server_security_mode = 1 
		,@backup_threshold = 60 
		,@threshold_alert_enabled = 1
		,@history_retention_period = 2880 
		,@backup_job_id = @LS_BackupJobId OUTPUT 
		,@primary_id = @LS_PrimaryId OUTPUT 
		,@overwrite = 1 


IF (@@ERROR = 0 AND @SP_Add_RetCode = 0) 
BEGIN 

DECLARE @LS_BackUpScheduleUID	As uniqueidentifier 
DECLARE @LS_BackUpScheduleID	AS int 


EXEC msdb.dbo.sp_add_schedule 
		@schedule_name =N''LSBackupSchedule_mssql-dbsql-mia1'' 
		,@enabled = 1 
		,@freq_type = 4 
		,@freq_interval = 1 
		,@freq_subday_type = 4 
		,@freq_subday_interval = 10 
		,@freq_recurrence_factor = 0 
		,@active_start_date = 20130523 
		,@active_end_date = 99991231 
		,@active_start_time = 0 
		,@active_end_time = 235900 
		,@schedule_uid = @LS_BackUpScheduleUID OUTPUT 
		,@schedule_id = @LS_BackUpScheduleID OUTPUT 

EXEC msdb.dbo.sp_attach_schedule 
		@job_id = @LS_BackupJobId 
		,@schedule_id = @LS_BackUpScheduleID  

EXEC msdb.dbo.sp_update_job 
		@job_id = @LS_BackupJobId 
		,@enabled = 1 


END 


EXEC master.dbo.sp_add_log_shipping_primary_secondary 
		@primary_database = N'''+@DB+''' 
		,@secondary_server = N''mssql-dbsql-mia'' 
		,@secondary_database = N'''+@DB+'''
		,@overwrite = 1 

-- ****** End: Script to be run at Primary: [mssql-dbsql-mia]  ******
'
EXECUTE(@SQL1)
--PRINT(@SQL1)



SELECT @SQL2 = '
-- ****** Begin: Script to be run at Secondary: [mssql-dbsql-mia] ******
DECLARE @LS_Secondary__CopyJobId	AS uniqueidentifier 
DECLARE @LS_Secondary__RestoreJobId	AS uniqueidentifier 
DECLARE @LS_Secondary__SecondaryId	AS uniqueidentifier 
DECLARE @LS_Add_RetCode	As int 


EXEC @LS_Add_RetCode = master.dbo.sp_add_log_shipping_secondary_primary 
		@primary_server = N''mssql-dbsql-poa'' 
		,@primary_database = N'''+@DB+'''
		,@backup_source_directory = N''\\MSSQL-DBSQL-MIA\log'' 
		,@backup_destination_directory = N''\\MSSQL-DBSQL-MIA\log'' 
		,@copy_job_name = N''LSCopy_mssql-dbsql-mia_'+@DB+'''
		,@restore_job_name = N''LSRestore_mssql-dbsql-mia_'+@DB+'''
		,@file_retention_period = 4320 
		,@monitor_server = N''mssql-dbsql-mia'' 
		,@monitor_server_security_mode = 1 
		,@overwrite = 1 
		,@copy_job_id = @LS_Secondary__CopyJobId OUTPUT 
		,@restore_job_id = @LS_Secondary__RestoreJobId OUTPUT 
		,@secondary_id = @LS_Secondary__SecondaryId OUTPUT 

IF (@@ERROR = 0 AND @LS_Add_RetCode = 0) 
BEGIN 

DECLARE @LS_SecondaryCopyJobScheduleUID	As uniqueidentifier 
DECLARE @LS_SecondaryCopyJobScheduleID	AS int 


EXEC msdb.dbo.sp_add_schedule 
		@schedule_name =N''DefaultCopyJobSchedule'' 
		,@enabled = 1 
		,@freq_type = 4 
		,@freq_interval = 1 
		,@freq_subday_type = 4 
		,@freq_subday_interval = 15 
		,@freq_recurrence_factor = 0 
		,@active_start_date = 20130523 
		,@active_end_date = 99991231 
		,@active_start_time = 0 
		,@active_end_time = 235900 
		,@schedule_uid = @LS_SecondaryCopyJobScheduleUID OUTPUT 
		,@schedule_id = @LS_SecondaryCopyJobScheduleID OUTPUT 

EXEC msdb.dbo.sp_attach_schedule 
		@job_id = @LS_Secondary__CopyJobId 
		,@schedule_id = @LS_SecondaryCopyJobScheduleID  

DECLARE @LS_SecondaryRestoreJobScheduleUID	As uniqueidentifier 
DECLARE @LS_SecondaryRestoreJobScheduleID	AS int 


EXEC msdb.dbo.sp_add_schedule 
		@schedule_name =N''DefaultRestoreJobSchedule'' 
		,@enabled = 1 
		,@freq_type = 4 
		,@freq_interval = 1 
		,@freq_subday_type = 4 
		,@freq_subday_interval = 10 
		,@freq_recurrence_factor = 0 
		,@active_start_date = 20130523 
		,@active_end_date = 99991231 
		,@active_start_time = 0 
		,@active_end_time = 235900 
		,@schedule_uid = @LS_SecondaryRestoreJobScheduleUID OUTPUT 
		,@schedule_id = @LS_SecondaryRestoreJobScheduleID OUTPUT 

EXEC msdb.dbo.sp_attach_schedule 
		@job_id = @LS_Secondary__RestoreJobId 
		,@schedule_id = @LS_SecondaryRestoreJobScheduleID  


END 


DECLARE @LS_Add_RetCode2	As int 


IF (@@ERROR = 0 AND @LS_Add_RetCode = 0) 
BEGIN 

EXEC @LS_Add_RetCode2 = master.dbo.sp_add_log_shipping_secondary_database 
		@secondary_database = N'''+@DB+'''
		,@primary_server = N''mssql-dbsql-poa'' 
		,@primary_database = N'''+@DB+'''
		,@restore_delay = 0 
		,@restore_mode = 1 
		,@disconnect_users	= 1 
		,@restore_threshold = 45   
		,@threshold_alert_enabled = 1 
		,@history_retention_period	= 2880 
		,@overwrite = 1 

END 


IF (@@error = 0 AND @LS_Add_RetCode = 0) 
BEGIN 

EXEC msdb.dbo.sp_update_job 
		@job_id = @LS_Secondary__CopyJobId 
		,@enabled = 0 

EXEC msdb.dbo.sp_update_job 
		@job_id = @LS_Secondary__RestoreJobId 
		,@enabled = 1 

END 


-- ****** End: Script to be run at Secondary: [mssql-dbsql-mia] ******
'
EXECUTE(@SQL2) --AT [MSSQL-DBSQL-MIA]
--PRINT(@SQL2)

    FETCH NEXT FROM CUR INTO @DB
END
CLOSE CUR
DEALLOCATE CUR


