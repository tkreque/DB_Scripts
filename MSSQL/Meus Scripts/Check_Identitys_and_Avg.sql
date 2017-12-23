use DBA
go

SELECT *
FROM DBA.dbo.DBA_SNAP_IDENTITY 
WHERE -- Threshold para Warning --
	(typename = 'bigint' AND remaining_value < 5000000000) OR
	(typename = 'int' AND remaining_value < 100000000) OR 
	(typename = 'smallint' AND remaining_value < 10000 ) OR
	(typename = 'tinyint' AND remaining_value < 50 ) 

---- MEDIA CRES----	
select sum(rem_values)/31 from (
select (d2.remaining_value-D1.remaining_value) as rem_values from 
(
	SELECT data, dbname, tbname, colname, remaining_value,typename
	FROM DBA.dbo.DBA_SNAP_IDENTITY 
) as D1 inner join (
	SELECT data, dbname, tbname, colname, remaining_value,typename
	FROM DBA.dbo.DBA_SNAP_IDENTITY 
) as D2 ON
	convert(datetime,d1.data) = convert(datetime,d2.data)+1 and
	d1.dbname = d2.dbname and
	d1.tbname = d2.tbname and
	d1.colname = d2.colname
WHERE d1.Dbname = 'omnilink' and d1.tbname = 'TB_POSICAO_EVENTO_INTEGRA' and d1.colname = 'CD_POSICAO_EVENTO'
	and d1.data >= '2013-03-02'
) t1

---- MEDIA DIAS ----
declare @media int = 2052845

SELECT (remaining_value/@media) as dias
FROM DBA.dbo.DBA_SNAP_IDENTITY d1
WHERE d1.Dbname = 'omnilink' and d1.tbname = 'TB_POSICAO_EVENTO_INTEGRA' and d1.colname = 'CD_POSICAO_EVENTO'
	and d1.data = '2013-04-02'

