/* 

Kill blockers for a SESSION ID

------------------------ CHANGE LOG ------------------------
2017-12-23 - Thiago Reque
  - Adjustments for add in Github
*/

declare  @kill varchar (max) = ''
		,@spid int = 1 				--- DEFINE SESSION ID HERE

select @kill = @kill + 'kill ' + CONVERT (varchar(10), blocking_session_id) + ';' 
from sys.dm_os_waiting_tasks
where session_id = @SPID

-- PRINT (@kill)	--- SHOW KILL COMMAND
EXEC (@kill)		--- EXECUTE KILL COMMAND
