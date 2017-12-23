/*
					Script que gera o alerta
	Ajustar os filtros conforme a necessidade e criar o script/procedure
*/

set nocount on

select top 1
	ltrim(((rq.total_elapsed_time/1000)/60)) as TotalTimeMin
from sys.dm_exec_requests rq
	inner join sys.dm_exec_sessions ss 
		on rq.session_id = ss.session_id
where 
	db_name(rq.database_id) not in ('tempdb')
	and ((rq.total_elapsed_time/1000)/60) > 0
	and rq.blocking_session_id <> 0
order by ((rq.total_elapsed_time/1000)/60) desc


/* 
					Script para a criação do JOB 
Se o comando acima foi criado o Script no caminho indicado manter o job desta forma, caso contrário ajustar.

*/

USE [msdb]
GO

/****** Object:  Job [DBA Monitor Locks]    Script Date: 08/29/2013 07:56:06 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/29/2013 07:56:06 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA Monitor Locks', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Job que executa todo o minuto e pega o maior tempo de locks que estão ocorrendo no banco.
No arquivo "C:\SQL\database_locks.txt" é gerado apenas 1 valor tipo int, no qual equivale ao top 1 de minutos em lock da transação.

NULL = Sem locks no banco.
< 10 minutos = Sem alerta.
>= 10 minutos = Gera alerta.

Ticket da requisição : 
', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [SQLCMD]    Script Date: 08/29/2013 07:56:07 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'SQLCMD', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'SQLCMD -h "-1" -S "" -i "C:\SQL\MonitorLock.sql" -o "C:\SQL\database_locks.txt"', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every_Minute', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20120704, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


