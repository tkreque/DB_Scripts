SELECT
	CONCAT(
		'ALTER TABLE ',t1.TABLE_SCHEMA,'.',t1.TABLE_NAME,' ','ADD ',
			IF(	t1.NON_UNIQUE = 1,
				CASE UPPER(t1.INDEX_TYPE)
					WHEN 'FULLTEXT' THEN 'FULLTEXT INDEX'
					WHEN 'SPATIAL' THEN 'SPATIAL INDEX'
					ELSE CONCAT('INDEX ',t1.INDEX_NAME,' USING ',t1.INDEX_TYPE)
				END,
				IF(UPPER(t1.INDEX_NAME) = 'PRIMARY',
					CONCAT('PRIMARY KEY USING ',t1.INDEX_TYPE),
					CONCAT('UNIQUE INDEX ',t1.INDEX_NAME,' USING ',t1.INDEX_TYPE)
				)
			),'(',GROUP_CONCAT(	DISTINCT CONCAT('', t1.COLUMN_NAME, '') ORDER BY SEQ_IN_INDEX ASC SEPARATOR ', '),');'
	) AS 'Show_Add_Indexes'
FROM information_schema.STATISTICS t1
	INNER JOIN sys.schema_unused_indexes t2 ON t1.TABLE_NAME = t2.object_name AND t1.INDEX_NAME = t2.index_name
-- WHERE t1.TABLE_SCHEMA = 'analytics'
GROUP BY t1.TABLE_NAME, t1.INDEX_NAME
ORDER BY t1.TABLE_SCHEMA ASC, t1.TABLE_NAME ASC, t1.INDEX_NAME ASC;