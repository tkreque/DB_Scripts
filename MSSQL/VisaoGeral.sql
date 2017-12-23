WITH blocking_info AS
(
    SELECT
        [blocker] = wait.blocking_session_id,
        [waiter] = lock.request_session_id,
        b_handle = br.[sql_handle],
        w_handle = wr.[sql_handle],
        [dbid] = lock.resource_database_id,
        duration = wait.wait_duration_ms / 1000,
        lock_type = lock.resource_type,
        lock_mode = block.request_mode
    FROM
        sys.dm_tran_locks AS lock
    INNER JOIN 
        sys.dm_os_waiting_tasks AS wait
        ON lock.lock_owner_address = wait.resource_address
    INNER JOIN
        sys.dm_exec_requests AS br
        ON wait.blocking_session_id = br.session_id
    INNER JOIN
        sys.dm_exec_requests AS wr
        ON lock.request_session_id = wr.session_id
    INNER JOIN 
        sys.dm_tran_locks AS block
        ON block.request_session_id = br.session_id
    WHERE
        block.request_owner_type = 'TRANSACTION'
)
SELECT
    [database] = DB_NAME(bi.[dbid]),
    bi.blocker,
    blocker_command = bt.[text],
    bi.waiter,
    waiter_command  = wt.[text],
    [duration MM:SS] = RTRIM(bi.duration / 60) + ':' 
        + RIGHT('0' + RTRIM(bi.duration % 60), 2),
    bi.lock_type,
    bi.lock_mode
FROM
    blocking_info AS bi
CROSS APPLY
    sys.dm_exec_sql_text(bi.b_handle) AS bt
CROSS APPLY
    sys.dm_exec_sql_text(bi.w_handle) AS wt;
    
    
    
    
    


SELECT  rq.session_id, 
		[database] = DB_NAME(rq.database_id),
		rq.start_time,
		rq.status, 
		rq.blocking_session_id, 
		rq.percent_complete,
		rq.wait_type,
		rq.last_wait_type,
		rq.row_count,
        CASE   
		   WHEN rq.[statement_start_offset] > 0 THEN  
			  --The start of the active command is not at the beginning of the full command text 
			  CASE rq.[statement_end_offset]  
				 WHEN -1 THEN  
					--The end of the full command is also the end of the active statement 
					SUBSTRING(st.TEXT, (rq.[statement_start_offset]/2) + 1, 2147483647) 
				 ELSE   
					--The end of the active statement is not at the end of the full command 
					SUBSTRING(st.TEXT, (rq.[statement_start_offset]/2) + 1, (rq.[statement_end_offset] - rq.[statement_start_offset])/2)   
			  END  
		   ELSE  
			  --1st part of full command is running 
			  CASE rq.[statement_end_offset]  
				 WHEN -1 THEN  
					--The end of the full command is also the end of the active statement 
					RTRIM(LTRIM(st.[text]))  
				 ELSE  
					--The end of the active statement is not at the end of the full command 
					LEFT(st.TEXT, (rq.[statement_end_offset]/2) +1)  
			  END  
		   END AS [executing statement],  
		st.[text] AS [full statement code] , 
		rq.query_hash,
		rq.query_plan_hash,
		cp.query_plan		
FROM sys.dm_exec_requests AS rq
	CROSS APPLY sys.dm_exec_sql_text(rq.sql_handle) st
	cross apply sys.dm_exec_query_plan(rq.plan_handle) cp		
WHERE   rq.session_id <> @@SPID
    AND rq.session_id > 50
    
    
    
    
-- capturar cursores    
SELECT c.session_id, c.properties, c.creation_time, c.is_open, t.text, c.reads, c.fetch_buffer_size, c.creation_time
FROM sys.dm_exec_cursors (0) c 
	CROSS APPLY sys.dm_exec_sql_text (c.sql_handle) t









