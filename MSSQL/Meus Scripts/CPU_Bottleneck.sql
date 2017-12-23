--/*
-- QUERY FROM TECHNET
select top 50 
    sum(qs.total_worker_time) as total_cpu_time, 
    sum(qs.execution_count) as total_execution_count,
    count(*) as  number_of_statements, 
    qs.plan_handle 
from 
    sys.dm_exec_query_stats qs
group by qs.plan_handle
order by sum(qs.total_worker_time) desc
--*/
--/*
-- MY QUERY 
select 
	total_cpu_time,
	total_execution_count,
	number_of_statements,
	(select text from sys.dm_exec_sql_text(t1.sql_handle)) as query_stmt,
	(select query_plan from sys.dm_exec_query_plan(t1.plan_handle)) as plan_xml,
	t1.plan_handle	
from (
	select top 50 
		sum(qs.total_worker_time) as total_cpu_time, 
		sum(qs.execution_count) as total_execution_count,
		count(*) as  number_of_statements,
		qs.plan_handle,
		qs.sql_handle 
	from 
		sys.dm_exec_query_stats qs
	group by qs.plan_handle, qs.sql_handle
	) as t1
order by t1.total_cpu_time desc
--*/
/*
-- TAKE THE QUERY AND PLAN STATEMENTS
select (select query_plan from sys.dm_exec_query_plan()) 
from sys.dm_exec_query_stats
select (select text from sys.dm_exec_sql_text()) 
from sys.dm_exec_query_stats
*/