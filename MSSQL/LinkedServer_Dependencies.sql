/* 

Linked Server dependencies

------------------------ CHANGE LOG ------------------------
2017-12-23 - Thiago Reque
  - Adjustments for add in Github
*/


declare @lk varchar(100) = '%<LinkedServer>%', --- DEFINE LINKED SERVER HERE, MUST BE ON '%%'
	@sql varchar(max)


SELECT @sql='
USE [?];

SELECT DB_NAME(),
OBJECT_NAME(object_id), *
FROM sys.sql_modules
WHERE definition LIKE '''+@lk+'''
'
exec sp_MSforeachdb @sql

select * from msdb.dbo.sysjobsteps
where command like @lk