--------- visao geral sessões
SELECT
	ConnectionCount, OpenTranCount, OpenCursorCount, ClosedCursorCount, BlockingRequestCount,
	ActiveReqCount, OpenResultSetCount, ActiveReqOpenTranCount, BlockedReqCount,
	WaitTime, CPUTime, ElapsedTime, Reads, Writes, LogicalReads, PendingIOCount, [RowCount], GrantedQueryMemoryKB,
	PiggiestRequest.session_id AS PiggiestRequestSessionID,
	PiggiestRequest.login_name AS PiggiestRequestLoginName,
	PiggiestRequest.host_name AS PiggiestRequestHostName,
	PiggiestRequest.program_name AS PiggiestRequestProgramName,
	PiggiestRequest.DatabaseID AS PiggiestRequestDatabaseID,
	PiggiestRequest.DatabaseName AS PiggiestRequestDatabaseName,
	PiggiestRequest.BatchText AS PiggiestRequestBatchText,
	PiggiestRequest.BatchTextLength, PiggiestRequest.StatementStartPos,
	PiggiestRequest.StatementEndPos, PiggiestRequest.StatementTextLength,
	PiggiestRequest.StatementText AS PiggiestRequestStatementText,
	PiggiestRequest.QueryPlan AS PiggiestRequestQueryPlanXML
