/* 

Get the identity current value and max values. 

------------------------ CHANGE LOG ------------------------
2017-12-23 - Thiago Reque
  - Adjustments for add in Github
*/

select DATA,DBNAME,OBJECT_ID,TBNAME,COLNAME,TYPENAME,LAST_VALUE,MAX_VALUE,max_value-last_value as remaining from (
SELECT 
	CONVERT(DATE,GETDATE()) AS data,
	DB_NAME() as dbname,
	obj.object_id, 
	obj.name AS tbname, 
	ident.name AS colname,
	types.name AS typename,
	CONVERT(BIGINT, ident.last_value) AS last_value,
	CONVERT(BIGINT, CASE types.name 
		WHEN 'int' THEN 2147483647
		WHEN 'bigint' THEN 9223372036854775807
		WHEN 'smallint' THEN 32767
		WHEN 'tinyint' THEN 255
	END ) AS max_value
FROM sys.identity_columns ident 
	INNER JOIN sys.all_objects obj 
		ON ident.object_id = obj.object_id
	INNER JOIN sys.systypes types
		ON types.xtype = ident.system_type_id
WHERE obj.type_desc = 'USER_TABLE' AND ident.last_value IS NOT NULL AND db_name() NOT IN ('master','model','msdb','tempdb')) t1