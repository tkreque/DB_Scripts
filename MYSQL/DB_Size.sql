/* 

------------------------ CHANGE LOG ------------------------
2018-01-30 - Thiago Reque
  - Created the script
*/

-- DATABASES SIZE IN MB
SELECT 
	TABLE_SCHEMA, 
	SUM(DATA_LENGTH)/1024 /1024 as SIZEMB 
FROM information_schema.tables 
GROUP BY TABLE_SCHEMA;

-- SERVER SIZE IN MB
SELECT 
	SUM(DATA_LENGTH)/1024 /1024 as TOTALSIZEMB 
FROM information_schema.tables;