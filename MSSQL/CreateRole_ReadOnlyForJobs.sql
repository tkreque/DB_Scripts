/* 

Create a read only jobs role to add users.
They cannot perform any action in the jobs

------------------------ CHANGE LOG ------------------------
2017-12-23 - Thiago Reque
  - Adjustments for add in Github
*/

USE [msdb]
GO
CREATE ROLE [SQLAgentReadOnlyRole] AUTHORIZATION [dbo]
GO
EXEC sp_addrolemember N'SQLAgentReaderRole', N'SQLAgentReadOnlyRole'
GO
DENY EXECUTE ON OBJECT::msdb.dbo.sp_add_job TO SQLAgentReadOnlyRole
DENY EXECUTE ON OBJECT::msdb.dbo.sp_add_jobserver TO SQLAgentReadOnlyRole
DENY EXECUTE ON OBJECT::msdb.dbo.sp_add_jobstep TO SQLAgentReadOnlyRole
DENY EXECUTE ON OBJECT::msdb.dbo.sp_update_job TO SQLAgentReadOnlyRole
DENY EXECUTE ON OBJECT::msdb.dbo.sp_add_jobschedule TO SQLAgentReadOnlyRole