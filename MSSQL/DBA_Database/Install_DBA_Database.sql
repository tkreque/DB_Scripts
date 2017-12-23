/* 

A database to Collect informations, perform maintenance tasks and health check of the MSSQL instance.
Created by Thiago leite () at ilegra
Adjusments made by Alexandre Muhlen () and Thiago Reque ()

------------------------ CHANGE LOG (PT-BR) ------------------------
12/04/2010	Thiago Leite
	- Criação do SETUP.SQL
24/05/2010	Alexandre Muhlen
	- Verificação se Broker está ativo na database DBA
	- Definição rotina de auditoria sobre login/user changes
26/05/2010 Thiago Leite
	- Alterado agenda job "DBA_track_snapshot"
	- Alterado tamanho do [command] na tabela DBA_SNAP_REQUESTS
	- Alterado tamanho do [program_name] de nvarchar(128) para nvarchar(256)
	- alterado procedure "usp_DBA_restart_alert", pois o acesso a tabela DBA_PARAMS não estava totalmente qualificado e retornava erros
08/06/2010  Alexandre Muhlen
	- Alteração procedure "usp_send_server_report", correção da informação sobre logins falhos
26/07/2010 Thiago Leite	
	- Alterado contexto do usuário que executa a trigger TRG_LOGINCHANGELOG, pois nem todo usuário tem permissão de VIEW SERVER STATE
04/08/2010 Thiago Leite
	- Configurar parametro "scan for startup procs" para executar procedure usp_DBA_restart_alert quando ambiente for reinicializado
09/08/2010 Thiago Reque
	- Alterado a procedure "usp_track_data_growth_stats" pois ela estava gerando uma divisão por zero na parte de inserir dados na tabela DBA_INFO_BACKUP_GROWTH.
08/09/2010 Thiago Leite
	- Alterado as procedures "usp_backup_alert" e "usp_send_server_report" para ignorarem database snapshot
09/09/2010 Thiago Reque
	- Alterado a procedure "usp_space_allocation_for_files" para ignorar databases em modo "READ-ONLY" e "OFFLINE"
13/09/2010 Thiago Reque
	- Alterado a procedure "usp_Maintenance_plan_checkintegrity" colocando o parametro [?] na linha do DBCC CHECKDB para não ignorar as databases com espaço no nome
04/10/2010 Alexandre Muhlen
	- Correção número de falhas de login na proc "usp_send_server_report"
	- Inclusão do parâmetro opcional "@vRecipients" na proc "usp_send_server_report"
19/11/2010 Alexandre Muhlen
	- Correção de todo Setup permitindo compatibilidade com collations case sensitive ou binarios
07/12/2010 Thiago Reque	
	- Alterado na procedure "usp_track_data_growth_stats" para adicionar os dados quando um servidor trabalha com schemas.
21/12/2010 Daniel Ortiz
	- Correção da criação da procedure "usp_track_data_growth_stats" e "usp_purge_data_growth_stats"
28/12/2010 Alexandre Muhlen
	- Correção procedure usp_Maintenance_plan_statistics, alterando verificação do nome da database corrente
07/01/2011 Thiago Reque
	- Alterado a procedure "usp_send_server_report" para executar o .vbs do caminho correto.
10/01/2011 Alexandre Muhlen
	- Alterado agendamento default do job "DBA maintenance_plan_statistics"
02/05/2011 Thiago Leite
	- Correção na procedure "sp_DBA_Maintenance_plan_indexes" para considerar nomes de indices com mais de 1 palavra
05/07/2011 Alexandre Muhlen
	- Correção da rotina "TRACK DDL COMMANDS" para considerar databases com " " (espaço) no nome
	- Criação de rotina de monitoramento, para coleta de indicadores pelo iMon/Zabbix
25/07/2011 Alexandre Muhlen
	- Adicionado WITH RECOMPILE na procedure usp_track_snapshot
29/12/2011 Thiago Reque
	- Adicionado o GROW MONITOR para o monitoramento do Zabbix/iMon e alterado o job "DBA disk_space_alert".
Versão: 1.0 - 05/03/2012 Alexandre Muhlen
	- Adição da opção ENCRYPTION em todos objetos (Procedures e Views)
	- Criação de FAQ #100010123 - Descrição de procedimento de alteração do Setup.SQL
	- Criação da tabela DBA_VERSION_CONTROLL
Versão: 1.1 - 30/03/2012 Thiago Leite
	- Removido o job purge monitor log, pois a procedure já havia sido excluida
Versão: 1.2 - 20/04/2012 Alexandre Muhlen
	- Adição coluna QUERY_PLAN na tabela DBA_SNAP_REQUESTS
	- Alterada procedure usp_track_snapshot para capturar QUERY_PLAN
	- Adicionado parâmetro "SNAPSHOT_QUERY_PLAN_RETENTION" na DBA_PARAMS com valor default = 7
	- Alterada procedure usp_purge_snapshot para limpar coluna QUERY_PLAN da DBA_SNAP_REQUESTS conforme parâmetro SNAPSHOT_QUERY_PLAN_RETENTION
Versão: 1.3 - 31/05/2012 Alexandre Muhlen
	- Adição coluna RUNNING_MIN_TOLERANCE tabela DBA_MONITOR_CRITICAL_JOBS
Versão: 1.4 - 02/07/2012 Thiago Reque
	- Ajustado a rotina da procedure "usp_space_allocation_for_files", adicionado filtros de Espaço na unidade e Alocação maior que o MaxSize definido.
Versão: 1.5 - 06/07/2012 Alexandre Muhlen
	- Criação da rotina de monitoramento de Critical Jobs
Versão: 1.6 - 23/07/2012 Thiago Reque
	- Ajustado a procedure "usp_track_data_growth_stats" para adicionar os schemas junto ao Tablename na tabela DBA_INFO_TABLE
Versão: 1.7 - 24/09/2012 Alexandre Mühlen
	- Ajustada a procedure "usp_Monitor_Critical_Jobs" para correção de bug no monitoramento
Versão: 1.8 - 20/11/2012 Alexandre Mühlen
	- Ajustada a procedure "usp_space_allocation_for_files" para correção de bug no controle de alocação
Versão: 1.9 - 22/11/2012 Alexandre Mühlen
	- Ajustada a procedure "usp_disk_space_alert" para correção de bug no alerta de disk space
Versão: SP1 - 03/01/2013 Thiago Reque
	- Ajustado o Report diário para enviar o número atual do setup
	- Criado a rotina de monitoração do max size para o Identity
	-	Monitoração da VersionStore da TempDB
Versão: 2.1 - 14/05/2013 Thiago Leite
	- Ajustada a procedure "usp_disk_space_alert" incluída uma nova funcionalidade que permite desconsiderar drives no monitoramento
	- Para usar inserir registro na DBA_PARAMS
		exemplo, para ignorar o drive Y na checagens:
		INSERT INTO [DBA].[dbo].[DBA_PARAMS]([PARAM_VALUE], [PARAM_NAME]) VALUES('Y', 'DISK_SPACE_DAYS_IGNORE')
Versão: 2.2 - 07/01/2014 Thiago Reque
	- Ajuste da rotina de monitoração do Identity e Dias de Crescimento
Versão: 2.3 - 30/01/2014 Thiago Reque
	- Ajuste da rotina de monitoração - Ticket : 1076231
	- Removido a DBA_SNAP_TEMP_ALLOCATION e adicionado a DBA_SNAP_TEMPDB
	- Ajuste na inserção do DBA_PARAMS para o SERVER_NAME
Versão: 2.4 - 25/02/2014 Alexandre Mühlen
	- Ajustes na rotina de monitoração
		- Considerar somente a última execução dos DBA Jobs
		- Corrigido problema na coleta de crescimento
		- Corrigido erro no monitoramento do crescimento, quando não ocorre crescimento
		- Ajustada rotina de alocação de espaço

--------------- NEW Changelog

2017-12-23 - Thiago Reque
  - Adjustments for add in Github


**** NOT SUPORTED ON LINUX INSTANCES (yet)!!!!
*/


-- PARAMS
DECLARE  @DIR_LOG varchar(MAX)
		,@DIR_DATE varchar(MAX)
		,@DIR_ZABBIX varchar(MAX)
		,@CUSTOMER varchar(1000)
		,@ALERT_EMAIL varchar(2000)
		
-- SET PARAMS
SELECT   @DIR_LOG = 'C:\SQL'			--- PATH FOR LOGFILE
   		,@DIR_DATA = 'C:\SQL'			--- PATH FOR DATAFILE
		,@DIR_ZABBIX = 'C:\SQL'			--- PATH TO SOME OUTPUT	FILES FOR ZABBIX READ
		,@CUSTOMER = 'Personal'			--- CUSTOMER NAME (setting up for job params)
		,@ALERT_EMAIL = 'my@email.com'	--- EMAIL TO RECEIVE SOME ALERTS

	   
-- VARIABLES
DECLARE @SQL VARCHAR(MAX)

