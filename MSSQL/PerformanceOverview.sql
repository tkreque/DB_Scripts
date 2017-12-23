DECLARE @ORDER INT = 14
/*
01 - Query
02 - statement_text
03 - query_fingerprint
04 - plan_fingerprint
05 - sample_sql_handle
06 - sample_plan_handle
07 - sample_statement_start_offset
08 - sample_statement_end_offset
09 - Executions/min <<<
10 - CPU (ms/sec)
11 - Physical Reads/sec
12 - Logical Writes/sec
13 - Logical Reads/sec
14 - Average Reads <<<
15 - Average Duration (ms)
16 - Plan Count
17 - Database Name
18 - Average CPU <<<
*/

IF OBJECT_ID('tempdb..#am_request_count', 'U') IS NULL
BEGIN
    CREATE TABLE #am_request_count (collection_time datetime PRIMARY KEY, request_count numeric (28, 1));
END;

IF OBJECT_ID ('tempdb..#am_fingerprint_stats_snapshots') IS NULL
BEGIN
    CREATE TABLE #am_fingerprint_stats_snapshots (
        collection_time datetime, 
        query_fingerprint binary(64), 
        plan_fingerprint binary(64), 
        plan_count int, 
        creation_time datetime, 
        last_execution_time datetime, 
        execution_count bigint, 
        total_worker_time_ms bigint, 
        min_worker_time_ms bigint, 
        max_worker_time_ms bigint, 
        total_physical_reads bigint, 
        min_physical_reads bigint, 
        max_physical_reads bigint, 
        total_logical_writes bigint, 
        min_logical_writes bigint, 
        max_logical_writes bigint, 
        total_logical_reads bigint, 
        min_logical_reads bigint, 
        max_logical_reads bigint, 
        total_clr_time bigint, 
        min_clr_time bigint, 
        max_clr_time bigint, 
        total_elapsed_time_ms bigint, 
        min_elapsed_time_ms bigint, 
        max_elapsed_time_ms bigint, 
        total_completed_execution_time_ms bigint, 
        -- A specific example of a plan with this plan fingerprint
        sample_sql_handle binary(64), 
        sample_plan_handle binary(64), 
        sample_statement_start_offset int, 
        sample_statement_end_offset int, 
        -- This fingerprint's rank by each of our perf metrics
        plan_count_rank int, 
        cpu_rank int, 
        physical_reads_rank int, 
        logical_reads_rank int, 
        logical_writes_rank int, 
        max_duration_rank int, 
        execution_count_rank int, 
        batch_text nvarchar(max),
        dbname nvarchar(128)
    );
    CREATE CLUSTERED INDEX cidx ON #am_fingerprint_stats_snapshots (collection_time, query_fingerprint, plan_fingerprint)
END;

-- Set @N to the number of queries to capture by each ordering metric.  Since there are seven different metrics, 
-- if N=10, you will get a minimum of 10 query plans (if the top 20 are the same for all metrics) and a max of 70
-- queries (if the five sets of 10 queries are all disjoint sets).  Actually, the query returns 'plan fingerprint' 
-- stats, not plan stats. 
DECLARE @N int;
SET @N = 20;

SET NOCOUNT ON;

-- Step 1: Capture a snapshot of (cumulative) query stats and store it in #temp_fingerprint_stats 
IF OBJECT_ID ('tempdb..#temp_fingerprint_stats') IS NOT NULL
BEGIN
    DROP TABLE #temp_fingerprint_stats;
END;

-- Get timestamp of current snapshot
DECLARE @current_collection_time datetime;
SET @current_collection_time = GETDATE();

