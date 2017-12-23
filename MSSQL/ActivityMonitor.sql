/* 

Acitvity monitor.
This script will check:
	1 - Locks on the instance
	2 - Querys running
	3 - Backup/Restore time left
	4 - Sessions opened by Database

------------------------ CHANGE LOG ------------------------
2017-12-23 - Thiago Reque
  - Adjustments for add in Github
*/

USE [master]
GO


SELECT t1.resource_type AS 'lock type',db_name(resource_database_id) AS 'database',
	t1.resource_associated_entity_id AS 'blk object',t1.request_mode AS 'lock req',                                                                          --- lock requested
	t1.request_session_id AS 'waiter sid', t2.wait_duration_ms AS 'wait time',             -- spid of waiter  
	(SELECT [text] FROM sys.dm_exec_requests AS r                                           -- get sql for waiter
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
	(SELECT [text] FROM sys.sysprocesses AS p                        -- get sql for blocker
	CROSS APPLY sys.dm_exec_sql_text(p.sql_handle) 
	WHERE p.spid = t2.blocking_session_id) AS 'blocker_stmt'
	FROM sys.dm_tran_locks AS t1 
	INNER JOIN sys.dm_os_waiting_tasks AS t2
	ON t1.lock_owner_address = t2.resource_address
order by t1.request_session_id;
GO

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
	
SELECT  rq.session_id,         
		SS.host_name, 
		SS.program_name, 
		SS.cpu_time, 
		[database] = DB_NAME(rq.database_id),
		rq.start_time,
		rq.row_count, 
		rq.status, 
		rq.blocking_session_id, 
		rq.percent_complete,
		rq.wait_type,
		rq.last_wait_type,
        SUBSTRING(st.text, (rq.statement_start_offset/2) + 1,

         ((CASE statement_end_offset 

          WHEN -1 THEN DATALENGTH(st.text)

          ELSE rq.statement_end_offset END 

            - rq.statement_start_offset)/2) + 1) AS statement_text, 
		st.text as full_statement,
		(select query_plan from sys.dm_exec_query_plan(rq.plan_handle)) as pla_xml

FROM sys.dm_exec_requests AS rq
	CROSS APPLY sys.dm_exec_sql_text(rq.sql_handle) st
	LEFT JOIN sys.dm_exec_sessions SS
		ON SS.session_id =rq.session_id
WHERE   rq.session_id <> @@SPID
    AND rq.session_id > 50
ORDER BY rq.session_id;
GO

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

SELECT r.Session_ID                                                                                      ,
       r.Command                                                                                         ,
       DB_NAME(r.database_id) DBname                                                                     ,
       CONVERT(NUMERIC(6,2), r.percent_complete)                                 AS [Percent Complete]   ,
       r.Wait_Type,
       CONVERT(VARCHAR(20),DATEADD(ms,r.estimated_completion_time,GETDATE()),20) AS [ETA Completion TIME],
       CONVERT(NUMERIC(6,2),r.total_elapsed_time       /1000.0/60.0)                    AS [Elapsed MIN]        ,
       CONVERT(NUMERIC(6,2),r.estimated_completion_time/1000.0/60.0)                    AS [ETA MIN]            ,
       CONVERT(NUMERIC(6,2),r.estimated_completion_time/1000.0/60.0/60.0)               AS [ETA Hours]          ,
       CONVERT(VARCHAR(100),
       (SELECT SUBSTRING(text,r.statement_start_offset/2,
               CASE
                       WHEN r.statement_end_offset = -1
                       THEN 1000
                       ELSE (r.statement_end_offset-r.statement_start_offset)/2
               END) 
       FROM    sys.dm_exec_sql_text(sql_handle)
       )) AS [TextQuery]
FROM   sys.dm_exec_requests r
WHERE command IN ('RESTORE DATABASE','BACKUP LOG','RESTORE LOG',
                   'BACKUP DATABASE', 'RESTORE HEADERON', 'DBCC TABLE CHECK')
GO


----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

select  
	 DB_NAME(database_id) [DBNAME]
	,login_name
	,program_name
	,host_name
	,count(1)	[QtdSessions]
	,MAX(login_time) [LastLogin]
from sys.dm_exec_sessions 
where session_id > 50 
group by 
	 database_id
	,login_name
	,program_name
	,host_name
GO

