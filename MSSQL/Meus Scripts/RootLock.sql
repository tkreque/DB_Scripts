SELECT 
	spid AS Victim, 
	blocked AS Blocker, 
	WaitResource,
	Status, 
	loginame AS LoginName,
	'KILL '+CONVERT(VARCHAR(7),blocked)+' -- WITH STATUSONLY' AS Query,
	CONVERT(XML,(SELECT [text] FROM sys.dm_exec_requests AS rq
	CROSS APPLY sys.dm_exec_sql_text(rq.sql_handle) 
	WHERE rq.session_id = pr.spid)) AS VictimSql,
	CONVERT(XML,(SELECT [text] FROM sys.dm_exec_requests AS rq
	CROSS APPLY sys.dm_exec_sql_text(rq.sql_handle) 
	WHERE rq.session_id = pr.blocked)) AS BlockerSql  
FROM sys.sysprocesses pr
WHERE blocked > 0
	AND blocked IN (
		SELECT spid
		FROM sys.sysprocesses
		WHERE blocked = 0
		)

