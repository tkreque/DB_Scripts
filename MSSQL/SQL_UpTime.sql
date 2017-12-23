/* 

Get the uptime for the SQL Server instance and SQL Server Agent

------------------------ CHANGE LOG ------------------------
2017-12-23 - Thiago Reque
  - Adjustments for add in Github
*/


USE MASTER
GO

SET NOCOUNT ON

DECLARE @crdate DATETIME, 
		@hr VARCHAR(50), 
		@min VARCHAR(5)

SELECT @crdate=crdate FROM sysdatabases WHERE NAME='tempdb'

SELECT @hr=(DATEDIFF ( mi, @crdate,GETDATE()))/60
	
	IF ((DATEDIFF ( mi, @crdate,GETDATE()))/60)=0
		SELECT @min=(DATEDIFF ( mi, @crdate,GETDATE()))
	ELSE
		SELECT @min=(DATEDIFF ( mi, @crdate,GETDATE()))-((DATEDIFF( mi, @crdate,GETDATE()))/60)*60

PRINT 'SQL Server "' + CONVERT(VARCHAR(20),SERVERPROPERTY('SERVERNAME'))+'" is Online for the past '+@hr+' hours & '+@min+' minutes'

IF NOT EXISTS (SELECT 1 FROM master.dbo.sysprocesses WHERE program_name = N'SQLAgent - Generic Refresher')
	PRINT 'SQL Server is running but SQL Server Agent <<NOT>> running'
ELSE
	PRINT 'SQL Server and SQL Server Agent both are running'


 