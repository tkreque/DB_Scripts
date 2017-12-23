DECLARE @Criteria INT = 5
DECLARE @Select_Criteria NVARCHAR(MAX)
DECLARE @OrderBy_Criteria NVARCHAR(MAX) = N''--AVG_
DECLARE @Top INT = 5

SELECT @Select_Criteria = CASE @Criteria
	WHEN 1 THEN 'Logical Reads'
	WHEN 2 THEN 'Physical Reads'
	WHEN 3 THEN 'Logical Writes'
	WHEN 4 THEN 'CPU'
	WHEN 5 THEN 'Duration'
	WHEN 6 THEN 'CLR Time'
END

SELECT 
	query_rank,
	case when LEN(qt.query_text) < 2048 then qt.query_text else LEFT(qt.query_text, 2048) + N'...' end as query_text,
	convert (varchar, creation_time, 103) + ' ' + convert (varchar, creation_time, 108) creation_time,
	convert (varchar, last_execution_time, 103) + ' ' + convert (varchar, last_execution_time, 108) last_execution_time,
	execution_count,
	plan_generation_num,
-- worker time
CASE @Select_Criteria
	WHEN 'Logical Reads' then total_logical_reads
	WHEN 'Physical Reads' then total_physical_reads
	WHEN 'Logical Writes' then total_logical_writes
	WHEN 'CPU' then total_worker_time
	WHEN 'Duration' then total_elapsed_time / 1000
	WHEN 'CLR Time' then total_clr_time
END TOTAL,
CASE @Select_Criteria
	WHEN 'Logical Reads' then last_logical_reads
	WHEN 'Physical Reads' then last_physical_reads
	WHEN 'Logical Writes' then last_logical_writes
	WHEN 'CPU' then last_worker_time
	WHEN 'Duration' then last_elapsed_time / 1000
	WHEN 'CLR Time' then last_clr_time
END [LAST],
CASE @Select_Criteria
	WHEN 'Logical Reads' then min_logical_reads
	WHEN 'Physical Reads' then min_physical_reads
	WHEN 'Logical Writes' then min_logical_writes
	WHEN 'CPU' then min_worker_time
	WHEN 'Duration' then min_elapsed_time / 1000
	WHEN 'CLR Time' then min_clr_time
END [MIN],
CASE @Select_Criteria
	WHEN 'Logical Reads' then max_logical_reads
	WHEN 'Physical Reads' then max_physical_reads
	WHEN 'Logical Writes' then max_logical_writes
	WHEN 'CPU' then max_worker_time
	WHEN 'Duration' then max_elapsed_time / 1000
	WHEN 'CLR Time' then max_clr_time
END [MAX],
CASE @Select_Criteria
	WHEN 'Logical Reads' then total_logical_reads / execution_count
	WHEN 'Physical Reads' then total_physical_reads / execution_count
	WHEN 'Logical Writes' then total_logical_writes / execution_count
	WHEN 'CPU' then total_worker_time / execution_count
	WHEN 'Duration' then (total_elapsed_time / execution_count) / 1000
	WHEN 'CLR Time' then total_clr_time / execution_count
END [AVG],
	master.dbo.fn_varbintohexstr(sql_handle) as sql_handle,
	master.dbo.fn_varbintohexstr(plan_handle) as plan_handle
from (select s.*, row_number() over(order by charted_value desc, last_execution_time desc) as query_rank from
		 (select *, 
				CASE @OrderBy_Criteria + @Select_Criteria
					WHEN 'Logical Reads' then total_logical_reads
					WHEN 'AVG_Logical Reads' then total_logical_reads / execution_count
					WHEN 'Physical Reads' then total_physical_reads
					WHEN 'AVG_Physical Reads' then total_physical_reads / execution_count
					WHEN 'Logical Writes' then total_logical_writes
					WHEN 'AVG_Logical Writes' then total_logical_writes / execution_count
					WHEN 'CPU' then total_worker_time
					WHEN 'AVG_CPU' then total_worker_time / execution_count
					WHEN 'Count' then execution_count
					WHEN 'Duration' then total_elapsed_time
					WHEN 'AVG_Duration' then total_elapsed_time / execution_count
					WHEN 'CLR Time' then total_clr_time
					WHEN 'AVG_CLR Time' then total_clr_time / execution_count
				END as charted_value 
			from sys.dm_exec_query_stats) as s where s.charted_value > 0 and execution_count > CASE WHEN @OrderBy_Criteria LIKE 'AVG%' THEN 1000 ELSE 0 END) as qs
	cross apply msdb.MS_PerfDashboard.fn_QueryTextFromHandle(sql_handle, statement_start_offset, statement_end_offset) as qt
where qs.query_rank <= @Top

--select * from sys.dm_exec_query_plan()