FROM
	(
		SELECT
			SUM(ConnectionCount) AS ConnectionCount,
			SUM(CONVERT(bigint, ISNULL(dm_tran_session_transactions.TransactionCount,0))) AS OpenTranCount,
			SUM(CONVERT(bigint, ISNULL(dm_exec_cursors.OpenCursorCount,0))) AS OpenCursorCount,
			SUM(CONVERT(bigint, ISNULL(dm_exec_cursors.ClosedCursorCount,0))) AS ClosedCursorCount,
			ISNULL(SUM(dm_exec_blockrequests.BlockingRequestCount),0) AS BlockingRequestCount,
			SUM(dm_exec_requests.ActiveReqCount) AS ActiveReqCount,
			SUM(dm_exec_requests.open_resultset_count) AS OpenResultSetCount,
			SUM(dm_exec_requests.open_transaction_count) AS ActiveReqOpenTranCount,
			SUM(dm_exec_requests.BlockedReqCount) AS BlockedReqCount,
			SUM(dm_exec_requests.wait_time) AS WaitTime,
			SUM(dm_exec_requests.cpu_time) AS CPUTime,
			SUM(dm_exec_requests.total_elapsed_time) AS ElapsedTime,
			SUM(dm_exec_requests.reads) AS Reads,
			SUM(dm_exec_requests.writes) AS Writes,
			SUM(dm_exec_requests.logical_reads) AS LogicalReads,
			SUM(dm_exec_requests.PendingIOCount) AS PendingIOCount,
			SUM(dm_exec_requests.row_count) AS [RowCount],
			SUM(dm_exec_requests.granted_query_memory) AS GrantedQueryMemoryKB
		FROM
			sys.dm_exec_sessions
			LEFT OUTER JOIN (
				SELECT session_id, COUNT(*) AS ConnectionCount FROM sys.dm_exec_connections GROUP BY session_id
			) AS dm_exec_connections ON sys.dm_exec_sessions.session_id=dm_exec_connections.session_id
			LEFT OUTER JOIN (
				SELECT session_id, COUNT(*) AS TransactionCount FROM sys.dm_tran_session_transactions GROUP BY session_id
			) AS dm_tran_session_transactions ON sys.dm_exec_sessions.session_id=dm_tran_session_transactions.session_id
			LEFT OUTER JOIN (
				SELECT blocking_session_id, COUNT(*) AS BlockingRequestCount FROM sys.dm_exec_requests GROUP BY blocking_session_id
			) AS dm_exec_blockrequests ON sys.dm_exec_sessions.session_id=dm_exec_blockrequests.blocking_session_id
			LEFT OUTER JOIN (
				SELECT session_id, SUM(CASE WHEN is_open=1 THEN 1 ELSE 0 END) AS OpenCursorCount, SUM(CASE WHEN is_open=0 THEN 1 ELSE 0 END) AS ClosedCursorCount
				FROM sys.dm_exec_cursors (0)
				GROUP BY session_id
			) AS dm_exec_cursors ON sys.dm_exec_sessions.session_id=dm_exec_cursors.session_id
			LEFT OUTER JOIN (
				SELECT
					dm_exec_requests.session_id,
					SUM(CONVERT(bigint, dm_exec_requests.open_transaction_count)) AS open_transaction_count,
					SUM(CONVERT(bigint, dm_exec_requests.open_resultset_count)) AS open_resultset_count,
					SUM(CASE WHEN dm_exec_requests.total_elapsed_time IS NULL THEN 0 ELSE 1 END) AS ActiveReqCount,
					SUM(CASE WHEN dm_exec_requests.blocking_session_id <> 0 THEN 1 ELSE 0 END) AS BlockedReqCount,
					SUM(CONVERT(bigint, dm_exec_requests.wait_time)) AS wait_time,
					SUM(CONVERT(bigint, dm_exec_requests.cpu_time)) AS cpu_time,
					SUM(CONVERT(bigint, dm_exec_requests.total_elapsed_time)) AS total_elapsed_time,
					SUM(CONVERT(bigint, dm_exec_requests.reads)) AS Reads,
					SUM(CONVERT(bigint, dm_exec_requests.writes)) AS Writes,
					SUM(CONVERT(bigint, dm_exec_requests.logical_reads)) AS logical_reads,
					SUM(CONVERT(bigint, dm_os_tasks.PendingIOCount)) AS PendingIOCount,
					SUM(CONVERT(bigint, dm_exec_requests.row_count)) AS row_count,
					SUM(CONVERT(bigint, dm_exec_requests.granted_query_memory*8)) AS granted_query_memory
				FROM
					sys.dm_exec_requests
					LEFT OUTER JOIN (
						SELECT request_id, session_id, SUM(pending_io_count) AS PendingIOCount
						FROM sys.dm_os_tasks WITH (NOLOCK)
						GROUP BY request_id, session_id
					) AS dm_os_tasks ON
						dm_exec_requests.request_id=dm_os_tasks.request_id
						AND dm_exec_requests.session_id=dm_os_tasks.session_id
				GROUP BY dm_exec_requests.session_id
			) AS dm_exec_requests ON sys.dm_exec_sessions.session_id=dm_exec_requests.session_id
		WHERE sys.dm_exec_sessions.is_user_process=1
	) AS Sessions
	LEFT OUTER JOIN (
		SELECT
			Requests.login_name, Requests.host_name, Requests.program_name, Requests.session_id,
			Requests.database_id AS DatabaseID, databases.name AS DatabaseName,
			Statements.text AS BatchText,
			LEN(Statements.text) AS BatchTextLength,
			Requests.statement_start_offset/2 AS StatementStartPos,
			CASE
				WHEN Requests.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(MAX),Statements.text))*2
				ELSE Requests.statement_end_offset
			END/2 AS StatementEndPos,
			(CASE
				WHEN Requests.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(MAX),Statements.text))*2
				ELSE Requests.statement_end_offset
			END - Requests.statement_start_offset)/2 AS StatementTextLength,
			CASE
				WHEN Requests.sql_handle IS NULL THEN ' '
				ELSE
					SubString(
						Statements.text,
						(Requests.statement_start_offset+2)/2,
						(CASE
							WHEN Requests.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(MAX),Statements.text))*2
							ELSE Requests.statement_end_offset
						END - Requests.statement_start_offset)/2
					)
			END AS StatementText,
			QueryPlans.query_plan AS QueryPlan
		FROM
			(
				SELECT
					Sessions.login_name, Sessions.host_name, Sessions.program_name, Requests.session_id,
					Requests.database_id,
					CONVERT(BigInt, (Requests.cpu_time+1))*CONVERT(BigInt, (Requests.reads*10+Requests.writes*10+Requests.logical_reads+1)) AS score,
					Requests.sql_handle, Requests.plan_handle, Requests.statement_start_offset, Requests.statement_end_offset,
					ROW_NUMBER() OVER (
						ORDER BY CONVERT(BigInt, (Requests.cpu_time+1))*CONVERT(BigInt, (Requests.reads*10+Requests.writes*10+Requests.logical_reads+1)) DESC
					) AS RowNumber
				FROM
					sys.dm_exec_sessions AS Sessions
					JOIN sys.dm_exec_requests AS Requests ON Sessions.session_id=Requests.session_id
			) AS Requests
			LEFT OUTER JOIN sys.databases ON requests.database_id=databases.database_id
			OUTER APPLY sys.dm_exec_sql_text(sql_handle) AS Statements
			OUTER APPLY sys.dm_exec_query_plan(plan_handle) AS QueryPlans
		WHERE RowNumber=1
	) AS PiggiestRequest ON 1=1

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

