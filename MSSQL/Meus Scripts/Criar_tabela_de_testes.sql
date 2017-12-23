use REQUE
go

create table teste (
	ID int identity,
	Varb int
	)
	
declare @cont int = 1	
while 1=1
begin
	insert into teste (Varb)
	values (@cont*2)
	
	set @cont=@cont+1
end

select COUNT(*) from teste
	