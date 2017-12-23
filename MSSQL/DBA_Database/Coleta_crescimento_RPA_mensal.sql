use dba
go

declare @dataInicio varchar(20), @dataFim varchar(20),@diaFim int

select @dataInicio = left(convert(varchar, dateadd(month, -1, getdate()), 112), 6) + '01'

set @diaFim = 31

while @diaFim > 0
begin
	set @dataFim = left(convert(varchar, dateadd(month, -1, getdate()), 112), 6) + right('0'+convert(varchar, @diaFim), 2)
	if isdate(@dataFim) = 1
		set @diaFim = 0
	else
		set @diaFim = @diaFim - 1
end

select 
	me.data as 'Data', 
	me.alocado as 'Alocado (MB)',
	me.usado as 'Usado (MB)',
	crescimento as 'Crescimento (MB)'
from (
		SELECT 
			me.data,
			sum(filesizemb) as usado
			sum(filesizemb) - sum(freespacemb) as alocado
		FROM DBA.dbo.DBA_INFO_DATABASE me
		GROUP BY me.data
	 ) as me
inner join 
	(
		SELECT
			ne.data,
			ne.(
where data between @dataInicio and @dataFim
order by 1