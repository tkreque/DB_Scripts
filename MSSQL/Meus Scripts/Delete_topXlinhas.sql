
begin tran

declare @rows int

select @rows=COUNT(*) from <tabela>
where <coluna> not in (
		select top(<valor>) <coluna> from <tabela>
		order by <coluna> desc)

while @rows>0
begin
	delete top(100) from <tabela>
	where <coluna> not in (
		select top(<valor>) <coluna> from <tabela>
		order by <coluna> desc)
	
	select @rows=COUNT(*) from <tabela>
	where <coluna> not in (
		select top(<valor>) <coluna> from <tabela>
		order by <coluna> desc)
end

select * from <tabela>

commit tran

