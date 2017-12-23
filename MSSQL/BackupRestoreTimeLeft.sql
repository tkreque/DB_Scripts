/* 

Give the information of Backup/Restore current status and time left to complete.
This are estimations not precise information.

------------------------ CHANGE LOG ------------------------
2017-12-23 - Thiago Reque
  - Adjustments for add in Github
*/

USE [msdb]
SELECT  r.Session_ID
       ,r.Command
       ,DB_NAME(r.database_id) DBname
       ,CONVERT(NUMERIC(6,2), r.percent_complete) AS [Percent Complete]
       ,r.Wait_Type
       ,CONVERT(VARCHAR(20),DATEADD(ms,r.estimated_completion_time,GETDATE()),20) AS [ETA Completion TIME]
       ,CONVERT(NUMERIC(6,2),r.total_elapsed_time       /1000.0/60.0) AS [Elapsed MIN]       
       ,CONVERT(NUMERIC(6,2),r.estimated_completion_time/1000.0/60.0) AS [ETA MIN]           
       ,CONVERT(NUMERIC(6,2),r.estimated_completion_time/1000.0/60.0/60.0) AS [ETA Hours]         
       ,CONVERT(VARCHAR(100),(
          SELECT 
            SUBSTRING(text,r.statement_start_offset/2, CASE
               WHEN r.statement_end_offset = -1
               THEN 1000
               ELSE (r.statement_end_offset-r.statement_start_offset)/2
             END) 
          FROM    
            sys.dm_exec_sql_text(sql_handle)
          )
       ) AS [TextQuery]
FROM   
  sys.dm_exec_requests r
WHERE command IN (
   'RESTORE DATABASE'
  ,'BACKUP LOG'
  ,'RESTORE LOG'
  ,'BACKUP DATABASE'
  ,'RESTORE HEADERON'
  ,'DBCC TABLE CHECK'
)
GO