---- Get all users with db_owner permission
declare @sql varchar(max)
create table #dba_dbowner (dbname varchar(100),dbrole varchar(20),membername varchar(200),membersid varchar(max))

select @sql='
use [?]
insert into #dba_dbowner (dbrole,membername,membersid)
exec sp_helprolemember ''db_owner''
update #dba_dbowner set dbname = ''?'' where dbname IS NULL
'

exec sp_MSforeachdb @sql

select * from #dba_dbowner   ---- FILTER WHAT YOU NEED

drop table #dba_dbowner

---- GIVE PERMISSION FOR MULTIPLE DATABASES FOR 1 USER
declare @db varchar(20), @sql varchar(max)

DECLARE c CURSOR FOR 
SELECT name from sys.databases where name in ()  ---- ADD ALL DBS NEEDED

OPEN c

FETCH NEXT FROM c 
INTO @db

WHILE @@FETCH_STATUS = 0
BEGIN
	
	---- CHANGE THE LOGIN AND USER
	select @sql = '
	USE ['+@db+']
	CREATE USER [xxx] FOR LOGIN [xxx]
	exec sp_addrolemember ''db_owner'',''xxx''
	'

	exec @sql

    FETCH NEXT FROM c 
    INTO @db

END 
CLOSE c;
DEALLOCATE c;
