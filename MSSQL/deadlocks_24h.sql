use dba
go


select count(*) as 'N� em 24h' 
from (
	select distinct data 
	from dba_consultadeadlocks
	where data >= getdate()-1
		--and login='KNIJNIK\srv.farmadmin'
) as t