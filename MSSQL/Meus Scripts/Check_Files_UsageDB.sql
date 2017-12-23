SELECT 
	dbname AS [DATABASE NAME],
	name AS [FILE NAME],
	(size*8)/1024 AS [FILE SIZE IN MB],
	(maxsize*8)/1024 AS [MAX FILE SIZE IN MB],
	(spaceUsed*8)/1024 AS [USED FILE SIZE IN MB],
	(spaceFree*8)/1024 AS [FREE FILE SIZE IN MB],
	CONVERT(VARCHAR(10),CONVERT(NUMERIC(15,2),((spaceUsed*100)/size)))+'%' AS [PERCENT USED SPACE],
	CONVERT(VARCHAR(10),CONVERT(NUMERIC(15,2),((spaceFree*100)/size)))+'%' AS [PERCENT FREE SPACE],
	CONVERT(VARCHAR(10),CONVERT(NUMERIC(15,2),(((maxsize-size)*100)/maxsize)))+'%' AS [PERCENT TO REACH MAXSIZE]
FROM (
	SELECT 
		DB_NAME() as dbname, 
		name, 
		size, 
		maxsize,
		FILEPROPERTY(name,'SpaceUsed') as spaceUsed,
		size-FILEPROPERTY(name,'SpaceUsed') as spaceFree
	FROM sys.sysfiles
) T1
