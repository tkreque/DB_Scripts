SELECT
	T2.session_id AS [Session ID]
	,DB_NAME(T1.database_id) AS [DatabaseName]
	,T2.HOST_NAME AS [HostName]
	,T2.program_name AS [ProgramName]
	,T2.login_name AS [UserName]
	,T2.status AS [Status]
	,T2.total_elapsed_time AS [Elapsed Time (in milisec)]
	,T3.start_time AS [Start Date and Time]
	,T3.command AS [Command Type executed]
	,T3.wait_type AS [Type of Wait]
	,T3.row_count AS [Rows]
	,(T1.user_objects_alloc_page_count * 8) AS [SPACE Allocated for User Objects (in KB)]
	,(T1.user_objects_dealloc_page_count * 8) AS [SPACE Deallocated for User Objects (in KB)]
	,(T1.internal_objects_alloc_page_count * 8) AS [SPACE Allocated for Internal Objects (in KB)]
	,(T1.internal_objects_dealloc_page_count * 8) AS [SPACE Deallocated for Internal Objects (in KB)]
	,(SELECT OBJECT_NAME(objectid) FROM sys.dm_exec_sql_text(T3.sql_handle)) AS [Query Object Name]
	,CONVERT(XML,(SELECT text FROM sys.dm_exec_sql_text(T3.sql_handle) FOR XML PATH, ELEMENTS)) AS [Query Text]
FROM 
	sys.dm_db_session_space_usage T1
INNER JOIN
	sys.dm_exec_sessions T2
		ON T1.session_id = T2.session_id
INNER JOIN
	sys.dm_exec_requests T3
		ON T2.session_id = T3.session_id
WHERE T2.status = 'running' AND T2.is_user_process <> 0