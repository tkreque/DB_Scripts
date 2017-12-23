/* 

Uninstall the DBA Database from the instance and all related objects
Created by Alexandre Muhlen () at ilegra
Adjusments made by Thiago Leite () and Thiago Reque ()

------------------------ CHANGE LOG ------------------------
26/08/2010 Alexandre Von Mühlen
	- Criação script "Uninstall.SQL"
05/07/2011 Alexandre Von Mühlen
	- Inclusão da exclusão de Jobs da rotina de monitoramento pelo iMon/Zabbix
27/03/2012 Thiago Reque
	- Inclusão da exclusão de Jobs antigos
06/07/2012 Alexandre Muhlen
	- Inclusão de job do Critical Jobs
03/01/2013 Thiago Reque
	- Inclusão do rollback antes de Dropar a database DBA
11/02/2014 Thiago Reque
	- Inclusão dos novos Jobs


--------------- NEW Changelog

2017-12-23 - Thiago Reque
  - Adjustments for add in Github


**** NOT SUPORTED ON LINUX INSTANCES (yet)!!!!
*/

USE [msdb]
GO

-------------------------------- JOBS ------------------------------------------
IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA maintenance_plan_indexes')
	EXEC dbo.sp_delete_job @job_name = 'DBA maintenance_plan_indexes'
GO

IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA maintenance_plan_statistics')
	EXEC dbo.sp_delete_job @job_name = 'DBA maintenance_plan_statistics'
GO

IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA maintenance_plan_checkintegrity')
	EXEC dbo.sp_delete_job @job_name = 'DBA maintenance_plan_checkintegrity'
GO

IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA backup_alert')
	EXEC dbo.sp_delete_job @job_name = 'DBA backup_alert'
GO

IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA track_data_growth_stats')
	EXEC dbo.sp_delete_job @job_name = 'DBA track_data_growth_stats'
GO

IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA purge_data_growth_stats')
	EXEC dbo.sp_delete_job @job_name = 'DBA purge_data_growth_stats'
GO

IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA login_failed_alert')
	EXEC dbo.sp_delete_job @job_name = 'DBA login_failed_alert'
GO

IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA track_snapshot')
	EXEC dbo.sp_delete_job @job_name = 'DBA track_snapshot'
GO

IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA purge_snapshot')
	EXEC dbo.sp_delete_job @job_name = 'DBA purge_snapshot'
GO

IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA space_allocation_for_files')
	EXEC dbo.sp_delete_job @job_name = 'DBA space_allocation_for_files'
GO

IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA disk_space_alert')
	EXEC dbo.sp_delete_job @job_name = 'DBA disk_space_alert'
GO

IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA send_server_report')
	EXEC dbo.sp_delete_job @job_name = 'DBA send_server_report'
GO

IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA purge_monitor_log')
	EXEC dbo.sp_delete_job @job_name = 'DBA purge_monitor_log'
GO

-------------------------------- New JOBs ------------------------------
IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA monitor_every_5_minutes')
	EXEC dbo.sp_delete_job @job_name = 'DBA monitor_every_5_minutes'
GO

IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA monitor_every_day')
	EXEC dbo.sp_delete_job @job_name = 'DBA monitor_every_day'
GO
---------------------------------------------------------------------------------

IF EXISTS (SELECT * FROM dbo.syscategories WHERE name = N'DBA Generic' AND category_class=1)
	EXEC dbo.sp_delete_category @class=N'JOB', @name=N'DBA Generic'

----------------------------------- DBA operator ---------------------------------
IF EXISTS (SELECT 1 FROM dbo.sysoperators WHERE name = 'DBA')
	EXEC dbo.sp_delete_operator 'DBA'
GO

-------------------- RESTART ALERT -------------------------
use master
go

EXECUTE AS LOGIN = 'sa'
GO
IF (SELECT OBJECT_ID('usp_DBA_restart_alert')) IS NOT NULL
	DROP PROC usp_DBA_restart_alert
GO

----------------- TRACK LOGIN/USER CHANGES -----------------
IF EXISTS (SELECT 1 FROM sys.server_triggers WHERE name = 'TRG_LOGINCHANGELOG')
	DROP TRIGGER TRG_LOGINCHANGELOG ON ALL SERVER

----------------- TRACK DDL COMMANDS -----------------------
EXEC sp_MSForEachDB 'USE [?]
	IF EXISTS (SELECT * FROM sys.triggers where name = ''TRG_ALL_DDL_EVENTS'')
		DROP TRIGGER TRG_ALL_DDL_EVENTS ON DATABASE'
GO

------------------- DEADLOCK MONITOR -------------------
IF EXISTS (SELECT 1 FROM sys.server_event_notifications WHERE name = 'DeadLockNotificationEvent')
	DROP EVENT NOTIFICATION DeadLockNotificationEvent ON SERVER
GO

--------------- LOGIN FAILED ALERT --------------------
IF EXISTS (SELECT 1 FROM master.sys.server_event_notifications WHERE name = 'LoginFailNotification')
	DROP EVENT NOTIFICATION LoginFailNotification ON SERVER

-------------- REBUILD AND REORGANIZE INDEXES --------------
IF OBJECT_ID('dbo.sp_DBA_Maintenance_plan_indexes') IS NOT NULL
	DROP PROCEDURE sp_DBA_Maintenance_plan_indexes
GO

---------------- DATABASE DBA -----------------------------
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DBA')
BEGIN
	ALTER DATABASE DBA SET OFFLINE WITH ROLLBACK IMMEDIATE;
	ALTER DATABASE DBA SET ONLINE;
	DROP DATABASE DBA;
END
GO
