use msdb
go

declare @sql nvarchar(max) = '';

select @sql += N'exec msdb.dbo.sp_update_job @job_name = ''' + name + N''', @enabled = 0;' 
from msdb.dbo.sysjobs
where name in (
	'',
	''
);

exec (@sql);

