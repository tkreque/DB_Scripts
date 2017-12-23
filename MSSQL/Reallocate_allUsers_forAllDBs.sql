/* 

Script for reallocate all users to logins for all Databases.
Usefull after restores

------------------------ CHANGE LOG ------------------------
2017-12-23 - Thiago Reque
  - Adjustments for add in Github
*/



DECLARE @Collation VARCHAR (100)
DECLARE @SQL VARCHAR(2000)
SELECT @Collation =CONVERT(SYSNAME,DatabasePropertyEx('master','Collation'))
SET @SQL = 'USE [?]
  DECLARE @DBUserName varchar(50)
  DECLARE @SysLoginName varchar(50)
  DECLARE SyncDBLogins CURSOR FOR 
  
  SELECT A.name DBUserName,        
         B.loginname SysLoginName 
  FROM sysusers A      
       JOIN master.dbo.syslogins B      
         ON A.name Collate ' + @Collation + ' = B.Name       
       JOIN master.dbo.sysdatabases C      
         ON C.Name = ''?'' 
  WHERE issqluser = 1       
    AND (A.sid IS NOT NULL       
    AND A.sid <> 0x0)       
    AND suser_sname(A.sid) IS NULL       
    AND (C.status & 32) =0 --Loading       
    AND (C.status & 64) =0 --pre recovery       
    AND (C.status & 128) =0 --recovering       
    AND (C.status & 256) =0 --not recovered       
    AND (C.status & 512) =0 --offline       
    AND (C.status & 1024) =0 --read only 
  ORDER BY A.name

  OPEN SyncDBLogins
  FETCH NEXT FROM SyncDBLogins 
  INTO @DBUserName, @SysLoginName

  WHILE @@FETCH_STATUS = 0 
  BEGIN    
      EXEC sp_change_users_login ''update_one'', @DBUserName, @SysLoginName    
      
      FETCH NEXT FROM SyncDBLogins    
      INTO @DBUserName, 
           @SysLoginName 
  END

  CLOSE SyncDBLogins
  DEALLOCATE SyncDBLogins
'

EXEC sp_msforeachdb @SQL