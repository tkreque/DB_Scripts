/* 

Check User permissions on database

------------------------ CHANGE LOG ------------------------
2017-12-23 - Thiago Reque
  - Adjustments for add in Github
*/


USE [<database>]
GO

EXECUTE AS USER = '<user>';
SELECT * FROM fn_my_permissions (NULL, 'DATABASE')
ORDER BY permission_name
GO