--Connections by LoginName, Hostname, and ProgramName
SELECT
	Sessions.login_name, Sessions.host_name, Sessions.program_name,
	ConnectionCount, OpenTranCount, OpenCursorCount, ClosedCursorCount, BlockingRequestCount,
	ActiveReqCount, OpenResultSetCount, ActiveReqOpenTranCount, BlockedReqCount,
	WaitTime, CPUTime, ElapsedTime, Reads, Writes, LogicalReads, PendingIOCount, [RowCount], GrantedQueryMemoryKB,
	PiggiestRequest.session_id AS PiggiestRequestSessionID,
	PiggiestRequest.DatabaseID AS PiggiestRequestDatabaseID,
	PiggiestRequest.DatabaseName AS PiggiestRequestDatabaseName,
	PiggiestRequest.BatchText AS PiggiestRequestBatchText,
	PiggiestRequest.BatchTextLength, PiggiestRequest.StatementStartPos,
	PiggiestRequest.StatementEndPos, PiggiestRequest.StatementTextLength,
	PiggiestRequest.StatementText AS PiggiestRequestStatementText,
	PiggiestRequest.QueryPlan AS PiggiestRequestQueryPlanXML
FROM
	(
		SELECT
			sys.dm_exec_sessions.login_name, sys.dm_exec_sessions.host_name, sys.dm_exec_sessions.program_name,
			SUM(ConnectionCount) AS ConnectionCount,
			SUM(CONVERT(bigint, ISNULL(dm_tran_session_transactions.TransactionCount,0))) AS OpenTranCount,
			SUM(CONVERT(bigint, ISNULL(dm_exec_cursors.OpenCursorCount,0))) AS OpenCursorCount,
			SUM(CONVERT(bigint, ISNULL(dm_exec_cursors.ClosedCursorCount,0))) AS ClosedCursorCount,
			ISNULL(SUM(dm_exec_blockrequests.BlockingRequestCount),0) AS BlockingRequestCount,
			SUM(dm_exec_requests.ActiveReqCount) AS ActiveReqCount,
			SUM(dm_exec_requests.open_resultset_count) AS OpenResultSetCount,
			SUM(dm_exec_requests.open_transaction_count) AS ActiveReqOpenTranCount,
			SUM(dm_exec_requests.BlockedReqCount) AS BlockedReqCount,
			SUM(dm_exec_requests.wait_time) AS WaitTime,
			SUM(dm_exec_requests.cpu_time) AS CPUTime,
			SUM(dm_exec_requests.total_elapsed_time) AS ElapsedTime,
			SUM(dm_exec_requests.reads) AS Reads,
			SUM(dm_exec_requests.writes) AS Writes,
			SUM(dm_exec_requests.logical_reads) AS LogicalReads,
			SUM(dm_exec_requests.PendingIOCount) AS PendingIOCount,
			SUM(dm_exec_requests.row_count) AS [RowCount],
			SUM(dm_exec_requests.granted_query_memory) AS GrantedQueryMemoryKB
		FROM
			sys.dm_exec_sessions
			LEFT OUTER JOIN (
				SELECT session_id, COUNT(*) AS ConnectionCount FROM sys.dm_exec_connections GROUP BY session_id
			) AS dm_exec_connections ON sys.dm_exec_sessions.session_id=dm_exec_connections.session_id
			LEFT OUTER JOIN (
				SELECT session_id, COUNT(*) AS TransactionCount FROM sys.dm_tran_session_transactions GROUP BY session_id
			) AS dm_tran_session_transactions ON sys.dm_exec_sessions.session_id=dm_tran_session_transactions.session_id
			LEFT OUTER JOIN (
				SELECT blocking_session_id, COUNT(*) AS BlockingRequestCount FROM sys.dm_exec_requests GROUP BY blocking_session_id
			) AS dm_exec_blockrequests ON sys.dm_exec_sessions.session_id=dm_exec_blockrequests.blocking_session_id
			LEFT OUTER JOIN (
				SELECT session_id, SUM(CASE WHEN is_open=1 THEN 1 ELSE 0 END) AS OpenCursorCount, SUM(CASE WHEN is_open=0 THEN 1 ELSE 0 END) AS ClosedCursorCount
				FROM sys.dm_exec_cursors (0)
				GROUP BY session_id
			) AS dm_exec_cursors ON sys.dm_exec_sessions.session_id=dm_exec_cursors.session_id
			LEFT OUTER JOIN (
				SELECT
					dm_exec_requests.session_id,
					SUM(CONVERT(bigint, dm_exec_requests.open_transaction_count)) AS open_transaction_count,
					SUM(CONVERT(bigint, dm_exec_requests.open_resultset_count)) AS open_resultset_count,
					SUM(CASE WHEN dm_exec_requests.total_elapsed_time IS NULL THEN 0 ELSE 1 END) AS ActiveReqCount,
					SUM(CASE WHEN dm_exec_requests.blocking_session_id <> 0 THEN 1 ELSE 0 END) AS BlockedReqCount,
					SUM(CONVERT(bigint, dm_exec_requests.wait_time)) AS wait_time,
					SUM(CONVERT(bigint, dm_exec_requests.cpu_time)) AS cpu_time,
					SUM(CONVERT(bigint, dm_exec_requests.total_elapsed_time)) AS total_elapsed_time,
					SUM(CONVERT(bigint, dm_exec_requests.reads)) AS Reads,
					SUM(CONVERT(bigint, dm_exec_requests.writes)) AS Writes,
					SUM(CONVERT(bigint, dm_exec_requests.logical_reads)) AS logical_reads,
					SUM(CONVERT(bigint, dm_os_tasks.PendingIOCount)) AS PendingIOCount,
					SUM(CONVERT(bigint, dm_exec_requests.row_count)) AS row_count,
					SUM(CONVERT(bigint, dm_exec_requests.granted_query_memory*8)) AS granted_query_memory
				FROM
					sys.dm_exec_requests
					LEFT OUTER JOIN (
						SELECT request_id, session_id, SUM(pending_io_count) AS PendingIOCount
						FROM sys.dm_os_tasks WITH (NOLOCK)
						GROUP BY request_id, session_id
					) AS dm_os_tasks ON
						dm_exec_requests.request_id=dm_os_tasks.request_id
						AND dm_exec_requests.session_id=dm_os_tasks.session_id
				GROUP BY dm_exec_requests.session_id
			) AS dm_exec_requests ON sys.dm_exec_sessions.session_id=dm_exec_requests.session_id
		WHERE sys.dm_exec_sessions.is_user_process=1
		GROUP BY sys.dm_exec_sessions.login_name, sys.dm_exec_sessions.host_name, sys.dm_exec_sessions.program_name
	) AS Sessions
	LEFT OUTER JOIN (
		SELECT
			Requests.login_name, Requests.host_name, Requests.program_name, Requests.session_id,
			Requests.database_id AS DatabaseID, databases.name AS DatabaseName,
			Statements.text AS BatchText,
			LEN(Statements.text) AS BatchTextLength,
			Requests.statement_start_offset/2 AS StatementStartPos,
			CASE
				WHEN Requests.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(MAX),Statements.text))*2
				ELSE Requests.statement_end_offset
			END/2 AS StatementEndPos,
			(CASE
				WHEN Requests.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(MAX),Statements.text))*2
				ELSE Requests.statement_end_offset
			END - Requests.statement_start_offset)/2 AS StatementTextLength,
			CASE
				WHEN Requests.sql_handle IS NULL THEN ' '
				ELSE
					SubString(
						Statements.text,
						(Requests.statement_start_offset+2)/2,
						(CASE
							WHEN Requests.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(MAX),Statements.text))*2
							ELSE Requests.statement_end_offset
						END - Requests.statement_start_offset)/2
					)
			END AS StatementText,
			QueryPlans.query_plan AS QueryPlan
		FROM
			(
				SELECT
					Sessions.login_name, Sessions.host_name, Sessions.program_name, Requests.session_id,
					Requests.database_id,
					CONVERT(BigInt, (Requests.cpu_time+1))*CONVERT(BigInt, (Requests.reads*10+Requests.writes*10+Requests.logical_reads+1)) AS score,
					Requests.sql_handle, Requests.plan_handle, Requests.statement_start_offset, Requests.statement_end_offset,
					ROW_NUMBER() OVER (
						PARTITION BY Sessions.login_name, Sessions.host_name, Sessions.program_name
						ORDER BY CONVERT(BigInt, (Requests.cpu_time+1))*CONVERT(BigInt, (Requests.reads*10+Requests.writes*10+Requests.logical_reads+1)) DESC
					) AS RowNumber
				FROM
					sys.dm_exec_sessions AS Sessions
					JOIN sys.dm_exec_requests AS Requests ON Sessions.session_id=Requests.session_id
			) AS Requests
			LEFT OUTER JOIN sys.databases ON requests.database_id=databases.database_id
			OUTER APPLY sys.dm_exec_sql_text(sql_handle) AS Statements
			OUTER APPLY sys.dm_exec_query_plan(plan_handle) AS QueryPlans
		WHERE RowNumber=1
	) AS PiggiestRequest ON
		Sessions.login_name=PiggiestRequest.login_name
		AND Sessions.host_name=PiggiestRequest.host_name
		AND Sessions.program_name=PiggiestRequest.program_name
