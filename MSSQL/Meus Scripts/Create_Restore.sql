select 
	database_id as id, 
	1 as priority,
	'
	RESTORE DATABASE ['+name+'] FROM DISK = ''\\bkp-dd01-mia.bkp.terra.com\backup-sqlserver2\MIG_04\'+name+'_MIG.BAK'' WITH
	' as sqltxt
from sys.databases
where name not in ('master','model','msdb','tempdb') and name not like 'TSML_%2012%'
union all 
select 
	dbid, 
	2,
	'
	MOVE '''+name+''' TO '''+filename+''',
	'
from sys.sysaltfiles 
where dbid in (
	select database_id 
	from sys.databases
	where name not in ('master','model','msdb','tempdb') and name not like 'TSML_%2012%'
) and fileid <> 2
union all
select 
	dbid, 
	3,
	'
	MOVE '''+name+''' TO '''+filename+''',
	'
from sys.sysaltfiles 
where dbid in (
	select database_id 
	from sys.databases
	where name not in ('master','model','msdb','tempdb') and name not like 'TSML_%2012%'
) and fileid = 2
union all
select 
	database_id, 
	4,
	'STATS = 5;' 
from sys.databases
where name not in ('master','model','msdb','tempdb') and name not like 'TSML_%2012%'
order by id,priority