USE [msdb]
GO

/****** Object:  DatabaseRole [JobsViewer]    Script Date: 7/13/2016 1:43:52 PM ******/
CREATE ROLE [JobsViewer]
GO

EXEC sp_addrolemember 'SQLAgentOperatorRole','JobsViewer';
EXEC sp_addrolemember 'SQLAgentReaderRole','JobsViewer';
EXEC sp_addrolemember 'SQLAgentUserRole','JobsViewer';

DENY EXECUTE ON sp_add_job TO [JobsViewer];
DENY EXECUTE ON sp_add_jobschedule TO [JobsViewer];
DENY EXECUTE ON sp_add_jobserver TO [JobsViewer];
DENY EXECUTE ON sp_add_jobstep TO [JobsViewer];
DENY EXECUTE ON sp_delete_job TO [JobsViewer];
DENY EXECUTE ON sp_delete_jobschedule TO [JobsViewer];
DENY EXECUTE ON sp_delete_jobstep TO [JobsViewer];
DENY EXECUTE ON sp_update_job TO [JobsViewer];

GRANT EXECUTE ON sp_start_job TO [JobsViewer];
GRANT EXECUTE ON sp_stop_job TO [JobsViewer];
GRANT EXECUTE ON sp_help_job TO [JobsViewer];
GRANT EXECUTE ON sp_help_jobstep TO [JobsViewer];
