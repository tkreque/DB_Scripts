
select * from sys.dm_exec_query_optimizer_info

select top 25
    sql_text.text,
    sql_handle,
    plan_generation_num,
    execution_count,
    dbid,
    objectid 
from 
    sys.dm_exec_query_stats a
    cross apply sys.dm_exec_sql_text(sql_handle) as sql_text
where 
    plan_generation_num >1
order by plan_generation_num desc