ORDER BY
	Sessions.ActiveReqCount DESC, Sessions.OpenTranCount DESC,
	Sessions.BlockingRequestCount DESC, Sessions.BlockedReqCount DESC, Sessions.ConnectionCount DESC,
	Sessions.login_name, Sessions.host_name, Sessions.program_name

--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

--Connections by session_id
SELECT
	Sessions.session_id, Sessions.login_name, Sessions.host_name, Sessions.program_name,
	Sessions.client_interface_name, Sessions.status,
	ConnectionCount, OpenTranCount, OpenCursorCount, ClosedCursorCount, BlockingRequestCount,
	ActiveReqCount, OpenResultSetCount, ActiveReqOpenTranCount, BlockedReqCount,
	WaitTime, CPUTime, ElapsedTime, Reads, Writes, LogicalReads, PendingIOCount, [RowCount], GrantedQueryMemoryKB,
	PiggiestRequest.DatabaseID AS PiggiestRequestDatabaseID,
	PiggiestRequest.DatabaseName AS PiggiestRequestDatabaseName,
	PiggiestRequest.BatchText AS PiggiestRequestBatchText,
	PiggiestRequest.BatchTextLength, PiggiestRequest.StatementStartPos,
	PiggiestRequest.StatementEndPos, PiggiestRequest.StatementTextLength,
	PiggiestRequest.StatementText AS PiggiestRequestStatementText,
	PiggiestRequest.QueryPlan AS PiggiestRequestQueryPlanXML
