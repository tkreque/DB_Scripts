exec master.dbo.sp_MSforeachdb '
USE [?]
IF (databasepropertyex(''?'', ''Updateability'') = ''READ_WRITE'') AND
	   (db_name() <> ''TEMPDB'') AND 
	   (databasepropertyex(''?'', ''status'') = ''ONLINE'')  
	BEGIN
	DECLARE @DATA VARCHAR(50),
		@NAME VARCHAR(MAX)
	SET @DATA = CONVERT(VARCHAR(15), GETDATE(), 112)
	
	
	SET @NAME = ''D:\Backup_SQL\''+@DATA+db_name()+''.bak''
	 
	BACKUP DATABASE [?] TO DISK=@NAME 
	END
	'