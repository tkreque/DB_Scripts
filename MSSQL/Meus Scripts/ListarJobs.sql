USE msdb
GO

SELECT DISTINCT
	t1.name, 
	t1.date_created,
	MAX(t2.start_execution_date), 
	MAX(t2.next_scheduled_run_date)
FROM msdb..sysjobs t1
	INNER JOIN msdb..sysjobactivity t2 ON
		t1.job_id = t2.job_id
WHERE 
	t1.enabled = 1 
	--AND t1.name NOT LIKE '%DBA%'
GROUP BY t1.name, t1.date_created
ORDER BY t1.name


