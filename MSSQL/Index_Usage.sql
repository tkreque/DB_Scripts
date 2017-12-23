/* 

Check index usage for a table

------------------------ CHANGE LOG ------------------------
2017-12-23 - Thiago Reque
  - Adjustments for add in Github
*/

DECLARE @TBL VARCHAR(1000) = '' 	---- DEFINE TABLE NAME HERE

select 'object' = 'Table: ' + object_name(s.object_id), ' - Index:' = s.name
  --,'user reads' = 'Leituras: ' + convert (varchar (20), user_seeks + user_scans + user_lookups)
  ,'user reads' = user_seeks + user_scans + user_lookups
  ,'system reads' = system_seeks + system_scans + system_lookups
  ,'user writes' = user_updates
  ,'system writes' = system_updates
from sys.dm_db_index_usage_stats a
right join sys.indexes s on a.object_id = s.object_id and a.index_id = s.index_id
where
--a.index_id IS NULL and 
s.object_id = object_id(@TBL)




