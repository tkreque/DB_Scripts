use db_name  --- Passar a DB
go

set nocount on

select 'RESTORE DATABASE ['+DB_NAME()+'] FROM DISK = ''C:\sql\'+db_name()+'.bak'' WITH' --- Ajustar o caminho do BKP
union all
select 
	case fileid 
	when 1 then	'MOVE '''+name+''' TO ''H:\MSSQL10.MSSQLSERVER\MSSQL\DATA\'+name+'.mdf'',' --- Ajustar o caminho dos MDFs e NDFs
	else 'MOVE '''+name+''' TO ''H:\MSSQL10.MSSQLSERVER\MSSQL\DATA\'+name+'.ndf'',' --- Ajustar o caminho dos MDFs e NDFs
	end
from sys.sysfiles
where name not like '%log%'
union all
select 'MOVE '''+name+''' TO ''L:\MSSQL10.MSSQLSERVER\MSSQL\Data\'+name+'.ldf'',' --- Ajustar o caminho dos LDFs
from sys.sysfiles
where name like '%log%'
union all
select 'STATS = 10'