FROM
	(
		SELECT
			sys.dm_exec_sessions.session_id,
			MAX(sys.dm_exec_sessions.login_name) AS login_name, MAX(sys.dm_exec_sessions.host_name) AS host_name,
			MAX(sys.dm_exec_sessions.program_name) AS program_name, MAX(sys.dm_exec_sessions.client_interface_name) AS client_interface_name,
			MAX(sys.dm_exec_sessions.status) AS status,
			SUM(ConnectionCount) AS ConnectionCount,
			SUM(CONVERT(bigint, ISNULL(dm_tran_session_transactions.TransactionCount,0))) AS OpenTranCount,
			SUM(CONVERT(bigint, ISNULL(dm_exec_cursors.OpenCursorCount,0))) AS OpenCursorCount,
			SUM(CONVERT(bigint, ISNULL(dm_exec_cursors.ClosedCursorCount,0))) AS ClosedCursorCount,
			ISNULL(SUM(dm_exec_blockrequests.BlockingRequestCount),0) AS BlockingRequestCount,
			SUM(dm_exec_requests.ActiveReqCount) AS ActiveReqCount,
			SUM(dm_exec_requests.open_resultset_count) AS OpenResultSetCount,
			SUM(dm_exec_requests.open_transaction_count) AS ActiveReqOpenTranCount,
			SUM(dm_exec_requests.BlockedReqCount) AS BlockedReqCount,
			SUM(dm_exec_requests.wait_time) AS WaitTime,
			SUM(dm_exec_requests.cpu_time) AS CPUTime,
			SUM(dm_exec_requests.total_elapsed_time) AS ElapsedTime,
			SUM(dm_exec_requests.reads) AS Reads,
			SUM(dm_exec_requests.writes) AS Writes,
			SUM(dm_exec_requests.logical_reads) AS LogicalReads,
			SUM(dm_exec_requests.PendingIOCount) AS PendingIOCount,
			SUM(dm_exec_requests.row_count) AS [RowCount],
			SUM(dm_exec_requests.granted_query_memory) AS GrantedQueryMemoryKB
		FROM
			sys.dm_exec_sessions
			LEFT OUTER JOIN (
				SELECT session_id, COUNT(*) AS ConnectionCount FROM sys.dm_exec_connections GROUP BY session_id
			) AS dm_exec_connections ON sys.dm_exec_sessions.session_id=dm_exec_connections.session_id
			LEFT OUTER JOIN (
				SELECT session_id, COUNT(*) AS TransactionCount FROM sys.dm_tran_session_transactions GROUP BY session_id
			) AS dm_tran_session_transactions ON sys.dm_exec_sessions.session_id=dm_tran_session_transactions.session_id
			LEFT OUTER JOIN (
				SELECT blocking_session_id, COUNT(*) AS BlockingRequestCount FROM sys.dm_exec_requests GROUP BY blocking_session_id
			) AS dm_exec_blockrequests ON sys.dm_exec_sessions.session_id=dm_exec_blockrequests.blocking_session_id
			LEFT OUTER JOIN (
				SELECT session_id, SUM(CASE WHEN is_open=1 THEN 1 ELSE 0 END) AS OpenCursorCount, SUM(CASE WHEN is_open=0 THEN 1 ELSE 0 END) AS ClosedCursorCount
				FROM sys.dm_exec_cursors (0)
				GROUP BY session_id
			) AS dm_exec_cursors ON sys.dm_exec_sessions.session_id=dm_exec_cursors.session_id
			LEFT OUTER JOIN (
				SELECT
					dm_exec_requests.session_id,
					SUM(CONVERT(bigint, dm_exec_requests.open_transaction_count)) AS open_transaction_count,
					SUM(CONVERT(bigint, dm_exec_requests.open_resultset_count)) AS open_resultset_count,
					SUM(CASE WHEN dm_exec_requests.total_elapsed_time IS NULL THEN 0 ELSE 1 END) AS ActiveReqCount,
					SUM(CASE WHEN dm_exec_requests.blocking_session_id <> 0 THEN 1 ELSE 0 END) AS BlockedReqCount,
					SUM(CONVERT(bigint, dm_exec_requests.wait_time)) AS wait_time,
					SUM(CONVERT(bigint, dm_exec_requests.cpu_time)) AS cpu_time,
					SUM(CONVERT(bigint, dm_exec_requests.total_elapsed_time)) AS total_elapsed_time,
					SUM(CONVERT(bigint, dm_exec_requests.reads)) AS Reads,
					SUM(CONVERT(bigint, dm_exec_requests.writes)) AS Writes,
					SUM(CONVERT(bigint, dm_exec_requests.logical_reads)) AS logical_reads,
					SUM(CONVERT(bigint, dm_os_tasks.PendingIOCount)) AS PendingIOCount,
					SUM(CONVERT(bigint, dm_exec_requests.row_count)) AS row_count,
					SUM(CONVERT(bigint, dm_exec_requests.granted_query_memory*8)) AS granted_query_memory
				FROM
					sys.dm_exec_requests
					LEFT OUTER JOIN (
						SELECT request_id, session_id, SUM(pending_io_count) AS PendingIOCount
						FROM sys.dm_os_tasks WITH (NOLOCK)
						GROUP BY request_id, session_id
					) AS dm_os_tasks ON
						dm_exec_requests.request_id=dm_os_tasks.request_id
						AND dm_exec_requests.session_id=dm_os_tasks.session_id
				GROUP BY dm_exec_requests.session_id
			) AS dm_exec_requests ON sys.dm_exec_sessions.session_id=dm_exec_requests.session_id
		WHERE sys.dm_exec_sessions.is_user_process=1
		GROUP BY sys.dm_exec_sessions.session_id
	) AS Sessions
	LEFT OUTER JOIN (
		SELECT
			Requests.session_id,
			Requests.database_id AS DatabaseID, databases.name AS DatabaseName,
			Statements.text AS BatchText,
			LEN(Statements.text) AS BatchTextLength,
			Requests.statement_start_offset/2 AS StatementStartPos,
			CASE
				WHEN Requests.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(MAX),Statements.text))*2
				ELSE Requests.statement_end_offset
			END/2 AS StatementEndPos,
			(CASE
				WHEN Requests.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(MAX),Statements.text))*2
				ELSE Requests.statement_end_offset
			END - Requests.statement_start_offset)/2 AS StatementTextLength,
			CASE
				WHEN Requests.sql_handle IS NULL THEN ' '
				ELSE
					SubString(
						Statements.text,
						(Requests.statement_start_offset+2)/2,
						(CASE
							WHEN Requests.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(MAX),Statements.text))*2
							ELSE Requests.statement_end_offset
						END - Requests.statement_start_offset)/2
					)
			END AS StatementText,
			QueryPlans.query_plan AS QueryPlan
		FROM
			(
				SELECT
					Requests.session_id,
					Requests.database_id,
					CONVERT(BigInt, (Requests.cpu_time+1))*CONVERT(BigInt, (Requests.reads*10+Requests.writes*10+Requests.logical_reads+1)) AS score,
					Requests.sql_handle, Requests.plan_handle, Requests.statement_start_offset, Requests.statement_end_offset,
					ROW_NUMBER() OVER (
						PARTITION BY Requests.session_id
						ORDER BY CONVERT(BigInt, (Requests.cpu_time+1))*CONVERT(BigInt, (Requests.reads*10+Requests.writes*10+Requests.logical_reads+1)) DESC
					) AS RowNumber
				FROM sys.dm_exec_requests AS Requests
			) AS Requests
			LEFT OUTER JOIN sys.databases ON requests.database_id=databases.database_id
			OUTER APPLY sys.dm_exec_sql_text(sql_handle) AS Statements
			OUTER APPLY sys.dm_exec_query_plan(plan_handle) AS QueryPlans
		WHERE RowNumber=1
	) AS PiggiestRequest ON Sessions.session_id=PiggiestRequest.session_id
ORDER BY
	Sessions.ActiveReqCount DESC, Sessions.OpenTranCount DESC,
	Sessions.BlockingRequestCount DESC, Sessions.BlockedReqCount DESC, Sessions.ConnectionCount DESC,
	Sessions.login_name, Sessions.host_name, Sessions.program_name, Sessions.session_id

GO
