/* 

Check when the last index rebuild for a table occurred 

------------------------ CHANGE LOG ------------------------
2017-12-23 - Thiago Reque
  - Adjustments for add in Github
*/

DECLARE @TBL VARCHAR(1000) = '' 	--- DEFINE TABLENAME HERE

SELECT name AS Stats,
	STATS_DATE(object_id, stats_id) AS LastStatsUpdate
FROM sys.stats
WHERE object_id = OBJECT_ID(@TBL)
and left(name,4)!='_WA_';