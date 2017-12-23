use master
go


select * from [miojo] as p inner join [reque] as f on p.codigo = f.codigo
WHERE p.codigo like 65  
	OR    p.produto LIKE '%65%'
	OR    f.endereco LIKE '%65%'
	OR    f.numero LIKE 65
order by case when p.codigo = 65 then 9999 else p.codigo end desc, p.produto