--------- CREATE database DBA -------------------------------
SELECT @SQL = '
	USE master;
	CREATE database DBA 
		ON PRIMARY  
			(NAME = ''DBA_DATA'', FILENAME = ''' + @DIR_DATA + '\DBA_DATA.mdf'', SIZE = 50 MB, FILEGROWTH = 50 MB, MAXSIZE = UNLIMITED)
		LOG ON
			(NAME = ''DBA_log'', FILENAME = ''' + @DIR_LOG + '\DBA_log.ldf'', SIZE = 25 MB, FILEGROWTH = 25 MB, MAXSIZE = UNLIMITED);
'

EXECUTE(@SQL)

IF ()
BEGIN
	ALTER AUTHORIZATION ON database::DBA TO sa
	GO

	USE DBA
	GO

	CREATE TABLE DBA_PARAMS
	(
	 PARAM_NAME VARCHAR(100) CONSTRAINT PK_PARAMS PRIMARY KEY,
	 PARAM_VALUE VARCHAR(MAX)
	)
	GO

	CREATE TABLE DBA_VERSION_CONTROLL
	(
		VERSION VARCHAR(20)
	)
	GO

	INSERT INTO DBA_VERSION_CONTROLL (VERSION) VALUES ('2.4')
	GO

	CREATE TABLE  DBA_INFO_database
	(   
	    DATE DATETIME,
		DATABASENAME VARCHAR(100),  	
		FILESIZEMB NUMERIC(17,2),  
		LOGICALFILENAME SYSNAME,  
		PHYSICALFILENAME NVARCHAR(520),  
		STATUS SYSNAME,  
		UPDATEABILITY SYSNAME,  
		RECOVERYMODE SYSNAME,  
		FREESPACEMB NUMERIC(17,2),  
		FREESPACEPCT VARCHAR(7), 
	    CONSTRAINT PK_DBA_INFO_database PRIMARY Key	(DATE, DATABASENAME, LOGICALFILENAME)
	)  
	GO

	CREATE TABLE DBA_INFO_FILESYSTEM
	(
	  DRIVE VARCHAR(10),
	  FREEMB NUMERIC(17,2), 
	  DATE DATETIME DEFAULT CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 103), 103), 
	  CONSTRAINT PK_DBA_INFO_FILESYSTEM PRIMARY KEY(DATE, DRIVE) 
	)
	GO

	CREATE TABLE DBA_INFO_TABLE
	(
	  DATE DATETIME ,
	  DATABASENAME VARCHAR(1000), 
	  TABLENAME VARCHAR(1000),
	  [ROWS] BIGINT,
	  DATE_SIZE NUMERIC(18,2),
	  RESERVED NUMERIC(18,2),
	  INDEX_SIZE NUMERIC(18,2),
	  UNUSED NUMERIC(18,2), 
	  CONSTRAINT PK_DBA_INFO_TABLE PRIMARY KEY(DATE, DATABASENAME, TABLENAME)
	)
	GO

	CREATE TABLE DBA_INFO_BACKUP_GROWTH
	(
	  DATE DATETIME,
	  DATABASENAME VARCHAR(1000),	    
	  MONTH_GROWTH NUMERIC(18,2), 
	  DAY_GROWTH NUMERIC(18,2), 
	  CONSTRAINT PK_DBA_INFO_BACKUP_GROWTH PRIMARY KEY(DATE, database_name)
	)
	GO

	CREATE TABLE [dbo].[DBA_LOGIN_FAIL](
		DATE DATETIME NOT NULL, -- dd/mm/yyyy
		HOUR INT NOT NULL,
		LOGINNAME VARCHAR (128) NOT NULL,
		CLIENTADDRESS VARCHAR (200) NOT NULL,
		COUNTFAIL INT,
		EVENTMSG XML, 
	   CONSTRAINT PK_DBA_LOGIN_FAIL PRIMARY KEY (DATE, HOUR, LOGINNAME, CLIENTADDRESS)
	)
	GO

	CREATE TABLE DBA_DEADLOCKGRAPH (
		ID INT IDENTITY(1,1), 
		EVENTMSG xml, 
		DATE DATETIME DEFAULT(GETDATE()),
		CONSTRAINT PK_DBA_DEADLOCKGRAPH PRIMARY KEY(DATE, ID) 
	)
	GO

	CREATE TABLE dbo.DBA_DDL_HISTORY
	(
		DATABASENAME VARCHAR(100),
		DDL XML NOT NULL
	)
	GO

	CREATE TABLE [dbo].[DBA_SNAP_SESSIONS](
		[DATE] [datetime] NOT NULL,
		[spid] [smallint] NOT NULL,
		[login_time] [datetime] NOT NULL,
		[host_name] [nvarchar](128) NULL,
		[program_name] [nvarchar](256) NULL,
		[client_interface_name] [nvarchar](32) NULL,
		[login_name] [nvarchar](128) NOT NULL,
		[nt_user_name] [nvarchar](128) NULL, 
	) ON [PRIMARY]
	GO

	CREATE CLUSTERED INDEX IDX_DBA_SNAP_SESSIONS_DATE_SPID
	ON [DBA_SNAP_SESSIONS](DATE, spid)
	GO

	CREATE TABLE [dbo].[DBA_SNAP_BLOCKS](
		[DATE] datetime not null, 
		[lock_type] [nvarchar](60) NOT NULL,
		DATABASENAME [nvarchar](128) NULL,
		[blk_object] [bigint] NOT NULL,
		[lock_req] [nvarchar](60) NOT NULL,
		[waiter_sid] [int] NOT NULL,
		[wait_time] [bigint] NULL,
		[waiter_batch] [nvarchar](max) NULL,
		[waiter_stmt] [nvarchar](max) NULL,
		[blocker_sid] [smallint] NOT NULL,
		[blocker_stmt] [nvarchar](max) NULL
	) ON [PRIMARY]
	GO

	CREATE CLUSTERED INDEX IDX_DBA_SNAP_BLOCKS_DATE_sid
	ON [DBA_SNAP_BLOCKS](DATE, [blocker_sid], [waiter_sid])
	GO


	CREATE TABLE [dbo].[DBA_SNAP_CACHE](
		[DATE] datetime not null, 
		[avg_logical_reads] [bigint] NULL,
		[avg_logical_writes] [bigint] NULL,
		[avg_phys_reads] [bigint] NULL,
		[Execution_count] [bigint] NOT NULL,
		[last_execution_time] [datetime] NOT NULL,
		[total_worker_time] [bigint] NOT NULL,
		[total_elapsed_time] [bigint] NOT NULL,
		[avg_elapsed_time] [bigint] NULL,
		[sql_handle] [varbinary](64) NOT NULL,
		creation_time datetime NOT NULL,
		[statement_text] [nvarchar](max) NULL
	) ON [PRIMARY]
	GO

	CREATE CLUSTERED INDEX IDX_SNAP_CACHE 
	ON [DBA_SNAP_CACHE](DATE)
	;

	CREATE TABLE [dbo].[DBA_SNAP_REQUESTS](
		[DATE] datetime not null, 
		[spid] [smallint] NOT NULL,
		[database] [nvarchar](128) NULL,
		[start_time] [datetime] NOT NULL,
		[status] [nvarchar](30) NOT NULL,
		[command] [nvarchar](max) NOT NULL,
		[sql_handle] [varbinary](64) NOT NULL,
		[obj] [nvarchar](517) NULL,
		[text] [nvarchar](max) NULL,
		[text_Full] [nvarchar](max) NULL,
		[blocking_session_id] [smallint] NULL,
		[wait_type] [nvarchar](60) NULL,
		[wait_time] [int] NOT NULL,
		[wait_resource] [nvarchar](256) NOT NULL,
		[query_plan] [xml] NULL
	) ON [PRIMARY]
	GO


	CREATE CLUSTERED INDEX IDX_DBA_SNAP_REQUESTS_DATE_spid
	ON [DBA_SNAP_REQUESTS](DATE, [spid])
	GO


	CREATE TABLE [dbo].DBA_SNAP_TRANSACTIONS(
		[DATE] [datetime] NOT NULL,
		[transaction_id] [bigint] NOT NULL,
		[name] [nvarchar](32) NOT NULL,
		[transaction_begin_time] [datetime] NOT NULL,
		[session_id] [int] NOT NULL,
		[login_time] [datetime] NOT NULL,
		[host_name] [nvarchar](128) NULL,
		[program_name] [nvarchar](256) NULL,
		[client_interface_name] [nvarchar](32) NULL,
	    [login_name] [nvarchar](128) NOT NULL,
		[nt_domain] [nvarchar](128) NOT NULL,
		[total_elapsed_time] [int] NOT NULL,
		[last_request_start_time] [datetime] NOT NULL,
		[last_request_end_time] [datetime] NULL,
		[reads] [bigint] NOT NULL,
		[writes] [bigint] NOT NULL,
		[logical_reads] [bigint] NOT NULL
	);


	CREATE CLUSTERED INDEX IDX_DBA_SNAP_TRANSACTIONS_DATE_spid
	ON DBA_SNAP_TRANSACTIONS(DATE, session_id)
	GO

	CREATE TABLE DBA_SNAP_OS_WAITING_TASKS(
		DATE DATETIME NOT NULL,
		WAITING_TASK_ADDRESS VARBINARY(8) NOT NULL,
		SESSION_ID SMALLINT NULL,
		EXEC_CONTEXT_ID INT NULL,
		WAIT_DURATION_MS BIGINT NULL,
		WAIT_TYPE NVARCHAR(60) NULL,
		RESOURCE_ADDRESS VARBINARY(8) NULL,
		BLOCKING_TASK_ADDRESS VARBINARY(8) NULL,
		BLOCKING_SESSION_ID SMALLINT NULL,
		BLOCKING_EXEC_CONTEXT_ID INT NULL,
		RESOURCE_DESCRIPTION NVARCHAR(1024) NULL
	) 
	GO

	CREATE CLUSTERED INDEX IDX_DBA_SNAP_OS_WAITING_TASKS_DATE_spid
	ON DBA_SNAP_OS_WAITING_TASKS(DATE, SESSION_ID)
	GO

	CREATE TABLE DBA_INFO_ALLOCATION
	(
		DATE	varchar(30) NOT NULL,
		DATABASENAME	varchar(100) NOT NULL,
		LOGICALFILENAME SYSNAME,
		FILESIZEMB	numeric(9) NOT NULL,
		FREESPACEMB	numeric(9) NOT NULL,
		NEW_FILESIZE	numeric(13) NOT NULL
	)
	GO


	CREATE TABLE DBA_LOGINCHANGELOG 
	(
		ID INT IDENTITY(1,1) CONSTRAINT PK_LOGINCHANGELOG PRIMARY KEY,
		DATE DATETIME CONSTRAINT DF_LOGINCHANGELOG_DATE DEFAULT(GETDATE()),
		CLIENT_NET_ADDRESS VARCHAR(48),
		HOSTNAME VARCHAR(128),
		EventMsg XML
	)
	GO

	CREATE TABLE [dbo].[DBA_SNAP_IDENTITY](
		[DATE] [date] NULL,
		[DBNAME] [varchar](max) NULL,
		[OBJECT_ID] [int] NULL,
		[TBNAME] [varchar](max) NULL,
		[COLNAME] [varchar](max) NULL,
		[TYPENAME] [varchar](50) NULL,
		[LAST_VALUE] [bigint] NULL,
		[MAX_VALUE] [bigint] NULL,
		[REMAINING_VALUE] [bigint] NULL
	)
	GO

	CREATE TABLE [dbo].[DBA_SNAP_TEMPDB](
		[DATE] [datetime] NULL,
		[SESSION_ID] [int] NULL,
		[TEMP_ALLOCATED] [bigint] NULL,
		[TEMP_DEALLOCATED] [bigint] NULL,
		[LOGIN_NAME] [varchar](100) NULL,
		[STATUS] [varchar](50) NULL,
		[LAST_REQUEST_START_TIME] [datetime] NULL,
		[LAST_REQUEST_END_TIME] [datetime] NULL
	)
	GO

	CREATE CLUSTERED INDEX IDX_TEMP_ALLOCATION_DATE ON DBA_SNAP_TEMPDB (DATE)
	GO

	CREATE VIEW vDBA_CHECK_LOGINFAIL
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	SELECT	CONVERT (VARCHAR, DATE, 112) + ' ' + CONVERT (VARCHAR, HOUR) + ':00' DATE,
			HOUR, LOGINNAME [LOGIN], CLIENTADDRESS IP,
			COUNTFAIL FALHAS, EVENTMSG [XML]
	FROM [DBA_LOGIN_FAIL]
	GO

	CREATE TABLE DBA_MONITOR_COUNTER_LOG (
		DATE DATETIME NOT NULL,
		LOG_TYPE VARCHAR(100) NOT NULL,
		COUNTER INT
	)
	GO

	ALTER TABLE DBA_MONITOR_COUNTER_LOG
		ADD CONSTRAINT PK_DBA_MONITOR_COUNTER_LOG PRIMARY KEY (DATE, LOG_TYPE)
	GO

	CREATE TABLE DBA_MONITOR_CRITICAL_JOBS (
		JOB_NAME VARCHAR(200) NOT NULL,
		FAILURES_TOLERANCE INT NOT NULL,
		INACTIVE_MIN_TOLERANCE INT,
		RUNNING_MIN_TOLERANCE INT,
		DAILY_EXECUTION_TIME_LIMIT VARCHAR (8), -- 00:00:00 (Should execute before this time)
		ACTIVE BIT DEFAULT(1),
		IGNORE_UNTIL DATETIME,
		CONSTRAINT PK_DBA_MONITOR_CRITICAL_JOBS PRIMARY KEY (JOB_NAME)
	 )
	GO

	CREATE TABLE DBA_MONITOR_CRITICAL_JOBS_ERROR_LOG (
		DATE DATETIME NOT NULL,
		JOB_NAME VARCHAR(200) NOT NULL,
		MSG VARCHAR (MAX),
		CONSTRAINT PK_DBA_MONITOR_CRITICAL_JOBS_ERROR_LOG PRIMARY KEY (DATE, JOB_NAME)
	 )
	GO

	CREATE VIEW vDBA_CHECK_DEADLOCKS
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	SELECT 
		DATE,
		CASE WHEN x.col.value ('../../@victim', 'nvarchar (100)') = x.col.value ('@id', 'nvarchar (100)') THEN 'VICTIM' ELSE '' END VITIMA,
		x.col.value ('@spid', 'nvarchar (5)') SPID,
		x.col.value ('@clientapp', 'nvarchar (50)') APPNAME,
		x.col.value ('@hostname', 'nvarchar (20)') [HOSTNAME],
		x.col.value ('@loginname', 'nvarchar (30)') [LOGIN],
		x.col.value ('executionStack[1]', 'nvarchar (500)') [SQL],
		EventMsg [XML]
	FROM DBA_DEADLOCKGRAPH
	CROSS APPLY EventMsg.nodes ('/EVENT_INSTANCE/TextDATE/deadlock-list/deadlock/process-list/process') x(col)
	GO

	CREATE VIEW dbo.vDBA_CHECK_DDLHISTORY
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	  select 
		 DATABASENAME,
	     DDL.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'VARCHAR(8000)') SCRIPT,
	     DDL.value('(/EVENT_INSTANCE/PostTime)[1]', 'DATETIME') CHANGE_DATE,
	     DDL.value('(/EVENT_INSTANCE/LoginName)[1]', 'VARCHAR(128)') LOGINNAME, 
	     DDL
	  from DBA_DDL_HISTORY
	GO

	CREATE VIEW vDBA_CHECK_LOGINCHANGELOG
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	SELECT
		DATE, CLIENT_NET_ADDRESS, HOSTNAME,
		EventMsg.value ('(/EVENT_INSTANCE/LoginName)[1]', 'nvarchar (100)') LoginName,  
		EventMsg.value ('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar (20)') EventType,  
		EventMsg.value ('(/EVENT_INSTANCE/ObjectName)[1]', 'nvarchar (100)') ObjectName,  
		EventMsg.value ('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'nvarchar (500)') [SQL],  
		EventMsg [XML]  
	FROM DBA_LOGINCHANGELOG  

	GO

	----- Setting configurations for jobs

	INSERT INTO DBA_PARAMS(PARAM_NAME, PARAM_VALUE)
	SELECT	   'CUSTOMER_NAME', @CUSTOMER
	UNION ALL
	SELECT	   'SERVER_NAME', @@SERVERNAME
	UNION ALL
	SELECT	   'INDEX_THRESHOLD_REORG', '10'
	UNION ALL
	SELECT	   'INDEX_THRESHOLD_REBUILD', '30'
	UNION ALL
	SELECT	   'INDEX_THRESHOLD_FILLFACTOR', '100'
	UNION ALL
	SELECT	   'DATA_GROWTH_STATS_RETENTION', '90'
	UNION ALL
	SELECT	   'MONITOR_LOG_RETENTION', '90'
	UNION ALL
	SELECT	   'SNAPSHOT_DATE_RETENTION', '30'
	UNION ALL
	SELECT	   'DISK_SPACE_DAYS', '90'
	UNION ALL
	SELECT	   'DISK_SPACE_THRESHOLD', '20'
	UNION ALL
	SELECT	   'DISK_SPACE_MARGIN', '1'
	UNION ALL
	SELECT	   'SNAPSHOT_QUERY_PLAN_RETENTION', '7'
	UNION ALL
	SELECT 	   'BACKUP_HOURS_WARNING', '24'
	UNION ALL
	SELECT 	   'BACKUP_HOURS_HIGH','48'

	GO
	EXEC sp_grantdbaccess 'guest'
	GO
	GRANT INSERT ON DBA_DDL_HISTORY TO PUBLIC
	GO
	GRANT INSERT ON DBA_DDL_HISTORY TO guest
	GO
	GRANT INSERT ON DBA_LOGINCHANGELOG TO PUBLIC
	GO
	GRANT INSERT ON DBA_LOGINCHANGELOG TO guest
	GO

	------------------------------------------------------------

	-------------- REBUILD AND REORGANIZE INDEXES --------------
	use master
	go

	IF OBJECT_ID('dbo.sp_DBA_Maintenance_plan_indexes') IS NOT NULL
	  DROP PROCEDURE sp_DBA_Maintenance_plan_indexes
	GO

	CREATE PROCEDURE dbo.sp_DBA_Maintenance_plan_indexes
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS 
	BEGIN 
		
		
		DECLARE @cmd NVARCHAR(1000)  
		DECLARE @Table VARCHAR(255)  
		DECLARE @SchemaName VARCHAR(255) 
		DECLARE @IndexName VARCHAR(255) 
		DECLARE @partition_number INT
		DECLARE @is_partitioned INT
		DECLARE @AvgFragmentationInPercent DECIMAL 
		DECLARE @fillfactor INT  
		DECLARE @FragmentationThresholdForReorganizeTableLowerLimit VARCHAR(10) 
		DECLARE @FragmentationThresholdForRebuildTableLowerLimit VARCHAR(10) 
		DECLARE @Message VARCHAR(1000) 

		SET NOCOUNT ON 
		
		--You can specify your customized value for reorganize and rebuild indexes, the default values 
		--of 10 and 30 means index will be reorgnized if the fragmentation level is more than equal to 10  
		--and less than 30, if the fragmentation level is more than equal to 30 then index will be rebuilt 
		SELECT 
			@fillfactor = (SELECT CONVERT(INT, PARAM_VALUE) FROM DBA.dbo.DBA_PARAMS WHERE PARAM_NAME = 'INDEX_THRESHOLD_FILLFACTOR'),
			@FragmentationThresholdForReorganizeTableLowerLimit = (SELECT CONVERT(INT, PARAM_VALUE) FROM DBA.dbo.DBA_PARAMS WHERE PARAM_NAME = 'INDEX_THRESHOLD_REORG'),
			@FragmentationThresholdForRebuildTableLowerLimit = (SELECT CONVERT(INT, PARAM_VALUE) FROM DBA.dbo.DBA_PARAMS WHERE PARAM_NAME = 'INDEX_THRESHOLD_REBUILD')

		BEGIN TRY 

		-- ensure the temporary table does not exist 
		IF (SELECT OBJECT_ID('tempdb..#FramentedTableList')) IS NOT NULL 
		DROP TABLE #FramentedTableList; 

		SET @Message = 'DATE : ' + CONVERT(VARCHAR, GETDATE()) + ' - Retrieving indexes with high fragmentation from ' + DB_NAME() + ' database.' 
		RAISERROR(@Message, 0, 1) WITH NOWAIT 


		SELECT OBJECT_NAME(IPS.object_id) AS [TableName], avg_fragmentation_in_percent, SI.name [IndexName],  
				schema_name(ST.schema_id) AS [SchemaName], 0 AS IsProcessed, partition_number, 
				CASE WHEN (SELECT COUNT(1) FROM sys.partitions P 
						   WHERE P.object_id = SI.object_id
							 AND P.index_id = SI.index_id) > 1 THEN 1 ELSE 0 END is_partitioned
		INTO #FramentedTableList 
		FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL , NULL) IPS 
		JOIN sys.tables ST WITH (nolock) ON IPS.object_id = ST.object_id 
		JOIN sys.indexes SI WITH (nolock) ON IPS.object_id = SI.object_id AND IPS.index_id = SI.index_id 
		WHERE ST.is_ms_shipped = 0 AND SI.name IS NOT NULL 
		AND avg_fragmentation_in_percent >= CONVERT(DECIMAL, 10)  
		ORDER BY avg_fragmentation_in_percent DESC 

		SET @Message = 'DATE : ' + CONVERT(VARCHAR, GETDATE()) + ' - Retrieved indexes with high fragmentation from ' + DB_NAME() + ' database.' 

		RAISERROR(@Message, 0, 1) WITH NOWAIT 
		RAISERROR('', 0, 1) WITH NOWAIT 

		WHILE EXISTS ( SELECT 1 FROM #FramentedTableList WHERE IsProcessed = 0 ) 
		BEGIN 

		  SELECT TOP 1 @Table = TableName, @AvgFragmentationInPercent = avg_fragmentation_in_percent,  
		  @SchemaName = SchemaName, @IndexName = IndexName, @partition_number = partition_number, 
		  @is_partitioned = is_partitioned	
		  FROM #FramentedTableList 
		  WHERE IsProcessed = 0 

		  --Reorganizing the index 
		  IF((@AvgFragmentationInPercent >= @FragmentationThresholdForReorganizeTableLowerLimit) AND (@AvgFragmentationInPercent < @FragmentationThresholdForRebuildTableLowerLimit)) 
		  BEGIN 
			SET @Message = 'DATE : ' + CONVERT(VARCHAR, GETDATE()) + ' - Reorganizing Index for [' + @Table + '] PARTITION = '  + convert(VARCHAR, @partition_number) + ' which has avg_fragmentation_in_percent = ' + CONVERT(VARCHAR, @AvgFragmentationInPercent) + '.' 
			RAISERROR(@Message, 0, 1) WITH NOWAIT 
			SET @cmd = 'ALTER INDEX [' + @IndexName + '] ON [' + RTRIM(LTRIM(@SchemaName)) + '].[' + RTRIM(LTRIM(@Table)) + '] REORGANIZE ' + CASE WHEN @is_partitioned = 1 THEN ' PARTITION='  + convert(VARCHAR, @partition_number) ELSE '' END
			PRINT @cmd 
			EXEC (@cmd) 
	 
			SET @Message = 'DATE : ' + CONVERT(VARCHAR, GETDATE()) + ' - Reorganize Index completed successfully for [' + @Table + ']. PARTITION = '  + convert(VARCHAR, @partition_number)  
			RAISERROR(@Message, 0, 1) WITH NOWAIT 
			RAISERROR('', 0, 1) WITH NOWAIT 
		  END 
		  --Rebuilding the index 
		  ELSE IF (@AvgFragmentationInPercent >= @FragmentationThresholdForRebuildTableLowerLimit ) 
		  BEGIN 
			SET @Message = 'DATE : ' + CONVERT(VARCHAR, GETDATE()) + ' - Rebuilding Index for [' + @Table + '] PARTITION = '  + convert(VARCHAR, @partition_number) +  ' which has avg_fragmentation_in_percent = ' + CONVERT(VARCHAR, @AvgFragmentationInPercent) + '.' 
			RAISERROR(@Message, 0, 1) WITH NOWAIT 
			SET @cmd = 'ALTER INDEX [' + @IndexName + '] ON [' + RTRIM(LTRIM(@SchemaName)) + '].[' + RTRIM(LTRIM(@Table)) + '] REBUILD ' + CASE WHEN @is_partitioned = 1 THEN ' PARTITION='  + convert(VARCHAR, @partition_number) ELSE ' WITH (FILLFACTOR = ' + CONVERT(VARCHAR(3),@fillfactor) + ', STATISTICS_NORECOMPUTE = OFF)' END 
			PRINT @cmd 
			EXEC (@cmd) 

			SET @Message = 'DATE : ' + CONVERT(VARCHAR, GETDATE()) + ' - Rebuild Index completed successfully for [' + @Table + ']. PARTITION = '  + convert(VARCHAR, @partition_number) 
			RAISERROR(@Message, 0, 1) WITH NOWAIT 
			RAISERROR('', 0, 1) WITH NOWAIT 
		  END 

		  UPDATE #FramentedTableList 
		  SET IsProcessed = 1  
		  WHERE TableName = @Table 
		  AND IndexName = @IndexName 
		  AND partition_number = @partition_number
		END 

		DROP TABLE #FramentedTableList  

		END TRY 

		BEGIN CATCH 
			DECLARE @DESC VARCHAR(8000)

			SELECT @DESC =
				'ErrorNumber: ' + CONVERT (VARCHAR(20),ERROR_NUMBER()) + CHAR(13) +
				'ErrorSeverity: ' + CONVERT (VARCHAR(20),ERROR_SEVERITY()) + CHAR(13) +
				'ErrorState: ' + CONVERT (VARCHAR(20),ERROR_STATE()) + CHAR(13) +
				'Errordatabase: ' + DB_NAME() + CHAR(13) +
				'ErrorProcedure: ' + ISNULL(ERROR_PROCEDURE(), '') + CHAR(13) +
				'ErrorLine: ' + CONVERT (VARCHAR(20),ERROR_LINE()) + CHAR(13) +
				'ErrorMessage: ' + ERROR_MESSAGE();
			
			IF @@TRANCOUNT > 0 
			ROLLBACK	

			RAISERROR(@DESC, 12, 1, 1)
		END CATCH 
	END
	GO

	use master
	go
	exec dbo.sp_MS_marksystemobject 'sp_DBA_Maintenance_plan_indexes'
	go



	USE DBA
	GO

	CREATE PROCEDURE usp_Maintenance_plan_indexes
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS 
	BEGIN
		--- INDEX REBUILD
		SET ARITHABORT ON

		DECLARE CR_DB CURSOR FOR 
		  SELECT NAME FROM master.dbo.sysdatabases WITH(NOLOCK)
		  WHERE NAME NOT IN ('tempdb')
			AND databasePROPERTYEX(NAME, 'Updateability') = 'READ_WRITE' 
			AND databasePROPERTYEX(NAME, 'status') = 'ONLINE' 
		  ORDER BY NAME

		DECLARE @NAME VARCHAR(256)
		DECLARE @B_FULL bit
		DECLARE @CMD VARCHAR(8000)


		OPEN CR_DB

		FETCH NEXT FROM CR_DB
		INTO @NAME

		WHILE(@@FETCH_STATUS = 0)
		BEGIN
			SET @B_FULL = 0
			IF databasePROPERTYEX(@NAME, 'recovery') = 'FULL'
			BEGIN
			  SET @CMD = 'ALTER database [' + @NAME + '] SET RECOVERY BULK_LOGGED'
			  EXECUTE(@CMD)

			  SET @B_FULL = 1
			END 
			
			SET @CMD = 'USE [' + @NAME + '] EXEC dbo.sp_DBA_Maintenance_plan_indexes'
			EXECUTE(@CMD)

			IF @B_FULL = 1 
			BEGIN
			  SET @CMD = 'ALTER database [' + @NAME + '] SET RECOVERY FULL'
			  EXECUTE(@CMD)      
			END	

			FETCH NEXT FROM CR_DB
			INTO @NAME	
		END

		CLOSE CR_DB
		DEALLOCATE CR_DB
	END
	GO
	------------------------------------------------------------

	------------------ UPDATE STATISTICS -----------------------
	use DBA
	go

	IF OBJECT_ID('dbo.usp_Maintenance_plan_statistics') IS NOT NULL
	  DROP PROCEDURE usp_Maintenance_plan_statistics
	GO
	CREATE PROCEDURE usp_Maintenance_plan_statistics
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	BEGIN
		EXEC master.dbo.sp_MSforeachdb '
		USE [?]
		IF (databasePROPERTYEX(''?'', ''Updateability'') = ''READ_WRITE'') AND
		   (db_name() <> ''tempdb'') AND 
		   (databasePROPERTYEX(''?'', ''Status'') = ''ONLINE'')  
		BEGIN  
			EXEC sp_updatestats
		END
		'
	END
	GO
	------------------------------------------------------------

	------------------ CHECK INTEGRITY -------------------------
	use DBA
	go

	IF OBJECT_ID('dbo.usp_Maintenance_plan_checkintegrity') IS NOT NULL
	  DROP PROCEDURE usp_Maintenance_plan_checkintegrity
	GO
	CREATE PROCEDURE usp_Maintenance_plan_checkintegrity
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	BEGIN

		EXEC master.dbo.sp_MSforeachdb '
		USE [?]
		IF (databasePROPERTYEX(''?'', ''Updateability'') = ''READ_WRITE'') AND
		   (db_name() <> ''tempdb'') AND 
		   (databasePROPERTYEX(''?'', ''Status'') = ''ONLINE'')  
		BEGIN  
			DBCC CHECKDB([?]) WITH PHYSICAL_ONLY
		END
		'
	END
	GO
	------------------------------------------------------------

	------------------- BACKUP ALERT ---------------------------
	USE DBA
	GO

	CREATE PROCEDURE [usp_backup_alert]
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	BEGIN

		SET NOCOUNT ON
		SET ANSI_WARNINGS OFF
		
		IF OBJECT_ID('tempdb..##TMP') IS NOT NULL
			DROP TABLE ##TMP

		DECLARE @thresholdW INT,
			@thresholdH INT

		SELECT @thresholdW = CONVERT(INT,PARAM_VALUE) FROM DBA_PARAMS WHERE PARAM_NAME = 'BACKUP_HOURS_WARNING'
		SELECT @thresholdH = CONVERT(INT,PARAM_VALUE) FROM DBA_PARAMS WHERE PARAM_NAME = 'BACKUP_HOURS_HIGH'

		SELECT [STATUS],[TYPE],[DB]
		INTO ##TMP
		FROM (
			SELECT CASE
					WHEN CONVERT(INT,CONVERT(VARCHAR(12), DATEDIFF(HOUR,MAX(bs.backup_finish_date),GETDATE()), 101)) > @thresholdW
						THEN '1'
					WHEN CONVERT(INT,CONVERT(VARCHAR(12), DATEDIFF(HOUR,MAX(bs.backup_finish_date),GETDATE()), 101)) > @thresholdH
						THEN '2'
					WHEN MAX(bs.backup_finish_date) IS NULL  --- There isn't any Backup yet, Warning Alert
						THEN '1'
					ELSE '0'
				END AS [STATUS]
				,'BACKUP LOG' AS [TYPE]
				,db.name AS [DB]
			FROM sys.databases db 
				LEFT OUTER JOIN msdb.dbo.backupset bs
					ON bs.database_name = db.name
					AND bs.type = 'L'
			WHERE databasePROPERTYEX(db.name, 'Status') = 'ONLINE'
				AND db.database_id > 4
				AND db.name <> 'DBA'
				AND db.recovery_model_desc in ('BULK LOGGED', 'FULL')
			GROUP BY db.name
				UNION ALL
				SELECT CASE
					WHEN CONVERT(INT,CONVERT(VARCHAR(12), DATEDIFF(HOUR,MAX(bs.backup_finish_date),GETDATE()), 101)) > @thresholdW
						THEN '1'
					WHEN CONVERT(INT,CONVERT(VARCHAR(12), DATEDIFF(HOUR,MAX(bs.backup_finish_date),GETDATE()), 101)) > @thresholdH
						THEN '2'
					WHEN MAX(bs.backup_finish_date) IS NULL
						THEN '1'
					ELSE '0'
				END
				,'BACKUP FULL E DIFF'
				,db.name 
				FROM sys.databases db 
					LEFT OUTER JOIN msdb.dbo.backupset bs
						ON bs.database_name = db.name
						AND bs.type IN ('I', 'D')
				WHERE databasePROPERTYEX(db.name, 'Status') = 'ONLINE'
					AND db.database_id > 4
					AND db.name <> 'DBA'
				GROUP BY db.name	
			) TBL
		IF NOT EXISTS (SELECT 1 FROM ##TMP WHERE TYPE = 'BACKUP LOG')
			INSERT INTO ##TMP ([TYPE], [STATUS], [DB]) VALUES ('BACKUP LOG', 0, '')
		IF NOT EXISTS (SELECT 1 FROM ##TMP WHERE TYPE = 'BACKUP FULL E DIFF')
			INSERT INTO ##TMP ([TYPE], [STATUS], [DB]) VALUES ('BACKUP FULL E DIFF', 0, '')

		-- The Return of the query for a txt file
		SELECT CONVERT(VARCHAR(100),MAX(CONVERT(INT,[STATUS])))+' | '+[TYPE] FROM ##TMP
		GROUP BY [TYPE]
		ORDER BY [TYPE];

	END
	GO
	------------------------------------------------------------

	--------------- TRACK AND PURGE DATE GROWTH STATS --------------------------
	USE DBA
	GO

	CREATE PROCEDURE [usp_track_data_growth_stats]
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	BEGIN
		BEGIN TRY
			BEGIN TRANSACTION	

				DECLARE @COMMAND VARCHAR(5000)  

				SELECT @COMMAND = '
						IF (databasePROPERTYEX(''?'', ''Status'') = ''ONLINE'')  
						BEGIN 
							USE [' + '?' + '] 
							SELECT  
								' + '''' + '?' + '''' + ' AS DATABASENAME,  
								CAST(sysfiles.size/128.0 AS NUMERIC(17,2)) AS FILESIZE,  
								LTRIM(sysfiles.name) AS LOGICALFILENAME, 
								sysfiles.filename AS PHYSICALFILENAME,  
								CONVERT(SYSNAME,databasePROPERTYEX(''?'',''STATUS'')) AS STATUS,  
								CONVERT(SYSNAME,databasePROPERTYEX(''?'',''UPDATEABILITY'')) AS UPDATEABILITY,  
								CONVERT(SYSNAME,databasePROPERTYEX(''?'',''RECOVERY'')) AS RECOVERYMODE,  
								CAST(sysfiles.size/128.0 - CAST(FILEPROPERTY(sysfiles.name, ' + '''' +  
									   'SpaceUsed' + '''' + ' ) AS NUMERIC(15,2))/128.0 AS NUMERIC(17,2)) AS FREESPACEMB,  
								CAST(100 * (CAST (((sysfiles.size/128.0 -CAST(FILEPROPERTY(sysfiles.name,  
								' + '''' + 'SpaceUsed' + '''' + ' ) AS NUMERIC(15,2))/128.0)/(sysfiles.size/128.0))  
								AS DECIMAL(4,2))) AS VARCHAR(8))  AS FREESPACEPCT,
								convert(datetime, convert(varchar, getdate(), 103), 103) AS COLLECT_DATE
							FROM dbo.sysfiles WITH(NOLOCK)
						END'  

				INSERT INTO DBA_INFO_database
				   (DATABASENAME,  
				   FILESIZEMB,  
				   LOGICALFILENAME,  
				   PHYSICALFILENAME,  
				   STATUS,  
				   UPDATEABILITY,  
				   RECOVERYMODE,  
				   FREESPACEMB,  
				   FREESPACEPCT,  
				   DATE)  	
				EXEC sp_MSforeachdb @COMMAND  
				;


				INSERT INTO DBA_INFO_FILESYSTEM(DRIVE, FREEMB)
				EXEC master.dbo.xp_fixeddrives


				IF OBJECT_ID('tempdb..##TMP') IS NOT NULL
				  DROP TABLE ##TMP
				;

				CREATE TABLE ##TMP
				(
					DATABASENAME	VARCHAR(1000),                                                                                                                            
					Tablename		VARCHAR(1000),                                                                                                                            
					rows		VARCHAR(1000),      
					reserved	VARCHAR(1000),
					data_size		VARCHAR(1000),          
					index_size  VARCHAR(1000),       
					unused	    VARCHAR(1000)
				)


				exec sp_MSforeachdb @command1='use [?] 
				IF DB_NAME() NOT IN (''tempdb'') AND 
				   (DATABASEPROPERTYEX(''?'', ''Status'') = ''ONLINE'')
				BEGIN
					DECLARE @NOME SYSNAME
					DECLARE CR_TABLES CURSOR LOCAL FAST_FORWARD
					  FOR SELECT ''['' + SCHEMA_NAME(uid) + ''].['' + NAME + '']'' as name
						  FROM sysobjects
						  WHERE xtype= ''U''

					OPEN CR_TABLES
					
					FETCH NEXT FROM CR_TABLES
					INTO @NOME

					WHILE @@FETCH_STATUS = 0
					BEGIN 

						INSERT INTO ##TMP(Tablename, rows, reserved, DATE_size, index_size, unused)
						SELECT ''[''+SCHEMA_NAME(schema_id)+''].[''+OBJECT_NAME(ps.object_id)+'']'' AS [name],
							SUM(CASE WHEN (index_id < 2) THEN (row_count)
								END) AS [rows],
							CONVERT(VARCHAR(18),SUM(in_row_reserved_page_count * 8))+'' KB'' AS [reserved],
							CONVERT(VARCHAR(18),SUM(CASE
										WHEN (index_id < 2) THEN (in_row_DATE_page_count + lob_used_page_count + row_overflow_used_page_count)
										ELSE (lob_used_page_count + row_overflow_used_page_count)
									END)
							* 8)+'' KB'' AS [DATE],
							CONVERT(VARCHAR(18),SUM(in_row_used_page_count - CASE
										WHEN (index_id < 2) THEN (in_row_DATE_page_count + lob_used_page_count + row_overflow_used_page_count)
										ELSE (lob_used_page_count + row_overflow_used_page_count)
									END)
							* 8)+'' KB'' AS [index_size],
							CONVERT(VARCHAR(18),SUM((in_row_reserved_page_count-in_row_used_page_count) * 8))+'' KB'' AS [unused]
						FROM sys.dm_db_partition_stats ps 
							INNER JOIN sys.tables tb 
								ON ps.object_id = tb.object_id 
						WHERE ps.object_id = OBJECT_ID(@NOME)
						GROUP BY ps.object_id,schema_id
						

						FETCH NEXT FROM CR_TABLES
						INTO @NOME
					END

					UPDATE ##TMP
					SET DATABASENAME = db_name()
					WHERE DATABASENAME IS NULL

					CLOSE CR_TABLES
					DEALLOCATE CR_TABLES
				END	  
				'

				INSERT INTO DBA_INFO_TABLE(DATE, DATABASENAME, TABLENAME, [ROWS], DATE_SIZE, RESERVED, INDEX_SIZE, UNUSED)
				SELECT 
					   CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 103), 103) AS DATE, 
					   DATABASENAME, 
					   Tablename,
					   CAST([rows] AS BIGINT) AS [ROWS],
					   CAST(CAST(REPLACE(reserved, 'KB', '') AS BIGINT) / 1024.0 AS NUMERIC(18,2)) AS RESERVED,
					   CAST(CAST(REPLACE(DATE_size, 'KB', '') AS BIGINT) / 1024.0 AS NUMERIC(18,2)) AS DATE_SIZE,
					   CAST(CAST(REPLACE(index_size, 'KB', '') AS BIGINT) / 1024.0 AS NUMERIC(18,2)) AS INDEX_SIZE,
					   CAST(CAST(REPLACE(unused, 'KB', '') AS BIGINT) / 1024.0 AS NUMERIC(18,2)) AS UNUSED
				FROM ##TMP

							
				INSERT INTO DBA_INFO_BACKUP_GROWTH(DATE, database_name, MONTH_GROWTH, DAY_GROWTH)
				SELECT 
					   CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 103), 103) AS DATE,
					   MAIOR.database_name,
					   CONVERT(NUMERIC(18,2), (MAIOR.backup_size - MENOR.backup_size) / 1024 / 1024) AS MONTH_GROWTH, 
					   CONVERT(NUMERIC(18,2), ((MAIOR.backup_size - MENOR.backup_size) / 1024 / 1024) / CASE WHEN DATEDIFF(DAY, MENOR.backup_finish_date, MAIOR.backup_finish_date) = 0 THEN 1 ELSE DATEDIFF(DAY, MENOR.backup_finish_date, MAIOR.backup_finish_date) END) AS DAY_GROWTH
				FROM
					(  SELECT  						    
							database_name,  
							backup_finish_date, 
							BS.backup_size
					   FROM msdb.dbo.backupset BS 
					   WHERE  EXISTS (SELECT 1 FROM sys.databases DB WHERE DB.name = BS.database_name)
						AND BS.backup_set_id = (SELECT TOP 1 BSTMP.backup_set_id 												 
												 FROM msdb.dbo.backupset BSTMP
												 WHERE BSTMP.type = 'D'
												   AND BSTMP.backup_finish_date >= DATEADD(MONTH, -1, GETDATE())
												   AND BSTMP.database_name = BS.database_name
												 ORDER BY BSTMP.backup_finish_date DESC)) MAIOR
					INNER JOIN (  SELECT  						    
										database_name,  
										backup_finish_date, 
										BS.backup_size
								   FROM msdb.dbo.backupset BS 								
								   WHERE EXISTS (SELECT 1 FROM sys.databases DB WHERE DB.name = BS.database_name)
									AND BS.backup_set_id = (SELECT TOP 1 BSTMP.backup_set_id 												 
															 FROM msdb.dbo.backupset BSTMP
															 WHERE BSTMP.type = 'D'
															   AND BSTMP.backup_finish_date >= DATEADD(MONTH, -1, GETDATE())
															   AND BSTMP.database_name = BS.database_name
															 ORDER BY BSTMP.backup_finish_date ASC)) MENOR
						ON MENOR.database_name = MAIOR.database_name


	SELECT @COMMAND = '
	IF (databasePROPERTYEX(''?'', ''Status'') = ''ONLINE'')  
						BEGIN 
							USE [' + '?' + ']

						SELECT DATE,DBNAME,OBJECT_ID,TBNAME,COLNAME,TYPENAME,LAST_VALUE,MAX_VALUE, (T1.MAX_VALUE-T1.LAST_VALUE) as REMAINING_VALUE
						FROM (
							SELECT 
								CONVERT(VARCHAR,GETDATE(),112) AS DATE,
								DB_NAME() as DBNAME,
								obj.OBJECT_ID, 
								obj.name AS TBNAME, 
								ident.name AS COLNAME,
								types.name AS TYPENAME,
								CONVERT(BIGINT, ident.last_value) AS LAST_VALUE,
								CONVERT(BIGINT, CASE types.name 
									WHEN ''int'' THEN 2147483647
									WHEN ''bigint'' THEN 9223372036854775807
									WHEN ''smallint'' THEN 32767
									WHEN ''tinyint'' THEN 255
								END ) AS MAX_VALUE
							FROM sys.identity_columns ident 
								INNER JOIN sys.all_objects obj 
									ON ident.object_id = obj.object_id
								INNER JOIN sys.systypes types
									ON types.xtype = ident.system_type_id
							WHERE obj.type_desc = ''USER_TABLE'' AND ident.last_value IS NOT NULL AND db_name() NOT IN (''master'',''model'',''msdb'',''tempdb'')
						) T1
					END
	'

	INSERT INTO DBA.dbo.DBA_SNAP_IDENTITY (DATE,DBNAME,OBJECT_ID,TBNAME,COLNAME,TYPENAME,LAST_VALUE,MAX_VALUE,REMAINING_VALUE)
	EXEC sp_MSforeachdb @COMMAND
			

			COMMIT

		END TRY
		BEGIN CATCH
			DECLARE @DESC VARCHAR(8000)
					
			SELECT @DESC =
				'ErrorNumber: ' + CONVERT (VARCHAR(20),ERROR_NUMBER()) + CHAR(13) +
				'ErrorSeverity: ' + CONVERT (VARCHAR(20),ERROR_SEVERITY()) + CHAR(13) +
				'ErrorState: ' + CONVERT (VARCHAR(20),ERROR_STATE()) + CHAR(13) +
				'Errordatabase: ' + DB_NAME() + CHAR(13) +
				'ErrorProcedure: ' + ISNULL(ERROR_PROCEDURE(), '') + CHAR(13) +
				'ErrorLine: ' + CONVERT (VARCHAR(20),ERROR_LINE()) + CHAR(13) +
				'ErrorMessage: ' + ERROR_MESSAGE();
			
			IF @@TRANCOUNT > 0 
			ROLLBACK	

			RAISERROR(@DESC, 12, 1, 1)
		END CATCH
	END
	GO
	-------------------------------------------------------
	CREATE PROCEDURE usp_purge_data_growth_stats
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	BEGIN 
		DECLARE @STATS_RETENTION INT
		SELECT @STATS_RETENTION = (SELECT CONVERT(INT, PARAM_VALUE) FROM DBA_PARAMS WHERE PARAM_NAME = 'DATA_GROWTH_STATS_RETENTION')
		
		BEGIN TRY
			BEGIN TRANSACTION
				DECLARE @DATE_BASE DATETIME 
				SET @DATE_BASE = CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE() - @STATS_RETENTION, 103), 103)

				DELETE FROM DBA_INFO_database
				WHERE DATE <= @DATE_BASE

				DELETE FROM DBA_INFO_FILESYSTEM
				WHERE DATE <= @DATE_BASE

				DELETE FROM DBA_INFO_TABLE
				WHERE DATE <= @DATE_BASE

				DELETE FROM DBA_INFO_BACKUP_GROWTH
				WHERE DATE <= @DATE_BASE

				DELETE FROM dbo.DBA_LOGIN_FAIL
				WHERE DATE <= @DATE_BASE
				
				DELETE FROM DBA_SNAP_IDENTITY
				WHERE DATE <= @DATE_BASE
				
			COMMIT
		END TRY
		BEGIN CATCH
			DECLARE @DESC VARCHAR(8000)

			SELECT @DESC =
				'ErrorNumber: ' + CONVERT (VARCHAR(20),ERROR_NUMBER()) + CHAR(13) +
				'ErrorSeverity: ' + CONVERT (VARCHAR(20),ERROR_SEVERITY()) + CHAR(13) +
				'ErrorState: ' + CONVERT (VARCHAR(20),ERROR_STATE()) + CHAR(13) +
				'Errordatabase: ' + DB_NAME() + CHAR(13) +
				'ErrorProcedure: ' + ISNULL(ERROR_PROCEDURE(), '') + CHAR(13) +
				'ErrorLine: ' + CONVERT (VARCHAR(20),ERROR_LINE()) + CHAR(13) +
				'ErrorMessage: ' + ERROR_MESSAGE();
			
			IF @@TRANCOUNT > 0 
			ROLLBACK	

			RAISERROR(@DESC, 12, 1, 1)
		END CATCH

	END
	GO
	-------------------------------------------------------

	--------------- LOGIN FAILED ALERT --------------------
	USE master
	GO
	ALTER database DBA SET ENABLE_BROKER
	GO

	USE DBA
	GO

	CREATE QUEUE LoginFailQueue; 

	CREATE SERVICE LoginFailService
		ON QUEUE LoginFailQueue([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);

	CREATE ROUTE LoginFailRoute 
		WITH SERVICE_NAME = N'LoginFailService'
			, ADDRESS = N'LOCAL';
	go

	EXEC AS LOGIN = 'sa';
	go

	IF EXISTS (SELECT 1 FROM master.sys.server_event_notifications WHERE name = 'LoginFailNotification')
		DROP EVENT NOTIFICATION LoginFailNotification ON SERVER

	CREATE EVENT NOTIFICATION LoginFailNotification 
		ON SERVER FOR AUDIT_LOGIN_FAILED 
			TO SERVICE 'LoginFailService', 'current database';
	go
	REVERT;
	GO 

	SET ANSI_NULLS ON;
	SET QUOTED_IDENTIFIER ON;
	GO

	CREATE PROCEDURE dbo.usp_ProcessLoginFail
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	BEGIN
		SET NOCOUNT ON;
		WHILE (1 = 1)    
		BEGIN
			DECLARE @messageBody VARBINARY(MAX);      
			DECLARE @messageTypeName NVARCHAR(256);           
			
			WAITFOR (
				RECEIVE TOP(1)                    
					@messageTypeName = message_type_name,                    
					@messageBody = message_body                    
				FROM LoginFailQueue                 
			), TIMEOUT 500
			
			IF @@ROWCOUNT = 0 BREAK ;        

			IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/Notifications/EventNotification')
			BEGIN
				DECLARE @XML XML,
						@DATE DATETIME,
						@HOUR INT,
						@LOGINNAME VARCHAR (128),
						@HOSTNAME VARCHAR (128),
						@CLIENTADDRESS VARCHAR (200),
						@TEXT VARCHAR (MAX)

				SELECT @XML=CONVERT(XML,@messageBody)

				SELECT @DATE = @XML.value('(/EVENT_INSTANCE/StartTime)[1]', 'NVARCHAR(128)')
					, @HOSTNAME = @XML.value('(/EVENT_INSTANCE/HostName)[1]', 'NVARCHAR(128)')
					, @LOGINNAME = @XML.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(500)')
					, @TEXT = @XML.value('(/EVENT_INSTANCE/TextDATE)[1]', 'NVARCHAR(128)');
				
				SELECT @HOUR = DATEPART (HOUR, @DATE)
				SELECT @DATE = CONVERT (VARCHAR, @DATE, 112)
				
				SELECT @CLIENTADDRESS = LEFT (SUBSTRING (@TEXT, PATINDEX ('%CLIENT: %', @TEXT)+8, LEN (@TEXT)), LEN (SUBSTRING (@TEXT, PATINDEX ('%CLIENT: %', @TEXT)+8, LEN (@TEXT)))-1)
				
				UPDATE [dbo].[DBA_LOGIN_FAIL]
				SET COUNTFAIL = COUNTFAIL + 1
				WHERE	DATE = @DATE AND 
						HOUR = @HOUR AND 
						LOGINNAME = @LOGINNAME AND 
						CLIENTADDRESS = @CLIENTADDRESS
				
				IF @@ROWCOUNT = 0
					INSERT INTO [dbo].[DBA_LOGIN_FAIL] (DATE, HOUR, LOGINNAME, CLIENTADDRESS, COUNTFAIL, EVENTMSG)
					VALUES (@DATE, @HOUR, @LOGINNAME, @CLIENTADDRESS, 1, @XML)
			END;
		END;
	END;

	GO
	ALTER QUEUE LoginFailQueue    
	WITH STATUS=ON
		,   ACTIVATION ( STATUS=ON
						, PROCEDURE_NAME = dbo.usp_ProcessLoginFail
						, MAX_QUEUE_READERS = 1
						, EXECUTE AS SELF) ;
	GO

	CREATE PROCEDURE [usp_login_failed_alert]
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	BEGIN

		SET NOCOUNT ON

		SELECT COALESCE(CONVERT(VARCHAR(10), SUM(COUNTFAIL)),'0')+' | FALHAS DE LOGIN' AS [FALHAS DE LOGIN] 
		FROM DBA.dbo.DBA_LOGIN_FAIL 
		WHERE DATE >= CONVERT (VARCHAR(20), GETDATE() -1, 112) AND [LOGINNAME] != '{$USER}'

	END
	GO
	------------------------------------------------------------

	------------------- DEADLOCK MONITOR -------------------
	USE master
	GO
	ALTER database DBA SET ENABLE_BROKER
	GO

	USE DBA
	GO
	-- Procedimento de processamento de deadlocks
	CREATE PROCEDURE usp_ProcessDeadlockNotification
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	    DECLARE @msgBody XML    
	    DECLARE @dlgId uniqueidentifier

	    WHILE(1=1)
	    BEGIN
	        BEGIN TRANSACTION    
	        BEGIN TRY        
	            ;RECEIVE TOP(1) 
	                    @msgBody    = message_body,
	                    @dlgId        = conversation_handle
	            FROM    dbo.DeadLockNotificationsQueue
	            
	            IF @@ROWCOUNT = 0
	            BEGIN
	                IF @@TRANCOUNT > 0
	                BEGIN 
	                    ROLLBACK;
	                END  
	                BREAK;
	            END 

	            INSERT INTO dbo.DBA_DEADLOCKGRAPH(EventMsg)
	            SELECT @msgBody WHERE @msgBody IS NOT NULL
	            
	            IF @@TRANCOUNT > 0
	            BEGIN 
	                COMMIT;
	            END
	        END TRY
	        BEGIN CATCH
				DECLARE @DESC VARCHAR(8000)

				SELECT @DESC =
					'ErrorNumber: ' + CONVERT (VARCHAR(20),ERROR_NUMBER()) + CHAR(13) +
					'ErrorSeverity: ' + CONVERT (VARCHAR(20),ERROR_SEVERITY()) + CHAR(13) +
					'ErrorState: ' + CONVERT (VARCHAR(20),ERROR_STATE()) + CHAR(13) +
					'Errordatabase: ' + DB_NAME() + CHAR(13) +
					'ErrorProcedure: ' + ISNULL(ERROR_PROCEDURE(), '') + CHAR(13) +
					'ErrorLine: ' + CONVERT (VARCHAR(20),ERROR_LINE()) + CHAR(13) +
					'ErrorMessage: ' + ERROR_MESSAGE();
				
				IF @@TRANCOUNT > 0 
				ROLLBACK	

				RAISERROR(@DESC, 12, 1, 1)
	        END CATCH;
	    END
	GO

	CREATE QUEUE DeadLockNotificationsQueue
	    WITH STATUS = ON,
	    ACTIVATION (
	        PROCEDURE_NAME = usp_ProcessDeadlockNotification,
	        MAX_QUEUE_READERS = 1,
	        EXECUTE AS 'dbo' );
	GO

	CREATE SERVICE DeadLockNotificationsService
	    ON QUEUE DeadLockNotificationsQueue 
	                ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
	GO

	CREATE ROUTE DeadLockNotificationsRoute
	    WITH SERVICE_NAME = 'DeadLockNotificationsService',
	    ADDRESS = 'LOCAL';
	GO
	IF EXISTS (SELECT 1 FROM master.sys.server_event_notifications WHERE name = 'DeadLockNotificationEvent')
		DROP EVENT NOTIFICATION DeadLockNotificationEvent ON SERVER

	CREATE EVENT NOTIFICATION DeadLockNotificationEvent
	ON SERVER 
	FOR DEADLOCK_GRAPH
	TO SERVICE 'DeadLockNotificationsService', 
	           'current database'
	GO

	CREATE PROCEDURE [usp_deadlocks_alert]
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	BEGIN

		SET NOCOUNT ON

		SELECT COALESCE(CONVERT(VARCHAR(10), COUNT(1)),'0')+' | DEADLOCKS' AS [DEADLOCKS]
		FROM DBA.dbo.DBA_DEADLOCKGRAPH 
		WHERE DATE >= CONVERT (VARCHAR(20), GETDATE() -1, 112)

	END
	GO
	------------------------------------------------------------

	----------------- TRACK DDL COMMANDS -----------------------
	USE DBA
	GO

	DECLARE @NAME SYSNAME
	DECLARE @SQL VARCHAR(MAX)

	DECLARE CR_DB CURSOR FOR 
		  SELECT name FROM master.dbo.sysdatabases WITH(NOLOCK)
		  WHERE name NOT IN ('tempdb')
			AND databasePROPERTYEX(name, 'Updateability') = 'READ_WRITE' 
			AND databasePROPERTYEX(name, 'Status') = 'ONLINE' 
		  ORDER BY name

	OPEN CR_DB

	FETCH NEXT FROM CR_DB
	INTO @NAME

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		--- CHECK IF EXISTS
		SELECT @SQL = 'USE [' + @NAME + ']
		IF EXISTS (SELECT * FROM [' + @NAME + '].sys.triggers where name = ''TRG_ALL_DDL_EVENTS'')
			EXEC sp_executesql N''DROP TRIGGER TRG_ALL_DDL_EVENTS ON database'''
		EXECUTE(@SQL)

		SELECT @SQL = 'USE [' + @NAME + ']
			EXEC sp_executesql N''
			CREATE TRIGGER TRG_ALL_DDL_EVENTS
			ON database
			FOR DROP_INDEX, CREATE_INDEX, DDL_VIEW_EVENTS, DDL_TABLE_EVENTS,
				DDL_TRIGGER_EVENTS,
				DDL_FUNCTION_EVENTS, DDL_SYNONYM_EVENTS, DDL_SSB_EVENTS, DDL_database_SECURITY_EVENTS,
				DDL_EVENT_NOTIFICATION_EVENTS, DDL_PROCEDURE_EVENTS, DDL_TYPE_EVENTS, DDL_XML_SCHEMA_COLLECTION_EVENTS,
				DDL_PARTITION_EVENTS, DDL_ASSEMBLY_EVENTS
			AS 
			BEGIN
			  DECLARE @xml XML
			  SET @xml = EVENTDATE()  

			  INSERT INTO DBA.dbo.DBA_DDL_HISTORY(DATABASENAME, DDL)
			  SELECT DB_NAME(), 
					 @xml
			END'''

		EXEC(@SQL)

		FETCH NEXT FROM CR_DB
		INTO @NAME
	END

	CLOSE CR_DB
	DEALLOCATE CR_DB
	GO
	------------------------------------------------------------

	----------------- TRACK LOGIN/USER CHANGES -----------------
	----------------- ONLY FOR SQL SERVER 2008 -----------------

	DECLARE @sql VARCHAR (MAX)
	IF CONVERT (INT, REPLACE (LEFT (CONVERT (VARCHAR, SERVERPROPERTY('ProductVersion')), 2), '.', '')) = 10
		SET @sql = '
	CREATE TRIGGER TRG_LOGINCHANGELOG
	ON ALL SERVER
	with EXEC as  ''sa''
	FOR DDL_SERVER_SECURITY_EVENTS, DDL_database_SECURITY_EVENTS
	AS 
	BEGIN
		DECLARE @xml XML, @spid INT
		SET @xml = EVENTDATE()
		
		SELECT
			@spid = x.col.value (''../SPID[1]'', ''int'')
		FROM @xml.nodes (''/EVENT_INSTANCE/TSQLCommand'') x(col)

		INSERT INTO DBA.dbo.DBA_LOGINCHANGELOG(EventMsg, CLIENT_NET_ADDRESS, HOSTNAME)
		SELECT @xml, client_net_address, s.host_name
		FROM sys.dm_exec_connections c, sys.dm_exec_sessions s
		WHERE c.session_id = @spid AND s.session_id = @spid
	END
	'
	EXEC (@sql)
	GO
	------------------------------------------------------------

	-------------------- TRACK SNAPSHOT ------------------------
	USE DBA
	GO

	CREATE PROCEDURE [usp_track_snapshot]
	WITH RECOMPILE
	-- START ENCRYPTION
	, ENCRYPTION
	-- END ENCRYPTION
	AS
	BEGIN
		BEGIN TRY
			  INSERT INTO DBA_SNAP_SESSIONS([DATE], [spid], [login_time], [host_name], [program_name], [client_interface_name],
				  [login_name], [nt_user_name])
			  select distinct getdate() DATE,
					 s.session_id spid, 
					 s.login_time,
					 s.host_name,
					 s.program_name,
					 s.client_interface_name,
					 s.login_name,
					 s.nt_user_name
			  from sys.dm_exec_sessions as s
				   LEFT JOIN sys.dm_exec_requests AS r 
					  ON s.session_id = r.session_id
				   LEFT JOIN (SELECT s.session_id 
							  FROM sys.dm_tran_active_transactions T
						  		   inner join sys.dm_tran_session_transactions ST
									  ON T.transaction_id = ST.transaction_id 
								   inner join sys.dm_exec_sessions s
							 		  ON ST.session_id = s.session_id
							  WHERE s.session_id > 50) t
						ON t.session_id = s.session_id
			  where s.is_user_process = 1
				AND COALESCE(t.session_id, r.session_id, 0) <> 0

			INSERT INTO [DBA_SNAP_BLOCKS](DATE, lock_type, DATABASENAME, blk_object, [lock_req], [waiter_sid], 
				[wait_time], [waiter_batch], [waiter_stmt], [blocker_sid], [blocker_stmt])
			SELECT 
				   getdate() as DATE, 
				   t1.resource_type AS 'lock_type',
				   db_name(resource_database_id) AS 'database',
				   t1.resource_associated_entity_id AS 'blk object',
				   t1.request_mode AS 'lock req', --- lock requested
				   t1.request_session_id AS 'waiter sid', 
				   t2.wait_duration_ms AS 'wait time',   -- spid of waiter  
				  (SELECT [text] 
				   FROM sys.dm_exec_requests AS r                                           -- get sql for waiter
					  CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) 
				   WHERE r.session_id = t1.request_session_id) AS 'waiter_batch',
				  (SELECT substring(qt.text,r.statement_start_offset/2, 
						(CASE WHEN r.statement_end_offset = -1 
							  THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2 
							  ELSE r.statement_end_offset END - r.statement_start_offset)/2) 
				   FROM sys.dm_exec_requests AS r
						CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS qt
				   WHERE r.session_id = t1.request_session_id) AS 'waiter_stmt',    -- statement blocked
				   t2.blocking_session_id AS 'blocker sid',                         -- spid of blocker
				  (SELECT [text] 
				   FROM sys.sysprocesses AS p                        -- get sql for blocker
					 CROSS APPLY sys.dm_exec_sql_text(p.sql_handle) 
				   WHERE p.spid = t2.blocking_session_id) AS 'blocker_stmt'
			FROM sys.dm_tran_locks AS t1 
				 INNER JOIN sys.dm_os_waiting_tasks AS t2
				   ON t1.lock_owner_address = t2.resource_address
			WHERE t2.blocking_session_id IS NOT NULL AND 
				  t1.request_session_id IS NOT NULL;



			INSERT INTO [DBA_SNAP_CACHE]([DATE], [avg_logical_reads], [avg_logical_writes], [avg_phys_reads], [Execution_count],
				[last_execution_time],[total_worker_time],[total_elapsed_time],[avg_elapsed_time],[sql_handle],[statement_text], creation_time)
			SELECT    top 10 
					  getdate() as DATE, 
					  (total_logical_reads/execution_count) as avg_logical_reads
					, (total_logical_writes/execution_count) as avg_logical_writes
					, (total_physical_reads/execution_count) as avg_phys_reads
					, execution_count
					, last_execution_time 
					, qs.total_worker_time
					, qs.total_elapsed_time 
					, qs.total_elapsed_time / qs.execution_count avg_elapsed_time
					, qs.sql_handle
					, SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,
					  ((CASE statement_end_offset 
					  WHEN -1 THEN DATELENGTH(st.text)
					  ELSE qs.statement_end_offset END 
						- qs.statement_start_offset)/2) + 1) AS statement_text, 
					qs.creation_time		
			FROM sys.dm_exec_query_stats AS qs
				 CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
			order by 
			 (total_logical_reads + total_logical_writes) Desc

			INSERT INTO DBA_SNAP_REQUESTS(
				[DATE] , [spid] , [database], [start_time], [status], [command], [sql_handle] , [obj] ,[text], text_Full,
				query_plan, [blocking_session_id] , [wait_type] ,[wait_time] ,[wait_resource])
			SELECT 
				getdate() as DATE, 
				[spid] = r.session_id,
				[database] = DB_NAME(r.database_id),
				r.start_time,
				r.[status],
				r.command,
				r.sql_handle,
				/* add other interesting columns here */
				[obj] = QUOTENAME(OBJECT_SCHEMA_NAME(t.objectid, t.[dbid]))
				+ '.' + QUOTENAME(OBJECT_NAME(t.objectid, t.[dbid])),
				CASE   
				   WHEN r.[statement_start_offset] > 0 THEN  
					  --The start of the active command is not at the beginning of the full command text 
					  CASE r.[statement_end_offset]  
						 WHEN -1 THEN  
							--The end of the full command is also the end of the active statement 
							SUBSTRING(t.text, (r.[statement_start_offset]/2) + 1, 2147483647) 
						 ELSE   
							--The end of the active statement is not at the end of the full command 
							SUBSTRING(t.text, (r.[statement_start_offset]/2) + 1, (r.[statement_end_offset] - r.[statement_start_offset])/2)   
					  END  
				   ELSE  
					  --1st part of full command is running 
					  CASE r.[statement_end_offset]  
						 WHEN -1 THEN  
							--The end of the full command is also the end of the active statement 
							RTRIM(LTRIM(t.[text]))  
						 ELSE  
							--The end of the active statement is not at the end of the full command 
							LEFT(t.text, (r.[statement_end_offset]/2) +1)  
					  END  
				   END AS [text],
				t.[text] as text_full, 		
				p.query_plan,
				r.blocking_session_id, 
				r.wait_type, 
				r.wait_time, 
				r.wait_resource
			FROM
				sys.dm_exec_requests AS r
			CROSS APPLY
				sys.dm_exec_sql_text(r.[sql_handle]) AS t
			CROSS APPLY
				sys.dm_exec_query_plan(r.plan_handle) AS p
			WHERE
				r.session_id <> @@SPID
				AND r.session_id > 50



			INSERT INTO DBA_SNAP_TRANSACTIONS([DATE], [transaction_id], [name], [transaction_begin_time], [session_id],
				[login_time], [host_name], [program_name], [client_interface_name], [login_name], [nt_domain], [total_elapsed_time],
				[last_request_start_time], [last_request_end_time], [reads], [writes], [logical_reads]) 
			select getdate() as DATE, ST.transaction_id, name, transaction_begin_time, ST.session_id, 
				login_time, host_name, program_name, client_interface_name, [login_name], nt_domain, total_elapsed_time, 
				last_request_start_time, last_request_end_time, reads, writes, logical_reads
			FROM sys.dm_tran_active_transactions T
				 inner join sys.dm_tran_session_transactions ST
					ON T.transaction_id = ST.transaction_id 
				 inner join sys.dm_exec_sessions S
					ON ST.session_id = S.session_id
				 


			INSERT INTO DBA.dbo.DBA_SNAP_OS_WAITING_TASKS(DATE ,WAITING_TASK_ADDRESS,SESSION_ID ,EXEC_CONTEXT_ID
				   ,WAIT_DURATION_MS ,WAIT_TYPE ,RESOURCE_ADDRESS ,BLOCKING_TASK_ADDRESS ,BLOCKING_SESSION_ID
				   ,BLOCKING_EXEC_CONTEXT_ID ,RESOURCE_DESCRIPTION)     
			SELECT 
			   Getdate() as DATE, waiting_task_address, session_id, exec_context_id, wait_duration_ms, wait_type, resource_address, 
				blocking_task_address, blocking_session_id, blocking_exec_context_id, resource_description
			FROM sys.dm_os_waiting_tasks
			where session_id >= 50
			 and session_id <> @@SPID
			 

			INSERT INTO DBA.dbo.DBA_SNAP_TEMPDB(DATE,SESSION_ID,TEMP_ALLOCATED,TEMP_DEALLOCATED,LOGIN_NAME,
				STATUS,LAST_REQUEST_START_TIME,LAST_REQUEST_END_TIME)
			SELECT TOP 100
				getdate(), t1.session_id, (t1.internal_objects_alloc_page_count + task_alloc) as temp_allocated, 
				(t1.internal_objects_dealloc_page_count + task_dealloc) as	temp_deallocated, t3.login_name,
				 t3.status, t3.last_request_start_time, t3.last_request_end_time
			FROM 
				sys.dm_db_session_space_usage as t1, 
				(select session_id, 
					sum(internal_objects_alloc_page_count)
						as task_alloc,
				sum (internal_objects_dealloc_page_count) as 
					task_dealloc 
					from sys.dm_db_task_space_usage group by session_id) as t2,
				sys.dm_exec_sessions as t3
			WHERE 
				t1.session_id = t2.session_id and t1.session_id = t3.session_id	and t1.session_id > 50
				and (t1.internal_objects_alloc_page_count + task_alloc) > 0

		        
		END TRY
		BEGIN CATCH
			DECLARE @DESC VARCHAR(8000)

			SELECT @DESC =
				'ErrorNumber: ' + CONVERT (VARCHAR(20),ERROR_NUMBER()) + CHAR(13) +
				'ErrorSeverity: ' + CONVERT (VARCHAR(20),ERROR_SEVERITY()) + CHAR(13) +
				'ErrorState: ' + CONVERT (VARCHAR(20),ERROR_STATE()) + CHAR(13) +
				'Errordatabase: ' + DB_NAME() + CHAR(13) +
				'ErrorProcedure: ' + ISNULL(ERROR_PROCEDURE(), '') + CHAR(13) +
				'ErrorLine: ' + CONVERT (VARCHAR(20),ERROR_LINE()) + CHAR(13) +
				'ErrorMessage: ' + ERROR_MESSAGE();
			
			IF @@TRANCOUNT > 0 
			ROLLBACK	

			RAISERROR(@DESC, 12, 1, 1)
		END CATCH
	END
	GO

	CREATE PROCEDURE usp_purge_snapshot
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	BEGIN 
		DECLARE @RETENTION_DAYS INT, @QUERY_PLAN_RETENTION INT
		SELECT @RETENTION_DAYS = (SELECT CONVERT(INT, PARAM_VALUE) FROM DBA_PARAMS WHERE PARAM_NAME = 'SNAPSHOT_DATE_RETENTION')
		SELECT @QUERY_PLAN_RETENTION = (SELECT CONVERT(INT, PARAM_VALUE) FROM DBA_PARAMS WHERE PARAM_NAME = 'SNAPSHOT_QUERY_PLAN_RETENTION')

		BEGIN TRY
			UPDATE DBA_SNAP_REQUESTS SET query_plan = NULL WHERE DATE <= getdate() - @QUERY_PLAN_RETENTION
			DELETE FROM DBA_SNAP_BLOCKS WHERE DATE <= getdate() - @RETENTION_DAYS
			DELETE FROM DBA_SNAP_CACHE WHERE DATE <= getdate() - @RETENTION_DAYS
			DELETE FROM DBA_SNAP_REQUESTS WHERE DATE <= getdate() - @RETENTION_DAYS
			DELETE FROM DBA_SNAP_SESSIONS WHERE DATE <= getdate() - @RETENTION_DAYS
			DELETE FROM DBA_SNAP_TRANSACTIONS WHERE DATE <= getdate() - @RETENTION_DAYS
			DELETE FROM DBA_SNAP_OS_WAITING_TASKS WHERE DATE <= getdate() - @RETENTION_DAYS
			DELETE FROM DBA_SNAP_TEMPDB WHERE DATE <= getdate() - @RETENTION_DAYS
		END TRY
		BEGIN CATCH
			DECLARE @DESC VARCHAR(8000)

			SELECT @DESC =
				'ErrorNumber: ' + CONVERT (VARCHAR(20),ERROR_NUMBER()) + CHAR(13) +
				'ErrorSeverity: ' + CONVERT (VARCHAR(20),ERROR_SEVERITY()) + CHAR(13) +
				'ErrorState: ' + CONVERT (VARCHAR(20),ERROR_STATE()) + CHAR(13) +
				'Errordatabase: ' + DB_NAME() + CHAR(13) +
				'ErrorProcedure: ' + ISNULL(ERROR_PROCEDURE(), '') + CHAR(13) +
				'ErrorLine: ' + CONVERT (VARCHAR(20),ERROR_LINE()) + CHAR(13) +
				'ErrorMessage: ' + ERROR_MESSAGE();
			
			IF @@TRANCOUNT > 0 
			ROLLBACK	

			RAISERROR(@DESC, 12, 1, 1)
		END CATCH
	END
	GO
	------------------------------------------------------------

	---------------- SPACE ALLOCATION FOR FILES ----------------

	USE DBA
	GO

	CREATE PROCEDURE [dbo].[usp_space_allocation_for_files]
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS 
	BEGIN

			if object_id('tempdb..#DBINFO') is not null
		  drop table #DBINFO
		

		CREATE TABLE  #DBINFO
		(   DATABASENAME VARCHAR(100),  
			FILESIZEMB NUMERIC(17,2),  
			LOGICALFILENAME SYSNAME,
			DRIVE CHAR,
			FREESPACEMB NUMERIC(17,2),  
			FREESPACEPCT VARCHAR(7),
			MAXSIZE NUMERIC(17,2))  

		DECLARE @COMMAND VARCHAR(5000)  


		SELECT @COMMAND = 'USE [' + '?' + '] 
		IF(databasePROPERTYEX(''?'', ''Updateability'') = ''READ_WRITE'' AND
			  databasePROPERTYEX(''?'', ''Status'') = ''ONLINE'')
					SELECT  
						  ' + '''' + '?' + '''' + ' AS DATABASENAME,  
						  CAST(sysfiles.size/128.0 AS NUMERIC(17,2)) AS FILESIZE,  
						  RTRIM(LTRIM(sysfiles.name)) AS LOGICALFILENAME,
						  LEFT(sysfiles.filename,1) AS DRIVE,               
						  CAST(sysfiles.size/128.0 - CAST(FILEPROPERTY(sysfiles.name, ' + '''' +  
								   'SpaceUsed' + '''' + ' ) AS NUMERIC(15,2))/128.0 AS NUMERIC(17,2)) AS FREESPACEMB,  
						  CAST(100 * (CAST (((sysfiles.size/128.0 -CAST(FILEPROPERTY(sysfiles.name,  
						  ' + '''' + 'SpaceUsed' + '''' + ' ) AS NUMERIC(15,2))/128.0)/(sysfiles.size/128.0))  
						  AS DECIMAL(4,2))) AS VARCHAR(8)) + ' + '''' + '%' + '''' + ' AS FREESPACEPCT,
						  CAST(sysfiles.maxsize /128.0 AS NUMERIC(17,2)) AS MAXSIZE
					FROM dbo.sysfiles WITH(NOLOCK)
					WHERE groupid <> 0 and growth > 0'  
		INSERT INTO #DBINFO  
		   (DATABASENAME,  
		   FILESIZEMB,  
		   LOGICALFILENAME,
		   DRIVE,  
		   FREESPACEMB,  
		   FREESPACEPCT,
		   MAXSIZE)  

		EXEC sp_MSforeachdb @COMMAND 
		
		INSERT INTO DBA.dbo.DBA_INFO_ALLOCATION(DATE, DATABASENAME, LOGICALFILENAME, FILESIZEMB, FREESPACEMB, NEW_FILESIZE)
		SELECT
			  CONVERT(VARCHAR, GETDATE(), 103) AS DATE,	  
			  DB.DATABASENAME,
			  DB.LOGICALFILENAME,
			  DB.FILESIZEMB, 
			  DB.FREESPACEMB,
			  CASE WHEN ((CEILING(DB.FILESIZEMB * (CASE WHEN DB.FILESIZEMB < 50000 THEN 0.16 ELSE 0.11 END) - DB.FREESPACEMB + DB.FILESIZEMB)) > DB.MAXSIZE) AND (DB.MAXSIZE > 0)
				THEN DB.MAXSIZE 
				ELSE CEILING(DB.FILESIZEMB * (CASE WHEN DB.FILESIZEMB < 50000 THEN 0.16 ELSE 0.11 END) - DB.FREESPACEMB + DB.FILESIZEMB) END AS NEW_FILESIZE
		FROM #DBINFO DB INNER JOIN DBA.dbo.DBA_INFO_FILESYSTEM FL ON DB.DRIVE = FL.DRIVE  and CONVERT(VARCHAR, GETDATE(), 112) = FL.DATE
		WHERE DB.DATABASENAME <> 'model' AND 
			  CONVERT(NUMERIC(9,2), REPLACE(DB.FREESPACEPCT, '%', '')) < 15 AND
			  CEILING(DB.FILESIZEMB * (CASE WHEN DB.FILESIZEMB < 50000 THEN 0.16 ELSE 0.11 END) - DB.FREESPACEMB + DB.FILESIZEMB) > FILESIZEMB AND
			  FL.FREEMB > 2048 AND 
			  ((DB.MAXSIZE > DB.FILESIZEMB) OR (DB.MAXSIZE < 0)) AND
			  ((FL.FREEMB > CEILING(DB.FILESIZEMB * (CASE WHEN DB.FILESIZEMB < 50000 THEN 0.16 ELSE 0.11 END) - DB.FREESPACEMB + DB.FILESIZEMB)- DB.FILESIZEMB) OR ((FL.FREEMB > (DB.MAXSIZE-DB.FILESIZEMB) AND (DB.MAXSIZE > 0))))

		DECLARE @COMANDO VARCHAR(8000)
		DECLARE CR_COMANDOS CURSOR LOCAL FAST_FORWARD
		FOR 
		SELECT  DISTINCT
				  'ALTER database [' + ALOC.DATABASENAME + '] MODIFY FILE(NAME = ''' + ALOC.LOGICALFILENAME + ''' ,      SIZE=' + 	  
				  cast(ALOC.NEW_FILESIZE as varchar(15)) + ' MB);' AS COMANDO		  
			FROM DBA.dbo.DBA_INFO_ALLOCATION ALOC
			INNER JOIN #DBINFO INFO ON ALOC.DATABASENAME = INFO.DATABASENAME
				AND ALOC.LOGICALFILENAME = INFO.LOGICALFILENAME
			WHERE ALOC.DATE 	= CONVERT(VARCHAR, GETDATE(), 103)
				AND ALOC.NEW_FILESIZE > INFO.FILESIZEMB
			ORDER BY  
			   COMANDO
		           

		OPEN CR_COMANDOS

		FETCH NEXT FROM CR_COMANDOS
		INTO @COMANDO

		WHILE @@FETCH_STATUS = 0
		BEGIN 

		  EXEC (@COMANDO)

		  FETCH NEXT FROM CR_COMANDOS
		  INTO @COMANDO
		END

		CLOSE CR_COMANDOS
		DEALLOCATE CR_COMANDOS
	END
	GO

	-------------------------------------------------------------
	---------------------- DISK SPACE ALERT ---------------------
	USE DBA
	GO

	CREATE PROCEDURE usp_disk_space_alert
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	BEGIN
		SET ANSI_WARNINGS OFF
		SET NOCOUNT ON
		DECLARE @DIAS INT,
				@THRESHOLD INT,
				@MARGEM NUMERIC(9,2),
				@CUSTOMER_NAME VARCHAR(100),
				@SERVER_NAME VARCHAR(100)
		
		SELECT @CUSTOMER_NAME = (SELECT PARAM_VALUE FROM DBA_PARAMS WHERE PARAM_NAME = 'CUSTOMER_NAME'), 
			 @SERVER_NAME =   (SELECT PARAM_VALUE FROM DBA_PARAMS WHERE PARAM_NAME = 'SERVER_NAME'),
			 @DIAS =   (SELECT PARAM_VALUE FROM DBA_PARAMS WHERE PARAM_NAME = 'DISK_SPACE_DAYS'),
			 @THRESHOLD =   (SELECT PARAM_VALUE FROM DBA_PARAMS WHERE PARAM_NAME = 'DISK_SPACE_THRESHOLD'),
			 @MARGEM =   (SELECT PARAM_VALUE FROM DBA_PARAMS WHERE PARAM_NAME = 'DISK_SPACE_MARGIN')

		IF OBJECT_ID('_FREESPACE') IS NOT NULL
			DROP TABLE [_FREESPACE]
		
		IF OBJECT_ID('tempdb.dbo.#IDB') IS NOT NULL
			DROP TABLE #IDB
		IF OBJECT_ID('tempdb.dbo.#PRE') IS NOT NULL
			DROP TABLE #PRE

		CREATE TABLE #IDB (
				DATE DATETIME, 
				PHYSICALFILENAME nvarchar (1040), 
				FILESIZEMB numeric (9,2), 
				FREESPACEMB numeric (9,2),
				DIF numeric (9,2)
			)
		
		INSERT INTO #IDB (DATE, PHYSICALFILENAME, FILESIZEMB, FREESPACEMB)
		SELECT DATE, PHYSICALFILENAME, FILESIZEMB, FREESPACEMB
		FROM dbo.DBA_INFO_database
		WHERE DATE >= (CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 112))-@DIAS)

		UPDATE T2
		SET DIF =  T2.FILESIZEMB - T1.FILESIZEMB
		FROM #IDB T1
		LEFT JOIN #IDB T2 ON T1.PHYSICALFILENAME = T2.PHYSICALFILENAME AND T1.DATE = T2.DATE - 1

		SELECT UNIDADE,	AVG (ESPACO) AVG_MB
		INTO #PRE
		FROM (
			SELECT DATE, LEFT (PHYSICALFILENAME, 1) UNIDADE, SUM (DIF /*- FREESPACEMB*/) ESPACO
			FROM #IDB
			GROUP BY LEFT (PHYSICALFILENAME, 1), DATE
		) T
		GROUP BY UNIDADE
		HAVING AVG (ESPACO) > 0

		SELECT	CONVERT (VARCHAR(5), DRIVE) DRIVE,
				CONVERT (VARCHAR(15), FREEMB) FREEMB, 
				CONVERT (VARCHAR(15), FLOOR(FREEMB / (AVG_MB * @MARGEM))) DAYS,
				CONVERT (VARCHAR(15), AVG_MB) AVG_MB
		INTO [_FREESPACE]
		FROM dbo.DBA_INFO_FILESYSTEM FS
		INNER JOIN #PRE GR ON FS.DRIVE = GR.UNIDADE
		WHERE DATE = CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 112))
			AND FLOOR(FREEMB / (AVG_MB * @MARGEM)) < @THRESHOLD
			AND FS.DRIVE NOT IN (SELECT PARAM_VALUE
								 FROM dbo.DBA_PARAMS
								 WHERE PARAM_NAME = 'DISK_SPACE_DAYS_IGNORE')

		IF @@ROWCOUNT > 0
		BEGIN

			DECLARE @sub VARCHAR(100)
			SET @sub = '[mssqldba] DATAFILE GROWTH ALERT - ' + @SERVER_NAME  + '(' + @CUSTOMER_NAME + ')' 

			DECLARE @SQL VARCHAR(MAX)
			SET @SQL = '
			PRINT ''USE THE FOLLOWING PARAMETERS:''
			PRINT ''ANALYSE DAYS: ' + CONVERT(VARCHAR(30), @DIAS) + '''
			PRINT ''THRESHOLD(days): ' + CONVERT(VARCHAR(30), @THRESHOLD) + '''
			PRINT ''MARGIN (%)     : ' + CONVERT(VARCHAR(30), @MARGEM) + '''
			PRINT ''''
			PRINT ''** CHECK THE DRIVES: **''
			SELECT	DRIVE DRIVE,
					FREEMB,
					DIAS [GROWTH DAYS],
					AVG_MB [GROWTH AVERAGE]
			FROM DBA.dbo.[_FREESPACE]
			'
			EXEC msdb.dbo.sp_send_dbmail @recipients = @ALERT_EMAIL,
				@subject = @sub,
				@query = @SQL,
				@attach_query_result_as_file = 0,
				@query_result_width = 200
		END
	END
	GO
	------------------------------------------------------------

	--------------------- TRACK IDENTITY -----------------------
	CREATE PROCEDURE [usp_identity_alert]
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	IF (
	SELECT COUNT(1)
	FROM DBA.dbo.DBA_SNAP_IDENTITY 
	WHERE -- Threshold for Disaster --
		 remaining_value = 0
	) > 0
		PRINT '3 | Identity Monitor'
	ELSE
	IF (
	SELECT COUNT(1)
	FROM DBA.dbo.DBA_SNAP_IDENTITY 
	WHERE -- Threshold for High --
		(typename = 'bigint' AND remaining_value < 2000000000) OR
		(typename = 'int' AND remaining_value < 50000000) OR 
		(typename = 'smallint' AND remaining_value < 5000 ) OR
		(typename = 'tinyint' AND remaining_value < 25 ) 
	) > 0
		PRINT '2 | Identity Monitor'
	ELSE
	IF (
	SELECT COUNT(1)
	FROM DBA.dbo.DBA_SNAP_IDENTITY 
	WHERE -- Threshold for Warning --
		(typename = 'bigint' AND remaining_value < 5000000000) OR
		(typename = 'int' AND remaining_value < 100000000) OR 
		(typename = 'smallint' AND remaining_value < 10000 ) OR
		(typename = 'tinyint' AND remaining_value < 50 ) 
	) > 0
		PRINT '1 | Identity Monitor' -- Warning
	ELSE 
		PRINT '0 | Identity Monitor' -- Normal

	GO


	-------------------------------------------------------------
	------------------------ SERVER REPORT ----------------------
	USE DBA
	GO
	CREATE FUNCTION dbo.udf_convert_int_time_to_datetime (@time_in INT, @date_in int = 0) 
	RETURNS VARCHAR(19) 
	AS 
	BEGIN      
	  DECLARE @time_out VARCHAR(19) 
	  SELECT @time_out = convert(varchar(10), CASE WHEN @date_in = 0 THEN getdate() ELSE CAST(STR(@date_in,8, 0) AS DATETIME) END, 103) + ' ' +
		  CASE LEN(@time_in) 
		  WHEN 6 THEN LEFT(CAST(@time_in AS VARCHAR(6)),2) + ':' + SUBSTRING(CAST(@time_in AS VARCHAR(6)), 3,2) + ':' + RIGHT(CAST(@time_in AS VARCHAR(6)), 2) 
		  WHEN 5 THEN '0' + LEFT(CAST(@time_in AS VARCHAR(6)),1) + ':' + SUBSTRING(CAST(@time_in AS VARCHAR(6)), 2,2) + ':' + RIGHT(CAST(@time_in AS VARCHAR(6)), 2) 
		  WHEN 4 THEN '00' + ':' + LEFT(CAST(@time_in AS VARCHAR(6)),2) + ':' + RIGHT(CAST(@time_in AS VARCHAR(6)), 2) 
		  ELSE '00:00:00' --midnight 
		  END --AS converted_time 
		  
	  RETURN @time_out 
	END
	GO

	CREATE FUNCTION [dbo].[udf_convert_int_time_to_datetime_ANSI] (@time_in INT, @date_in int = 0) 
	RETURNS datetime
	AS 
	BEGIN      
	  DECLARE @time_out datetime, @time_char varchar(12)
	  SET @time_char = RIGHT ('000000' + convert (varchar(10), @time_in), 6)
	  SELECT @time_out = 
		case when @date_in = 0 then convert (varchar(10), getdate(), 112)
		else convert (varchar(10), @date_in) end + ' ' +
		LEFT(@time_char, 2) + ':' + 
		SUBSTRING(@time_char, 3, 2) + ':' + 
		RIGHT(@time_char, 2) --AS converted_time
	  RETURN @time_out 
	END
	GO

	CREATE PROCEDURE [usp_corrupted_page_alert]
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	BEGIN

		SET NOCOUNT ON

		SELECT COALESCE(CONVERT(VARCHAR (10),COUNT(*)),'0')+' | CORRUPTED PAGES' AS [DATE PAGE CORRUPTED] 
		FROM msdb.dbo.suspect_pages 
		WHERE last_update_date BETWEEN GETDATE() - 1 AND GETDATE()

	END
	GO

	CREATE PROCEDURE [usp_dba_broker_alert]
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	BEGIN

		SET NOCOUNT ON

		SELECT 
		CASE
			WHEN is_broker_enabled = 1
				THEN '0 | SERVICE BROKER DBA'
				ELSE '1 | SERVICE BROKER DBA'
			END
		FROM sys.databases WHERE name = 'DBA'

	END
	GO

	CREATE PROCEDURE [usp_dba_jobs_alert]
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	BEGIN
		
		SET NOCOUNT ON
		
		SELECT 
				  CASE 
					WHEN COUNT(*) = 0 THEN '0 | JOB FAILED ' 
						ELSE CONVERT (VARCHAR, COUNT(*)) + ' | JOB FAILED ' 
					END
			FROM(
		SELECT JB.NAME AS JOB, 
						JH.RUN_STATUS AS RUN_STATUS
				 FROM MSDB.DBO.SYSJOBS JB WITH(NOLOCK)
					  INNER JOIN MSDB.DBO.SYSJOBHISTORY JH WITH(NOLOCK)
						 ON JH.JOB_ID = JB.JOB_ID
				INNER JOIN (
						SELECT JB.NAME, 
						max (CONVERT(DATETIME, DBA.dbo.udf_convert_int_time_to_datetime(JH.run_time, JH.RUN_DATE), 103)) LAST_RUN
						 FROM MSDB.DBO.SYSJOBS JB WITH(NOLOCK)
							  INNER JOIN MSDB.DBO.SYSJOBHISTORY JH WITH(NOLOCK)
								 ON JH.JOB_ID = JB.JOB_ID
						 WHERE JB.ENABLED = 1
						   AND JH.STEP_ID = 0	   
						   and JH.run_time is not null
						   and JH.RUN_DATE is not null
						   and JB.name like '%DBA%'
						 GROUP BY JB.NAME) LR ON LR.NAME = JB.NAME AND 
							LR.LAST_RUN = CONVERT(DATETIME, DBA.dbo.udf_convert_int_time_to_datetime(JH.run_time, JH.RUN_DATE), 103)
				 WHERE JB.ENABLED = 1
				   AND JH.STEP_ID = 0	   
				   and JH.run_time is not null
				   and JH.RUN_DATE is not null
				   and JB.name like '%DBA%'
					AND JH.RUN_STATUS <> 1
				 ) AS TBL
		
	END
	GO

	CREATE PROCEDURE [usp_growth_days_alert]
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	BEGIN
		
		DECLARE @DIAS INT,  -- DAYS TO ANALYZE
				@THRESHOLD INT, -- LIMIT OF DAYS TO GROWTH
				@MARGEM NUMERIC(9,2), -- (%) GROTH MARGIN (**FORMAT = 1.2 FOR 20%)
			    @CUSTOMER_NAME VARCHAR(100),
			    @SERVER_NAME VARCHAR(100)
		
	  SELECT @CUSTOMER_NAME = (SELECT PARAM_VALUE FROM DBA_PARAMS WHERE PARAM_NAME = 'CUSTOMER_NAME'), 
			 @SERVER_NAME =   (SELECT PARAM_VALUE FROM DBA_PARAMS WHERE PARAM_NAME = 'SERVER_NAME'),
			 @DIAS = (SELECT PARAM_VALUE FROM DBA_PARAMS WHERE PARAM_NAME = 'DISK_SPACE_DAYS'),
			 @THRESHOLD =  (SELECT PARAM_VALUE FROM DBA_PARAMS WHERE PARAM_NAME = 'DISK_SPACE_THRESHOLD'),
			 @MARGEM =   (SELECT PARAM_VALUE FROM DBA_PARAMS WHERE PARAM_NAME = 'DISK_SPACE_MARGIN')

		IF OBJECT_ID('_FREESPACEMONIT') IS NOT NULL
			DROP TABLE [_FREESPACEMONIT]

	SELECT DRIVE, FREEMB, FLOOR(FREEMB / (CASE WHEN AVG_MB = 0 THEN 0.001 ELSE AVG_MB END  * @MARGEM)) DIAS, AVG_MB
		INTO [_FREESPACEMONIT]
		FROM dbo.DBA_INFO_FILESYSTEM FS
		INNER JOIN (
			SELECT UNIDADE, SUM (PCTG) [PCTG], SUM (CRESCIMENTO) / @DIAS AVG_MB
			FROM (
				SELECT	D1.DATE, D1.UNIDADE, D1.ESPACO SPC1, D2.ESPACO SPC2, 
						((D1.ESPACO - D2.ESPACO) * 100) / D2.ESPACO PCTG,
						D1.ESPACO - D2.ESPACO CRESCIMENTO
				FROM (
					SELECT DATE, LEFT (PHYSICALFILENAME, 1) UNIDADE, SUM (FILESIZEMB /*- FREESPACEMB*/) ESPACO
					FROM dbo.DBA_INFO_database
					WHERE DATE >= (CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 112))-@DIAS)
					GROUP BY LEFT (PHYSICALFILENAME, 1), DATE
				) D1
				INNER JOIN (
					SELECT DATE, LEFT (PHYSICALFILENAME, 1) UNIDADE, SUM (FILESIZEMB /*- FREESPACEMB*/) ESPACO
					FROM dbo.DBA_INFO_database
					WHERE DATE >= (CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 112))-(@DIAS+1))
					GROUP BY LEFT (PHYSICALFILENAME, 1), DATE
				) D2 ON D1.DATE = D2.DATE + 1 AND D1.UNIDADE = D2.UNIDADE
			) TBL
			GROUP BY UNIDADE
		) GR ON FS.DRIVE = GR.UNIDADE
		WHERE DATE = CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 112))

	CREATE TABLE ##temptb ([drive] VARCHAR(10),[MB Free] BIGINT)

	INSERT INTO ##temptb ([drive],[MB free])
	 EXEC master.dbo.xp_fixeddrives

		SET NOCOUNT ON
		
		 SELECT CONVERT(VARCHAR(20),[dias])+' | GROWTH DAYS ('+[drive]+')'
		 FROM DBA.dbo.[_FREESPACEMONIT]
		 
	 DROP TABLE ##temptb

	END
	GO
	-------------------------------------------------------------
	---------------------- CRITICAL JOBS ------------------------

	CREATE PROCEDURE [usp_critical_jobs_alert]
	-- START ENCRYPTION
	WITH ENCRYPTION
	-- END ENCRYPTION
	AS
	SET NOCOUNT ON
	DECLARE @Result INT = 0,
			@DESC VARCHAR (MAX)

	-- #FAILURES_TOLERANCE
	SELECT @Result = @Result + ISNULL (COUNT(*), 0)
	FROM msdb.dbo.sysjobs JOBS
	INNER JOIN DBA.dbo.DBA_MONITOR_CRITICAL_JOBS CJ ON JOBS.name = CJ.JOB_NAME
	INNER JOIN msdb.dbo.sysjobhistory c ON JOBS.job_id = c.job_id
	WHERE c.step_id = 0 
	AND DBA.dbo.udf_convert_int_time_to_datetime_ANSI (run_time, run_date) >
	-- Last success execution
	(	SELECT ISNULL (MAX (DBA.dbo.udf_convert_int_time_to_datetime_ANSI (run_time, run_date)), '1900-01-01')
		FROM msdb.dbo.sysjobs a
		JOIN DBA.dbo.DBA_MONITOR_CRITICAL_JOBS b ON a.name = b.JOB_NAME
		JOIN msdb.dbo.sysjobhistory c ON a.job_id = c.job_id
		WHERE c.step_id = 0 AND run_status = 1 AND a.name = CJ.JOB_NAME
	)
	AND CJ.FAILURES_TOLERANCE <> -1 AND CJ.IGNORE_UNTIL <= GETDATE() AND CJ.ACTIVE = 1
	AND run_status = 0 -- Failed execution
	GROUP BY cj.JOB_NAME
	-- Number of failures
	HAVING COUNT(*) >= (
		SELECT FAILURES_TOLERANCE 
		FROM DBA.dbo.DBA_MONITOR_CRITICAL_JOBS a
		WHERE a.JOB_NAME = CJ.JOB_NAME
	)
	IF @@ROWCOUNT > 0
	BEGIN
		INSERT INTO [dbo].[DBA_MONITOR_CRITICAL_JOBS_ERROR_LOG] (DATE, JOB_NAME, MSG)
		SELECT GETDATE(), CJ.JOB_NAME, 
			'ERROR TYPE: FAILURES_TOLERANCE' +
			' | THRESHOLD: ' + CONVERT (VARCHAR(10), CJ.FAILURES_TOLERANCE) + 
			' | CURRENT: ' + CONVERT (VARCHAR(10), COUNT(*))
		FROM msdb.dbo.sysjobs JOBS
		INNER JOIN DBA.dbo.DBA_MONITOR_CRITICAL_JOBS CJ ON JOBS.name = CJ.JOB_NAME
		INNER JOIN msdb.dbo.sysjobhistory c ON JOBS.job_id = c.job_id
		WHERE c.step_id = 0 
		AND DBA.dbo.udf_convert_int_time_to_datetime_ANSI (run_time, run_date) >
		-- Last success execution
		(	SELECT ISNULL (MAX (DBA.dbo.udf_convert_int_time_to_datetime_ANSI (run_time, run_date)), '1900-01-01')
			FROM msdb.dbo.sysjobs a
			JOIN DBA.dbo.DBA_MONITOR_CRITICAL_JOBS b ON a.name = b.JOB_NAME
			JOIN msdb.dbo.sysjobhistory c ON a.job_id = c.job_id
			WHERE c.step_id = 0 AND run_status = 1 AND a.name = CJ.JOB_NAME
		)
		AND CJ.FAILURES_TOLERANCE <> -1 AND CJ.IGNORE_UNTIL <= GETDATE() AND CJ.ACTIVE = 1
		AND run_status = 0 -- Failed execution
		GROUP BY cj.JOB_NAME, CJ.FAILURES_TOLERANCE
		-- Number of failures
		HAVING COUNT(*) >= (
			SELECT FAILURES_TOLERANCE 
			FROM DBA.dbo.DBA_MONITOR_CRITICAL_JOBS a
			WHERE a.JOB_NAME = CJ.JOB_NAME
		)
	END

	-- #RUNNING_MIN_TOLERANCE
	SELECT @Result = @Result + ISNULL (COUNT(*), 0)
		--JOBS.NAME, convert (varchar(10), CASE WHEN A.stop_execution_date IS NOT NULL THEN 0
		--ELSE DATEDIFF (MINUTE, A.start_execution_date, GETDATE())
		--END) [A]
	FROM msdb.dbo.sysjobactivity A
	JOIN msdb.dbo.sysjobs JOBS ON A.job_id = JOBS.job_id
	JOIN DBA.dbo.DBA_MONITOR_CRITICAL_JOBS CJ ON JOBS.name = CJ.JOB_NAME
	WHERE A.start_execution_date = (
			SELECT MAX(A.start_execution_date)
			FROM msdb.dbo.sysjobactivity A
			JOIN msdb.dbo.sysjobs B ON A.job_id = B.job_id
			WHERE B.name = JOBS.name
		)
		AND CJ.RUNNING_MIN_TOLERANCE <> -1 AND CJ.IGNORE_UNTIL <= GETDATE() AND CJ.ACTIVE = 1
		AND (CASE WHEN A.stop_execution_date IS NOT NULL THEN 0
		ELSE DATEDIFF (MINUTE, A.start_execution_date, GETDATE())
		END) > CJ.RUNNING_MIN_TOLERANCE
	IF @@ROWCOUNT > 0
	BEGIN
		INSERT INTO [dbo].[DBA_MONITOR_CRITICAL_JOBS_ERROR_LOG] (DATE, JOB_NAME, MSG)
		SELECT GETDATE(), CJ.JOB_NAME, 
			'ERROR TYPE: RUNNING_MIN_TOLERANCE' +
			' | THRESHOLD: ' + CONVERT (VARCHAR(10), CJ.RUNNING_MIN_TOLERANCE) + 
			' | CURRENT: ' + CONVERT (VARCHAR(10), CASE WHEN A.stop_execution_date IS NOT NULL THEN 0
													ELSE DATEDIFF (MINUTE, A.start_execution_date, GETDATE())END)
		FROM msdb.dbo.sysjobactivity A
		JOIN msdb.dbo.sysjobs JOBS ON A.job_id = JOBS.job_id
		JOIN DBA.dbo.DBA_MONITOR_CRITICAL_JOBS CJ ON JOBS.name = CJ.JOB_NAME
		WHERE A.start_execution_date = (
				SELECT MAX(A.start_execution_date)
				FROM msdb.dbo.sysjobactivity A
				JOIN msdb.dbo.sysjobs B ON A.job_id = B.job_id
				WHERE B.name = JOBS.name
			)
			AND CJ.RUNNING_MIN_TOLERANCE <> -1 AND CJ.IGNORE_UNTIL <= GETDATE() AND CJ.ACTIVE = 1
			AND (CASE WHEN A.stop_execution_date IS NOT NULL THEN 0
			ELSE DATEDIFF (MINUTE, A.start_execution_date, GETDATE())
			END) > CJ.RUNNING_MIN_TOLERANCE
	END

	-- #INACTIVE_MIN_TOLERANCE

	SELECT @Result = @Result + ISNULL (COUNT(*), 0)
		--JOBS.NAME, convert (varchar(10), DATEDIFF (MINUTE, A.stop_execution_date, GETDATE())) [A]
	FROM msdb.dbo.sysjobactivity A
	JOIN msdb.dbo.sysjobs JOBS ON A.job_id = JOBS.job_id
	JOIN DBA.dbo.DBA_MONITOR_CRITICAL_JOBS CJ ON JOBS.name = CJ.JOB_NAME
	WHERE A.stop_execution_date = (
			SELECT MAX(A.stop_execution_date)
			FROM msdb.dbo.sysjobactivity A
			JOIN msdb.dbo.sysjobs B ON A.job_id = B.job_id
			WHERE B.name = JOBS.name
		)
		AND CJ.INACTIVE_MIN_TOLERANCE <> -1 AND CJ.IGNORE_UNTIL <= GETDATE() AND CJ.ACTIVE = 1
		AND (DATEDIFF (MINUTE, A.stop_execution_date, GETDATE())) > CJ.INACTIVE_MIN_TOLERANCE
	IF @@ROWCOUNT > 0
	BEGIN
		INSERT INTO [dbo].[DBA_MONITOR_CRITICAL_JOBS_ERROR_LOG] (DATE, JOB_NAME, MSG)
		SELECT GETDATE(), CJ.JOB_NAME, 
			'ERROR TYPE: INACTIVE_MIN_TOLERANCE' + 
			' | THRESHOLD: ' + CONVERT (VARCHAR(10), CJ.INACTIVE_MIN_TOLERANCE) + 
			' | CURRENT: ' + CONVERT (VARCHAR(10), DATEDIFF (MINUTE, A.stop_execution_date, GETDATE()))
		FROM msdb.dbo.sysjobactivity A
		JOIN msdb.dbo.sysjobs JOBS ON A.job_id = JOBS.job_id
		JOIN DBA.dbo.DBA_MONITOR_CRITICAL_JOBS CJ ON JOBS.name = CJ.JOB_NAME
		WHERE A.stop_execution_date = (
				SELECT MAX(A.stop_execution_date)
				FROM msdb.dbo.sysjobactivity A
				JOIN msdb.dbo.sysjobs B ON A.job_id = B.job_id
				WHERE B.name = JOBS.name
			)
			AND CJ.INACTIVE_MIN_TOLERANCE <> -1 AND CJ.IGNORE_UNTIL <= GETDATE() AND CJ.ACTIVE = 1
			AND (DATEDIFF (MINUTE, A.stop_execution_date, GETDATE())) > CJ.INACTIVE_MIN_TOLERANCE
	END

	-- #DAILY_EXECUTION_TIME_LIMIT

	SELECT @Result = @Result + ISNULL (COUNT(*), 0)
		--CJ.JOB_NAME, CJ.DAILY_EXECUTION_TIME_LIMIT
	FROM DBA.dbo.DBA_MONITOR_CRITICAL_JOBS CJ
	WHERE CJ.DAILY_EXECUTION_TIME_LIMIT <> '-1' AND CJ.IGNORE_UNTIL <= GETDATE() AND CJ.ACTIVE = 1
		AND CONVERT (DATETIME, CONVERT (VARCHAR(8), GETDATE(), 112) + ' ' + CJ.DAILY_EXECUTION_TIME_LIMIT) < GETDATE()
		AND NOT EXISTS (
			SELECT JOBS.NAME, MIN (DBA.dbo.udf_convert_int_time_to_datetime_ANSI (run_time, run_date)) [A]
			FROM msdb.dbo.sysjobs JOBS
			join msdb.dbo.sysjobhistory JH ON JH.job_id = JOBS.job_id
			WHERE DBA.dbo.udf_convert_int_time_to_datetime_ANSI (run_time, run_date) BETWEEN CONVERT (VARCHAR(8), GETDATE(), 112) AND
				CONVERT (DATETIME, CONVERT (VARCHAR(8), GETDATE(), 112) + ' ' + CJ.DAILY_EXECUTION_TIME_LIMIT)
				AND JOBS.name = CJ.JOB_NAME
			GROUP BY JOBS.NAME
		)
	IF @@ROWCOUNT > 0
	BEGIN
		INSERT INTO [dbo].[DBA_MONITOR_CRITICAL_JOBS_ERROR_LOG] (DATE, JOB_NAME, MSG)
		SELECT GETDATE(), CJ.JOB_NAME, 
			'ERROR TYPE: DAILY_EXECUTION_TIME_LIMIT' +
			' | THRESHOLD: ' + CONVERT (VARCHAR(10), CJ.DAILY_EXECUTION_TIME_LIMIT)
		FROM DBA.dbo.DBA_MONITOR_CRITICAL_JOBS CJ
		WHERE CJ.DAILY_EXECUTION_TIME_LIMIT <> '-1' AND CJ.IGNORE_UNTIL <= GETDATE() AND CJ.ACTIVE = 1
			AND CONVERT (DATETIME, CONVERT (VARCHAR(8), GETDATE(), 112) + ' ' + CJ.DAILY_EXECUTION_TIME_LIMIT) < GETDATE()
			AND NOT EXISTS (
				SELECT JOBS.NAME, MIN (DBA.dbo.udf_convert_int_time_to_datetime_ANSI (run_time, run_date)) [A]
				FROM msdb.dbo.sysjobs JOBS
				join msdb.dbo.sysjobhistory JH ON JH.job_id = JOBS.job_id
				WHERE DBA.dbo.udf_convert_int_time_to_datetime_ANSI (run_time, run_date) BETWEEN CONVERT (VARCHAR(8), GETDATE(), 112) AND
					CONVERT (DATETIME, CONVERT (VARCHAR(8), GETDATE(), 112) + ' ' + CJ.DAILY_EXECUTION_TIME_LIMIT)
					AND JOBS.name = CJ.JOB_NAME
				GROUP BY JOBS.NAME
			)
	END

	-- #JOB_EXISTENCE

	SELECT @Result = @Result + ISNULL (COUNT(*), 0)
		--CJ.JOB_NAME
	FROM DBA.dbo.DBA_MONITOR_CRITICAL_JOBS CJ
	LEFT JOIN msdb.dbo.sysjobs JOBS ON CJ.JOB_NAME = JOBS.name AND JOBS.enabled = 1
	WHERE JOBS.name IS NULL 
		AND CJ.DAILY_EXECUTION_TIME_LIMIT <> '-1' AND CJ.IGNORE_UNTIL <= GETDATE() AND CJ.ACTIVE = 1
	IF @@ROWCOUNT > 0
	BEGIN
		INSERT INTO [dbo].[DBA_MONITOR_CRITICAL_JOBS_ERROR_LOG] (DATE, JOB_NAME, MSG)
		SELECT GETDATE(), CJ.JOB_NAME, 
			'ERROR TYPE: JOB_EXISTENCE' +
			' | JOB DOESN''T EXISTS OR WRONG NAME OR DISABLED'
		FROM DBA.dbo.DBA_MONITOR_CRITICAL_JOBS CJ
		LEFT JOIN msdb.dbo.sysjobs JOBS ON CJ.JOB_NAME = JOBS.name and JOBS.enabled = 1
		WHERE JOBS.name IS NULL
			AND CJ.IGNORE_UNTIL <= GETDATE() AND CJ.ACTIVE = 1
	END

	SELECT CASE WHEN @Result IS NULL OR @Result = 0 THEN '0 | CRITICAL JOBS' ELSE '1 | CRITICAL JOBS' END

	GO

	----------------------------------- DBA operator ---------------------------------
	USE [msdb]
	GO

	IF EXISTS (SELECT 1 FROM dbo.sysoperators WHERE name = 'DBA')
		EXEC dbo.sp_delete_operator 'DBA'

	EXEC msdb.dbo.sp_add_operator @name=N'DBA', 
			@enabled=1, 
			@pager_days=0, 
			@email_address=@ALERT_EMAIL
	GO
	----------------------------------------------------------------------------------

	-------------------------------- JOBS ------------------------------------------
	USE [msdb]
	GO
	/****** Object:  Job [DBA maintenance_plan_indexes]    Script Date: 03/29/2010 17:57:32 ******/
	BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0
	/****** Object:  JobCategory [DBA Generic]    Script Date: 03/29/2010 17:57:32 ******/
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'DBA Generic' AND category_class=1)
	BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'DBA Generic'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	END

	IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA maintenance_plan_indexes')
		EXEC dbo.sp_delete_job @job_name = 'DBA maintenance_plan_indexes'

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA maintenance_plan_indexes', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=2, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'
	', 
			@category_name=N'DBA Generic', 
			@owner_login_name=N'sa', 
			@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	/****** Object:  Step [Maintenance_plan_indexes]    Script Date: 03/29/2010 17:57:33 ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Maintenance_plan_indexes', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_success_step_id=0, 
			@on_fail_action=2, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'USE DBA
	GO

	EXECUTE usp_Maintenance_plan_indexes', 
			@database_name=N'master', 
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'MONDAY_02_00_AM', 
			@enabled=1, 
			@freq_type=8, 
			@freq_interval=3, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20100329, 
			@active_end_date=99991231, 
			@active_start_time=20000, 
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
	USE [msdb]
	GO
	/****** Object:  Job [DBA maintenance_plan_statistics]    Script Date: 03/29/2010 17:57:39 ******/
	BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0
	/****** Object:  JobCategory [DBA Generic]    Script Date: 03/29/2010 17:57:39 ******/
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'DBA Generic' AND category_class=1)
	BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'DBA Generic'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	END

	IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA maintenance_plan_statistics')
		EXEC dbo.sp_delete_job @job_name = 'DBA maintenance_plan_statistics'

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA maintenance_plan_statistics', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=2, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'No description available.', 
			@category_name=N'DBA Generic', 
			@owner_login_name=N'sa', 
			@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	/****** Object:  Step [Maintenance_plan_statistics]    Script Date: 03/29/2010 17:57:39 ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Maintenance_plan_statistics', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_success_step_id=0, 
			@on_fail_action=2, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'use DBA
	go

	EXECUTE usp_Maintenance_plan_statistics
	GO', 
			@database_name=N'master', 
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'EVERY_DAY_02_00_AM', 
			@enabled=1, 
			@freq_type=8, 
			@freq_interval=125, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20100329, 
			@active_end_date=99991231, 
			@active_start_time=23000, 
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
	USE [msdb]
	GO
	/****** Object:  Job [DBA maintenance_plan_checkintegrity]    Script Date: 03/29/2010 17:57:43 ******/
	BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0
	/****** Object:  JobCategory [DBA Generic]    Script Date: 03/29/2010 17:57:43 ******/
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'DBA Generic' AND category_class=1)
	BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'DBA Generic'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	END

	IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA maintenance_plan_checkintegrity')
		EXEC dbo.sp_delete_job @job_name = 'DBA maintenance_plan_checkintegrity'

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA maintenance_plan_checkintegrity', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=2, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'No description available.', 
			@category_name=N'DBA Generic', 
			@owner_login_name=N'sa', 
			@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	/****** Object:  Step [Maintenance_plan_checkintegrity]    Script Date: 03/29/2010 17:57:43 ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Maintenance_plan_checkintegrity', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_success_step_id=0, 
			@on_fail_action=2, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'USE DBA
	GO
	EXECUTE usp_Maintenance_plan_checkintegrity
	GO', 
			@database_name=N'master', 
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'MONDAY_03_00_AM', 
			@enabled=1, 
			@freq_type=8, 
			@freq_interval=2, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20100329, 
			@active_end_date=99991231, 
			@active_start_time=30000, 
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

	USE [msdb]
	GO

	/****** Object:  Job [DBA track_data_growth_stats]    Script Date: 02/05/2014 1:56:39 PM ******/
	BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0
	/****** Object:  JobCategory [DBA Generic]    Script Date: 02/05/2014 1:56:40 PM ******/
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'DBA Generic' AND category_class=1)
	BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'DBA Generic'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	END

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA track_data_growth_stats', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=2, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'No description available.', 
			@category_name=N'DBA Generic', 
			@owner_login_name=N'sa', 
			@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	/****** Object:  Step [track_data_growth_stats]    Script Date: 02/05/2014 1:56:44 PM ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'track_data_growth_stats', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_success_step_id=0, 
			@on_fail_action=2, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'USE DBA

	GO

	EXECUTE usp_track_data_growth_stats

	GO', 
			@database_name=N'master', 
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'EVERY_DAY', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=0, 
			@active_start_date=20100329, 
			@active_end_date=99991231, 
			@active_start_time=50500, 
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

	USE [msdb]
	GO
	/****** Object:  Job [DBA purge_data_growth_stats]    Script Date: 03/29/2010 17:57:53 ******/
	BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0
	/****** Object:  JobCategory [DBA Generic]    Script Date: 03/29/2010 17:57:53 ******/
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'DBA Generic' AND category_class=1)
	BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'DBA Generic'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	END

	IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA purge_data_growth_stats')
		EXEC dbo.sp_delete_job @job_name = 'DBA purge_data_growth_stats'

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA purge_data_growth_stats', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=2, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'No description available.', 
			@category_name=N'DBA Generic', 
			@owner_login_name=N'sa', 
			@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	/****** Object:  Step [purge_data_growth_stats]    Script Date: 03/29/2010 17:57:54 ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'purge_data_growth_stats', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_success_step_id=0, 
			@on_fail_action=2, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'USE DBA
	GO

	EXECUTE usp_purge_data_growth_stats
	GO', 
			@database_name=N'master', 
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'EVERY_DAY_05_15_AM', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=0, 
			@active_start_date=20100329, 
			@active_end_date=99991231, 
			@active_start_time=51500, 
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


	USE [msdb]
	GO
	/****** Object:  Job [DBA track_snapshot]    Script Date: 03/29/2010 17:58:01 ******/
	BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0
	/****** Object:  JobCategory [DBA Generic]    Script Date: 03/29/2010 17:58:01 ******/
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'DBA Generic' AND category_class=1)
	BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'DBA Generic'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	END

	IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA track_snapshot')
		EXEC dbo.sp_delete_job @job_name = 'DBA track_snapshot'

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA track_snapshot', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=2, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'No description available.', 
			@category_name=N'DBA Generic', 
			@owner_login_name=N'sa', 
			@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	/****** Object:  Step [track_snapshot]    Script Date: 03/29/2010 17:58:02 ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'track_snapshot', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_success_step_id=0, 
			@on_fail_action=2, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'USE DBA
	GO

	EXECUTE usp_track_snapshot
	GO
	', 
			@database_name=N'master', 
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'EVERY_DAY_FOR_EACH_5_MINUTES', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=4, 
			@freq_subday_interval=5, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=0, 
			@active_start_date=20100329, 
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

	USE [msdb]
	GO
	/****** Object:  Job [DBA purge_snapshot]    Script Date: 03/29/2010 17:58:05 ******/
	BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0
	/****** Object:  JobCategory [Full-Text]    Script Date: 03/29/2010 17:58:05 ******/
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Full-Text' AND category_class=1)
	BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Full-Text'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	END

	IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA purge_snapshot')
		EXEC dbo.sp_delete_job @job_name = 'DBA purge_snapshot'

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA purge_snapshot', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=2, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'No description available.', 
			@category_name=N'Full-Text', 
			@owner_login_name=N'sa', 
			@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	/****** Object:  Step [purge_snapshot]    Script Date: 03/29/2010 17:58:05 ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'purge_snapshot', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_success_step_id=0, 
			@on_fail_action=2, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'USE DBA
	GO

	EXECUTE usp_purge_snapshot', 
			@database_name=N'master', 
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'EVERY_DAY_05_30_AM', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=0, 
			@active_start_date=20100329, 
			@active_end_date=99991231, 
			@active_start_time=53000, 
			@active_end_time=235959
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	COMMIT TRANSACTION
	GOTO EndSave
	QuitWithRollback:
	    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
	EndSave:
	Go

	USE [msdb]
	GO
	/****** Object:  Job [DBA space_allocation_for_files]    Script Date: 03/29/2010 17:58:09 ******/
	BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0
	/****** Object:  JobCategory [DBA Generic]    Script Date: 03/29/2010 17:58:09 ******/
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'DBA Generic' AND category_class=1)
	BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'DBA Generic'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	END

	IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA space_allocation_for_files')
		EXEC dbo.sp_delete_job @job_name = 'DBA space_allocation_for_files'

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA space_allocation_for_files', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=2, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'No description available.', 
			@category_name=N'DBA Generic', 
			@owner_login_name=N'sa', 
			@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	/****** Object:  Step [space_allocation_for_files]    Script Date: 03/29/2010 17:58:10 ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'space_allocation_for_files', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_success_step_id=0, 
			@on_fail_action=2, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'USE DBA
	GO

	EXECUTE usp_space_allocation_for_files

	', 
			@database_name=N'master', 
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'EVERY_DAY_05_45_AM', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=0, 
			@active_start_date=20100329, 
			@active_end_date=99991231, 
			@active_start_time=54500, 
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

	USE [msdb]
	GO
	/****** Object:  Job [DBA monitor_every_5_minutes]    Script Date: 03/29/2010 17:58:09 ******/
	IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA monitor_every_5_minutes')
		EXEC dbo.sp_delete_job @job_name = 'DBA monitor_every_5_minutes'

	DECLARE @jobId BINARY(16)
	EXEC  msdb.dbo.sp_add_job @job_name=N'DBA monitor_every_5_minutes', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=2, 
			@notify_level_netsend=2, 
			@notify_level_page=2, 
			@delete_level=0, 
			@description=N'DBA monitor_every_5_minutes', 
			@category_name=N'DBA Generic', 
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	EXEC msdb.dbo.sp_add_jobserver @job_name=N'DBA monitor_every_5_minutes', @server_name = @@SERVERNAME
	EXEC msdb.dbo.sp_add_jobstep @job_name=N'DBA monitor_every_5_minutes', @step_name=N'DBA Jobs', 
			@step_id=2, 
			@cmdexec_success_code=0, 
			@on_success_action=3, 
			@on_fail_action=2, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'USE [DBA]
	GO
	DECLARE @cmd VARCHAR(1000), @server VARCHAR(100)
	SET @server = @@SERVERNAME
	SET @cmd = ''SQLCMD -S "'' + @server + ''" -h -1 -Q "EXEC DBA.dbo.usp_dba_jobs_alert" > '+@DIR_ZABBIX+'\SQL_DBAJobs.txt''
	EXEC master..xp_cmdshell @cmd
	GO', 
			@database_name=N'DBA', 
			@flags=0
	EXEC msdb.dbo.sp_add_jobstep @job_name=N'DBA monitor_every_5_minutes', @step_name=N'Critical Jobs', 
			@step_id=3, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_fail_action=2, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'USE [DBA]
	GO

	DECLARE @cmd VARCHAR(1000), @server VARCHAR(100)
	SET @server = @@SERVERNAME
	SET @cmd = ''SQLCMD -S "'' + @server + ''" -h -1 -Q "EXEC DBA.dbo.usp_critical_jobs_alert" > '+@DIR_ZABBIX+'\SQL_CriticalJobs.txt''
	EXEC master..xp_cmdshell @cmd
	GO', 
			@database_name=N'DBA', 
			@flags=0
	EXEC msdb.dbo.sp_update_job @job_name=N'DBA monitor_every_5_minutes', 
			@enabled=1, 
			@start_step_id=1
	DECLARE @schedule_id int
	EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DBA monitor_every_5_minutes', @name=N'Every 5 Minutes', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=4, 
			@freq_subday_interval=5, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20140116, 
			@active_end_date=99991231, 
			@active_start_time=0, 
			@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
	GO

	USE [msdb]
	GO
	/****** Object:  Job [DBA monitor_every_day]    Script Date: 03/29/2010 17:58:09 ******/
	IF EXISTS (SELECT 1 FROM dbo.sysjobs WHERE name = 'DBA monitor_every_day')
		EXEC dbo.sp_delete_job @job_name = 'DBA monitor_every_day'

	DECLARE @jobId BINARY(16)
	EXEC  msdb.dbo.sp_add_job @job_name=N'DBA monitor_every_day', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=2, 
			@notify_level_netsend=2, 
			@notify_level_page=2, 
			@delete_level=0, 
			@description=N'DBA monitor_daily', 
			@category_name=N'DBA Generic', 
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	EXEC msdb.dbo.sp_add_jobserver @job_name=N'DBA monitor_every_day', @server_name = @@SERVERNAME
	EXEC msdb.dbo.sp_add_jobstep @job_name=N'DBA monitor_every_day', @step_name=N'Deadlocks', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=3, 
			@on_fail_action=2, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'USE [DBA]
	GO

	DECLARE @cmd VARCHAR(1000), @server VARCHAR(100)
	SET @server = @@SERVERNAME
	SET @cmd = ''SQLCMD -S "'' + @server + ''" -h -1 -Q "EXEC DBA.dbo.usp_deadlocks_alert " > '+@DIR_ZABBIX+'\SQL_Deadlocks.txt''
	EXEC master..xp_cmdshell @cmd
	GO', 
			@database_name=N'DBA', 
			@flags=0
	EXEC msdb.dbo.sp_add_jobstep @job_name=N'DBA monitor_every_day', @step_name=N'Logins', 
			@step_id=2, 
			@cmdexec_success_code=0, 
			@on_success_action=3, 
			@on_fail_action=2, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'USE [DBA]
	GO

	DECLARE @cmd VARCHAR(1000), @server VARCHAR(100)
	SET @server = @@SERVERNAME
	SET @cmd = ''SQLCMD -S "'' + @server + ''" -h -1 -Q "EXEC DBA.dbo.usp_login_failed_alert " > '+@DIR_ZABBIX+'\SQL_LoginFailed.txt''
	EXEC master..xp_cmdshell @cmd
	GO', 
			@database_name=N'DBA', 
			@flags=0
	EXEC msdb.dbo.sp_add_jobstep @job_name=N'DBA monitor_every_day', @step_name=N'Corrupted Pages', 
			@step_id=3, 
			@cmdexec_success_code=0, 
			@on_success_action=3, 
			@on_fail_action=2, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'USE [DBA]
	GO

	DECLARE @cmd VARCHAR(1000), @server VARCHAR(100)
	SET @server = @@SERVERNAME
	SET @cmd = ''SQLCMD -S "'' + @server + ''" -h -1 -Q "EXEC DBA.dbo.usp_corrupted_page_alert " > '+@DIR_ZABBIX+'\SQL_CorruptedPage.txt''
	EXEC master..xp_cmdshell @cmd
	GO', 
			@database_name=N'DBA', 
			@flags=0
	EXEC msdb.dbo.sp_add_jobstep @job_name=N'DBA monitor_every_day', @step_name=N'Backups', 
			@step_id=4, 
			@cmdexec_success_code=0, 
			@on_success_action=3, 
			@on_fail_action=2, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'USE [DBA]
	GO

	DECLARE @cmd VARCHAR(1000), @server VARCHAR(100)
	SET @server = @@SERVERNAME
	SET @cmd = ''SQLCMD -S "'' + @server + ''" -h -1 -Q "EXEC DBA.dbo.usp_backup_alert " > '+@DIR_ZABBIX+'\SQL_Backup.txt''
	EXEC master..xp_cmdshell @cmd
	GO', 
			@database_name=N'DBA', 
			@flags=0
	EXEC msdb.dbo.sp_add_jobstep @job_name=N'DBA monitor_every_day', @step_name=N'DBA Service Broker', 
			@step_id=5, 
			@cmdexec_success_code=0, 
			@on_success_action=3, 
			@on_fail_action=2, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'USE [DBA]
	GO

	DECLARE @cmd VARCHAR(1000), @server VARCHAR(100)
	SET @server = @@SERVERNAME
	SET @cmd = ''SQLCMD -S "'' + @server + ''" -h -1 -Q "EXEC DBA.dbo.usp_dba_broker_alert " > '+@DIR_ZABBIX+'\SQL_DbaBroker.txt''
	EXEC master..xp_cmdshell @cmd
	GO', 
			@database_name=N'DBA', 
			@flags=0
	EXEC msdb.dbo.sp_add_jobstep @job_name=N'DBA monitor_every_day', @step_name=N'Growth Days', 
			@step_id=6, 
			@cmdexec_success_code=0, 
			@on_success_action=3, 
			@on_fail_action=2, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'USE [DBA]
	GO

	DECLARE @cmd VARCHAR(1000), @server VARCHAR(100)
	SET @server = @@SERVERNAME
	SET @cmd = ''SQLCMD -S "'' + @server + ''" -h -1 -Q "EXEC DBA.dbo.usp_growth_days_alert " > '+@DIR_ZABBIX+'\SQL_GrowthDays.txt''
	EXEC master..xp_cmdshell @cmd
	GO', 
			@database_name=N'DBA', 
			@flags=0
	EXEC msdb.dbo.sp_add_jobstep @job_name=N'DBA monitor_every_day', @step_name=N'Identity', 
			@step_id=7, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_fail_action=2, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'USE [DBA]
	GO

	DECLARE @cmd VARCHAR(1000), @server VARCHAR(100)
	SET @server = @@SERVERNAME
	SET @cmd = ''SQLCMD -S "'' + @server + ''" -h -1 -Q "EXEC DBA.dbo.usp_identity_alert" > '+@DIR_ZABBIX+'\SQL_IdentityMonitor.txt''
	EXEC master..xp_cmdshell @cmd
	GO', 
			@database_name=N'DBA', 
			@flags=0
	EXEC msdb.dbo.sp_update_job @job_name=N'DBA monitor_every_day', 
			@enabled=1, 
			@start_step_id=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=2, 
			@notify_level_netsend=2, 
			@notify_level_page=2, 
			@delete_level=0, 
			@description=N'DBA monitor_every_day', 
			@category_name=N'DBA Generic', 
			@owner_login_name=N'sa', 
			@notify_email_operator_name=N'', 
			@notify_netsend_operator_name=N'', 
			@notify_page_operator_name=N''
	DECLARE @schedule_id int
	EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DBA monitor_every_day', @name=N'Every Day', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20140116, 
			@active_end_date=99991231, 
			@active_start_time=80000, 
			@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
	GO

	----------------------------------------------------------------------------------

	EXEC sp_configure 'show advanced options', 1
	RECONFIGURE WITH OVERRIDE
	GO
	EXEC sp_configure 'xp_cmdshell', 1
	RECONFIGURE WITH OVERRIDE
	GO
	exec sp_configure 'scan for startup procs', '1'
	GO
	RECONFIGURE WITH OVERRIDE
	GO

	EXEC xp_cmdshell 'mkdir '+@DIR_ZABBIX+'
	icacls '+@DIR_ZABBIX+' /grant:r todos:(OI)(CI)M'
	GO

	EXEC xp_cmdshell 'mkdir '+@DIR_ZABBIX+'
	icacls '+@DIR_ZABBIX+' /grant:r todos:(OI)(CI)M'
	GO
END
ELSE
	PRINT 'Error on creating the database!'