-- This CTE returns a unified view of the query stats for both in-progress queries (from sys.dm_exec_requests)
-- and completed queries (from sys.dm_exec_query_stats). 
WITH merged_query_stats AS 
(
    SELECT 
        [sql_handle], 
        statement_start_offset,
        statement_end_offset,
        plan_generation_num,
        [plan_handle], 
        query_hash AS query_fingerprint, 
        query_plan_hash AS plan_fingerprint, 
        creation_time,
        last_execution_time, 
        execution_count,
        total_worker_time / 1000 AS total_worker_time_ms,
        min_worker_time / 1000 AS min_worker_time_ms,
        max_worker_time / 1000 AS max_worker_time_ms,
        total_physical_reads,
        min_physical_reads,
        max_physical_reads,
        total_logical_writes,
        min_logical_writes,
        max_logical_writes,
        total_logical_reads,
        min_logical_reads,
        max_logical_reads,
        total_clr_time,
        min_clr_time,
        max_clr_time,
        total_elapsed_time / 1000 AS total_elapsed_time_ms,
        min_elapsed_time / 1000 AS min_elapsed_time_ms,
        max_elapsed_time / 1000 AS max_elapsed_time_ms, 
        total_elapsed_time / 1000 AS total_completed_execution_time_ms
    FROM sys.dm_exec_query_stats AS q
    -- To reduce the number of rows that we have to deal with in later queries, filter out any very old rows
    WHERE q.last_execution_time > DATEADD (hour, -4, GETDATE())
    
    -- The UNIONed query below is a workaround for VSTS #91422, sys.dm_exec_query_stats does not reflect stats for in-progress queries. 
    UNION ALL 
    SELECT 
        [sql_handle],
        statement_start_offset,
        statement_end_offset,
        NULL AS plan_generation_num,
        plan_handle,
        query_hash AS query_fingerprint, 
        query_plan_hash AS plan_fingerprint, 
        start_time AS creation_time,
        start_time AS last_execution_time,
        0 AS execution_count,
        cpu_time AS total_worker_time_ms,
        NULL AS min_worker_time_ms,  -- min should not be influenced by in-progress queries
        cpu_time AS max_worker_time_ms,
        reads AS total_physical_reads,
        NULL AS min_physical_reads,  -- min should not be influenced by in-progress queries
        reads AS max_physical_reads,
        writes AS total_logical_writes,
        NULL AS min_logical_writes,  -- min should not be influenced by in-progress queries
        writes AS max_logical_writes,
        logical_reads AS total_logical_reads,
        NULL AS min_logical_reads,   -- min should not be influenced by in-progress queries
        logical_reads AS max_logical_reads,
        NULL AS total_clr_time,      -- CLR time is not available in dm_exec_requests
        NULL AS min_clr_time,        -- CLR time is not available in dm_exec_requests
        NULL AS max_clr_time,        -- CLR time is not available in dm_exec_requests
        total_elapsed_time AS total_elapsed_time_ms,
        NULL AS min_elapsed_time_ms, -- min should not be influenced by in-progress queries
        total_elapsed_time AS max_elapsed_time_ms, 
        NULL AS total_completed_execution_time_ms
    FROM sys.dm_exec_requests AS r 
    WHERE [sql_handle] IS NOT NULL 
        -- Don't attempt to collect stats for very brief in-progress requests; the active statement 
        -- will likely have changed by the time that we harvest query text, in the next query 
        AND DATEDIFF (second, r.start_time, @current_collection_time) > 1
)
-- Insert the fingerprint stats into a temp table.  SQL isn't always able to produce a good estimate of the amount of 
-- memory that the upcoming sorts (for ROW_NUMER()) will need because of lack of accurate stats on DMVs.  Staging the 
-- data in a temp table allows the memory cost of the sort operations to be more accurate, which avoids unnecessary 
-- spilling to tempdb. 
SELECT 
    fingerprint_stats.*, 
    example_plan.sample_sql_handle, 
    example_plan.sample_plan_handle, 
    example_plan.sample_statement_start_offset, 
    example_plan.sample_statement_end_offset
