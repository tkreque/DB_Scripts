use dba
go

select 
	data, 
	alocado,
	usado,
	crescimento
from (
		SELECT 
			me.data,
			sum(filesizemb) as alocado,
			sum(freespacemb) as usado, 
			sum(filesizemb) - sum(freespacemb) as crescimento 
		FROM DBA.dbo.DBA_INFO_DATABASE me
		GROUP BY me.data
	 ) as me
order by 1