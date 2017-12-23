declare @db varchar(50) = 'crm', --- DB NAME
	@job_str varchar(150),
	@job_end varchar(150)
	
select 
	@job_str = 'LSBackup_'+@db,
	@job_end = 'LSRestore_mssql-dbsql02-p\sql02_'+@db --- AJUSTAR O INICIO PARA O SERVIDOR CORRESPONDENTE
	
	
exec msdb..sp_start_job @job_name = @job_str
begin
	waitfor delay '00:01'; --- 1 MIN DE DELAY
	exec [MSSQLSE-SQL-POA\SQL02].msdb..sp_start_job @job_name = @job_end;
end

