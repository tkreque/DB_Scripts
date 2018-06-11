SET @schema := '%';		-- % for all schemas

SELECT
	CONCAT(
		'ALTER TABLE ',t1.TABLE_SCHEMA,'.',t1.TABLE_NAME,' ','DROP INDEX ',t1.INDEX_NAME,';'
	) AS 'Show_Drop_Indexes'
FROM information_schema.STATISTICS t1
	INNER JOIN sys.schema_unused_indexes t2 ON t1.TABLE_NAME = t2.object_name AND t1.INDEX_NAME = t2.index_name
WHERE t1.TABLE_SCHEMA LIKE @schema
GROUP BY t1.TABLE_NAME, t1.INDEX_NAME
ORDER BY t1.TABLE_SCHEMA ASC, t1.TABLE_NAME ASC, t1.INDEX_NAME ASC;