INTO #temp_fingerprint_stats
FROM
-- Calculate plan fingerprint stats by grouping the query stats by plan fingerprint
(
    SELECT 
        mqs.query_fingerprint, 
        mqs.plan_fingerprint, 
        -- The same plan could be returned by both dm_exec_query_stats and dm_exec_requests -- count distinct plan 
        -- handles only
        COUNT(DISTINCT plan_handle) AS plan_count, 
        MIN (mqs.creation_time) AS creation_time, 
        MAX (mqs.last_execution_time) AS last_execution_time, 
        SUM (mqs.execution_count) AS execution_count, 
        SUM (mqs.total_worker_time_ms) AS total_worker_time_ms, 
        MIN (mqs.min_worker_time_ms) AS min_worker_time_ms, 
        MAX (mqs.max_worker_time_ms) AS max_worker_time_ms, 
        SUM (mqs.total_physical_reads) AS total_physical_reads, 
        MIN (mqs.min_physical_reads) AS min_physical_reads, 
        MAX (mqs.max_physical_reads) AS max_physical_reads, 
        SUM (mqs.total_logical_writes) AS total_logical_writes, 
        MIN (mqs.min_logical_writes) AS min_logical_writes, 
        MAX (mqs.max_logical_writes) AS max_logical_writes, 
        SUM (mqs.total_logical_reads) AS total_logical_reads, 
        MIN (mqs.min_logical_reads) AS min_logical_reads, 
        MAX (mqs.max_logical_reads) AS max_logical_reads, 
        SUM (mqs.total_clr_time) AS total_clr_time, 
        MIN (mqs.min_clr_time) AS min_clr_time, 
        MAX (mqs.max_clr_time) AS max_clr_time, 
        SUM (mqs.total_elapsed_time_ms) AS total_elapsed_time_ms, 
        MIN (mqs.min_elapsed_time_ms) AS min_elapsed_time_ms, 
        MAX (mqs.max_elapsed_time_ms) AS max_elapsed_time_ms, 
        SUM (mqs.total_completed_execution_time_ms) AS total_completed_execution_time_ms 
    FROM merged_query_stats AS mqs
    GROUP BY 
        mqs.query_fingerprint, 
        mqs.plan_fingerprint
) AS fingerprint_stats
INNER JOIN 
(
    -- This query assigns a unique row identifier to each plan that has the same fingerprint -- we'll 
    -- select each fingerprint's 'Plan #1' (the earliest example that's still in cache) to use as a sample plan
    -- for the fingerprint.  Later (in the outer query's WHERE clause) we'll filter out all but the first plan, 
    -- and use that one to get a valid sql_handle/plan_handle. 
    SELECT 
        *, 
        ROW_NUMBER() OVER (
            PARTITION BY plan_fingerprint 
            ORDER BY creation_time 
        ) AS plan_instance_number 
    FROM 
    (
        SELECT 
            query_hash AS query_fingerprint, 
            query_plan_hash AS plan_fingerprint, 
            qs.[sql_handle] AS sample_sql_handle, 
            qs.plan_handle AS sample_plan_handle, 
            qs.statement_start_offset AS sample_statement_start_offset, 
            qs.statement_end_offset AS sample_statement_end_offset, 
            qs.creation_time 
        FROM sys.dm_exec_query_stats AS qs 
        -- To get a sample plan for in-progress queries, we need to look in dm_exec_requests, too
        UNION ALL 
        SELECT 
            query_hash AS query_fingerprint, 
            query_plan_hash AS plan_fingerprint, 
            r.[sql_handle] AS sample_sql_handle, 
            r.plan_handle AS sample_plan_handle, 
            r.statement_start_offset AS sample_statement_start_offset, 
            r.statement_end_offset AS sample_statement_end_offset, 
            r.start_time AS creation_time
        FROM sys.dm_exec_requests AS r
    ) AS all_plans_numbered
) AS example_plan 
    ON example_plan.query_fingerprint = fingerprint_stats.query_fingerprint 
        AND example_plan.plan_fingerprint = fingerprint_stats.plan_fingerprint 
-- To improve perf of the next query, filter out plan fingerprints that aren't very interesting according to any of our 
-- perf metrics.  Note that our most frequent allowed execution rate for this script is one execution every 15 seconds, 
-- so, for example, a plan that is executed 50 times in a 15+ second time interval will qualify for further processing. 
WHERE plan_instance_number = 1
    AND (fingerprint_stats.total_worker_time_ms > 500       -- 500 ms cumulative CPU time
    OR fingerprint_stats.execution_count > 50               -- 50 executions
    OR fingerprint_stats.total_physical_reads > 50          -- 50 cumulative physical reads
    OR fingerprint_stats.total_logical_reads > 5000         -- 5,000 cumulative logical reads
    OR fingerprint_stats.total_logical_writes > 50          -- 50 cumulative logical writes
    OR fingerprint_stats.total_elapsed_time_ms > 5000)      -- 5 seconds cumulative execution time
-- SQL doesn't always have good stats on DMVs, and as a result it may select a loop join-based plan w/the 
-- sys.dm_exec_query_stats DMV as the inner table.  The DMVs don't have indexes that would support efficient 
-- loop joins, and will commonly have a large enough number of rows that unindexed loop joins will be an  
-- unattractive option. Given this, we gain much better worst-case perf with minimal cost to best-case perf 
-- by prohibiting loop joins via this hint. 
OPTION (HASH JOIN, MERGE JOIN);


-- Step 2: Rank the plan fingerprints by CPU use, execution count, etc and store the results in #am_fingerprint_stats_snapshots 
-- Now we have the stats for all plan fingerprints.  Return only the top N by each of our perf metrics.  
-- The reason we need a derived table here is because SQL disallows the direct use of ROW_NUMBER() 
-- in a WHERE clause, yet we need to filter based on the row number (rank). 
INSERT INTO #am_fingerprint_stats_snapshots
SELECT 
    @current_collection_time AS collection_time, 
    ranked_fingerprint_stats.*, 
    batch_text.text AS batch_text,
    plan_info.dbname
FROM
(
    SELECT
        *,
        -- Rank the fingerprints by each of our perf metrics 
        ROW_NUMBER () OVER (ORDER BY plan_count DESC) AS plan_count_rank, 
        ROW_NUMBER () OVER (ORDER BY total_worker_time_ms DESC) AS cpu_rank, 
        ROW_NUMBER () OVER (ORDER BY total_physical_reads DESC) AS physical_reads_rank, 
        ROW_NUMBER () OVER (ORDER BY total_logical_reads DESC) AS logical_reads_rank, 
        ROW_NUMBER () OVER (ORDER BY total_logical_writes DESC) AS logical_writes_rank, 
        ROW_NUMBER () OVER (ORDER BY max_elapsed_time_ms DESC) AS max_duration_rank, 
        ROW_NUMBER () OVER (ORDER BY execution_count DESC) AS execution_count_rank
    FROM #temp_fingerprint_stats
) AS ranked_fingerprint_stats
-- Get the query text
OUTER APPLY sys.dm_exec_sql_text (sample_sql_handle) AS batch_text
OUTER APPLY (SELECT DB_NAME(CONVERT(int, value)) AS dbname FROM sys.dm_exec_plan_attributes(sample_plan_handle) WHERE attribute='dbid') AS plan_info
WHERE 
    cpu_rank <= @N 
    OR logical_writes_rank <= @N 
    OR physical_reads_rank <= @N 
    OR max_duration_rank <= @N 
    OR execution_count_rank <= @N 
    OR plan_count_rank <= @N;


-- Step 3: Calculate the delta since the prior snapshot, and return the fingerprint stats for the just-completed time interval
-- Get timestamp of previous snapshot
DECLARE @previous_collection_time datetime;
SELECT TOP 1 @previous_collection_time = collection_time 
FROM #am_fingerprint_stats_snapshots
WHERE collection_time < @current_collection_time
ORDER BY collection_time DESC;

-- Subtract prior stats from current stats to get stats for this time interval
-- 
-- In this query, the expression below represents 'interval duration'.  If we do find the plan in the prior snapshot, we use 
-- [current_snapshot_time - prior_snapshot_time] to calculate the interval duration.  If we don't find the plan fingerprint in 
-- the prior snapshot (either because this is the first snapshot, or because this is the first time this plan has shown up in 
-- our TOP N), and if the plan has been around since before our prior snapshot, we amortize its execution cost over the plan 
-- lifetime.  
-- 
--  DATEDIFF (second, 
--      CASE 
--          WHEN (prev_stats.plan_fingerprint IS NULL AND cur_stats.creation_time < @previous_collection_time)
--              THEN cur_stats.creation_time 
--          ELSE @previous_collection_time 
--      END, 
--      @current_collection_time)
--
-- The purpose of this is to avoid the assumption that all execution stats for a 'new' query plan occurred within the just-
-- completed time interval.  It also allows us to show some execution stats immediately after the first snapshot, rather than 
-- waiting until the second snapshot. 
WITH interval_fingerprint_stats AS
(
    SELECT 
        cur_stats.batch_text, 
        SUBSTRING (
            cur_stats.batch_text, 
            (cur_stats.sample_statement_start_offset/2) + 1, 
            (
                (
                    CASE cur_stats.sample_statement_end_offset 
                        WHEN -1 THEN DATALENGTH(cur_stats.batch_text)
                        WHEN 0 THEN DATALENGTH(cur_stats.batch_text)
                        ELSE cur_stats.sample_statement_end_offset 
                    END 
                    - cur_stats.sample_statement_start_offset
                )/2
            ) + 1
        ) AS statement_text, 
        -- If we don't have a prior snapshot, and if the plan has been around since before the start of the interval, 
        -- amortize the cost of the query over its lifetime so that we don't make the (typically incorrect) assumption 
        -- that the cost was all accumulated within the just-completed interval. 
        CASE 
            WHEN DATEDIFF (second, CASE WHEN (@previous_collection_time IS NULL) OR (prev_stats.plan_fingerprint IS NULL AND cur_stats.creation_time < @previous_collection_time) THEN cur_stats.creation_time ELSE @previous_collection_time END, @current_collection_time) > 0
            THEN DATEDIFF (second, CASE WHEN (@previous_collection_time IS NULL) OR (prev_stats.plan_fingerprint IS NULL AND cur_stats.creation_time < @previous_collection_time) THEN cur_stats.creation_time ELSE @previous_collection_time END, @current_collection_time)
            ELSE 1 -- protect from divide by zero
        END AS interval_duration_sec, 
        cur_stats.query_fingerprint, 
        cur_stats.plan_fingerprint, 
        cur_stats.sample_sql_handle, 
        cur_stats.sample_plan_handle, 
        cur_stats.sample_statement_start_offset, 
        cur_stats.sample_statement_end_offset, 
        cur_stats.plan_count, 
        -- If a plan is removed from cache, then reinserted, it is possible for it to seem to have negative cost.  The 
        -- CASE statements below handle this scenario. 
        CASE WHEN (cur_stats.execution_count - ISNULL (prev_stats.execution_count, 0)) < 0 
            THEN cur_stats.execution_count 
            ELSE (cur_stats.execution_count - ISNULL (prev_stats.execution_count, 0)) 
        END AS interval_executions, 
        cur_stats.execution_count AS total_executions, 
        CASE WHEN (cur_stats.total_worker_time_ms - ISNULL (prev_stats.total_worker_time_ms, 0)) < 0 
            THEN cur_stats.total_worker_time_ms
            ELSE (cur_stats.total_worker_time_ms - ISNULL (prev_stats.total_worker_time_ms, 0)) 
        END AS interval_cpu_ms, 
        CASE WHEN (cur_stats.total_physical_reads - ISNULL (prev_stats.total_physical_reads, 0)) < 0 
            THEN cur_stats.total_physical_reads
            ELSE (cur_stats.total_physical_reads - ISNULL (prev_stats.total_physical_reads, 0)) 
        END AS interval_physical_reads, 
        CASE WHEN (cur_stats.total_logical_writes - ISNULL (prev_stats.total_logical_writes, 0)) < 0 
            THEN cur_stats.total_logical_writes 
            ELSE (cur_stats.total_logical_writes - ISNULL (prev_stats.total_logical_writes, 0)) 
        END AS interval_logical_writes, 
        CASE WHEN (cur_stats.total_logical_reads - ISNULL (prev_stats.total_logical_reads, 0)) < 0 
            THEN cur_stats.total_logical_reads 
            ELSE (cur_stats.total_logical_reads - ISNULL (prev_stats.total_logical_reads, 0)) 
        END AS interval_logical_reads, 
        CASE WHEN (cur_stats.total_elapsed_time_ms - ISNULL (prev_stats.total_elapsed_time_ms, 0)) < 0 
            THEN cur_stats.total_elapsed_time_ms 
            ELSE (cur_stats.total_elapsed_time_ms - ISNULL (prev_stats.total_elapsed_time_ms, 0)) 
        END AS interval_elapsed_time_ms, 
        cur_stats.total_completed_execution_time_ms AS total_completed_execution_time_ms,
        cur_stats.dbname
    FROM #am_fingerprint_stats_snapshots AS cur_stats
    LEFT OUTER JOIN #am_fingerprint_stats_snapshots AS prev_stats
        ON prev_stats.collection_time = @previous_collection_time
        AND prev_stats.plan_fingerprint = cur_stats.plan_fingerprint AND prev_stats.query_fingerprint = cur_stats.query_fingerprint
    WHERE cur_stats.collection_time = @current_collection_time
)
SELECT 
    SUBSTRING (statement_text, 1, 200) AS [Query], 
    /* Begin hidden grid columns */
    -- We must convert these to a hex string representation because they will be stored in a DataGridView, which can't  
    -- handle binary cell values (assumes anything binary is an image) 
    /* End hidden grid columns */
    interval_executions * 60 / interval_duration_sec AS [Executions/min], 
    interval_cpu_ms / interval_duration_sec AS [CPU (ms/sec)], 
    interval_physical_reads / interval_duration_sec AS [Physical Reads/sec], 
    interval_logical_writes / interval_duration_sec AS [Logical Writes/sec], 
    interval_logical_reads / interval_duration_sec AS [Logical Reads/sec], 
    interval_logical_reads / CASE interval_executions WHEN 0 THEN 1 ELSE interval_executions END AS [Average Reads], 
    interval_cpu_ms / CASE interval_executions WHEN 0 THEN 1 ELSE interval_executions END [Average CPU],
    CASE total_executions 
        WHEN 0 THEN 0
        ELSE total_completed_execution_time_ms / total_executions 
    END AS [Average Duration (ms)], 
    plan_count AS [Plan Count], 
    dbname AS [Database Name],
    statement_text,
    sample_statement_start_offset,
    sample_statement_end_offset,  
    master.dbo.fn_varbintohexstr(query_fingerprint) AS query_fingerprint, 
    master.dbo.fn_varbintohexstr(plan_fingerprint) AS plan_fingerprint,     
    master.dbo.fn_varbintohexstr(sample_sql_handle) AS sample_sql_handle,   
    master.dbo.fn_varbintohexstr(sample_plan_handle) AS sample_plan_handle
FROM interval_fingerprint_stats
ORDER BY CASE @ORDER
			WHEN 1 THEN SUBSTRING (statement_text, 1, 200)
			WHEN 2 THEN statement_text
			WHEN 3 THEN master.dbo.fn_varbintohexstr(query_fingerprint)
			WHEN 4 THEN master.dbo.fn_varbintohexstr(plan_fingerprint)
			WHEN 5 THEN master.dbo.fn_varbintohexstr(sample_sql_handle)
			WHEN 6 THEN master.dbo.fn_varbintohexstr(sample_plan_handle)
			WHEN 7 THEN sample_statement_start_offset
			WHEN 8 THEN sample_statement_end_offset
			WHEN 9 THEN interval_executions * 60 / interval_duration_sec
			WHEN 10 THEN interval_cpu_ms / interval_duration_sec
			WHEN 11 THEN interval_physical_reads / interval_duration_sec
			WHEN 12 THEN interval_logical_writes / interval_duration_sec
			WHEN 13 THEN interval_logical_reads / interval_duration_sec
			WHEN 14 THEN interval_logical_reads / CASE interval_executions WHEN 0 THEN 1 ELSE interval_executions END
			WHEN 15 THEN CASE total_executions WHEN 0 THEN 0 ELSE total_completed_execution_time_ms / total_executions END
			WHEN 16 THEN plan_count
			WHEN 17 THEN dbname
			WHEN 18 THEN interval_cpu_ms / CASE interval_executions WHEN 0 THEN 1 ELSE interval_executions END
		END DESC
-- Step 4: Delete all but the most recent snapshot; we no longer need any older data
DELETE FROM #am_fingerprint_stats_snapshots
WHERE collection_time != @current_collection_time; 

