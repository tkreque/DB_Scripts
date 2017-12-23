exec sp_MSforeachdb ' 
use [?]

if (''?''<>''tempdb'')
begin
exec (''alter database [?] set recovery simple'')
end
'