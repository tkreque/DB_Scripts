/* 

SpWho2 with filters.

------------------------ CHANGE LOG ------------------------
2017-12-23 - Thiago Reque
  - Adjustments for add in Github
*/


CREATE TABLE #sessions_spwho
(SPID INT, 
Status VARCHAR(1000) NULL, 
Login SYSNAME NULL, 
HostName SYSNAME NULL, 
BlkBy SYSNAME NULL, 
DBName SYSNAME NULL, 
Command VARCHAR(1000) NULL, 
CPUTime INT NULL, 
DiskIO INT NULL, 
LastBatch VARCHAR(1000) NULL, 
ProgramName VARCHAR(1000) NULL, 
SPID2 INT,
RequestID INT)
GO

INSERT INTO #sessions_spwho
EXEC sp_who2
GO

SELECT *
FROM #sessions_spwho
WHERE
	DBName = '<database>'
ORDER BY LastBatch
GO

DROP TABLE #sessions_spwho
GO