USE DBA
go

DECLARE @sql VARCHAR (max), @DBs VARCHAR (MAX),
		@dataInicio VARCHAR(20), @dataFim VARCHAR(20),
		@diaFim INT, @Cols VARCHAR(MAX)

SET @DBs = ''

SELECT @DBs = @DBs + QUOTENAME(name)+ ','
FROM sys.databases
WHERE name NOT IN ('DBA', 'master', 'msdb', 'model')
ORDER BY name

SET @DBs = LEFT(@DBs, LEN(@DBs)-1)

SET @Cols = 'DATA, '

SELECT @Cols = @Cols + 'REPLACE (CONVERT (VARCHAR, ' + QUOTENAME(name)+ '), ''.'', '','')' + QUOTENAME(name)+ ','
FROM sys.databases
WHERE name NOT IN ('DBA', 'master', 'msdb', 'model')
ORDER BY name

SET @Cols = LEFT(@Cols, LEN(@Cols)-1)

SELECT @dataInicio = LEFT(CONVERT(VARCHAR, DATEADD(month, -1, GETDATE()), 112), 6) + '01'

SET @diaFim = 31

WHILE @diaFim > 0
BEGIN
	SET @dataFim = LEFT(CONVERT(VARCHAR, DATEADD(month, -1, GETDATE()), 112), 6) + RIGHT('0'+CONVERT(VARCHAR, @diaFim), 2) + ' 23:59'
	IF ISDATE(@dataFim) = 1
		SET @diaFim = 0
	ELSE
		SET @diaFim = @diaFim - 1
END

SET @sql = 
'SELECT ' + @Cols + '
FROM (
	SELECT 
		CONVERT (VARCHAR, data, 103) DATA, 
		DATABASENAME, 
		FILESIZEMB
	FROM dbo.DBA_INFO_DATABASE
	WHERE 
	data BETWEEN ''' + @dataInicio + ''' AND ''' + @dataFim + ''' AND 
	PHYSICALFILENAME NOT LIKE ''%.log''
) AS tmp
PIVOT (
	SUM (FILESIZEMB)
	FOR DATABASENAME IN(' + @DBs + ')
) PivotTable'

EXECUTE (@sql)