create procedure usp_delLogin
	@LoginName varchar(100)
as
begin

declare @cont int = 1,
	@sql varchar(max),
	@name varchar(max),
	@text varchar(max),
	@db varchar(max)

	
create table #users ( 
	id int identity,
	name varchar (max), 
	databasename varchar(max)
)

select @text='use ?;insert into #users (name,databasename) select name,DB_NAME() from sys.sysusers where sid = (select sid from sys.syslogins where name = '''+@loginname+''')'

exec sp_MSforeachdb @text

select databasename as [Database Name who had the user] from #users

while @cont < (select COUNT(*)+1 from #users)
begin
	select @db=databasename from #users where id=@cont
	select @name=name from #users where id=@cont
	execute('use '+@db+'; drop user '+@name)
	set @cont=@cont+1
end

exec ('drop login '+@loginname)

drop table #users
end

