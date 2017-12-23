/* 

Change the Maintenance Plan Owner.

------------------------ CHANGE LOG ------------------------
2017-12-23 - Thiago Reque
  - Adjustments for add in Github
*/


DECLARE  @Owner VARCHAR(100) = ''				---- DEFINE THE NEW OWNER FOR THE MAINTENANCE PLAN HERE
		,@MaintenanceName VARCHAR(1000) = ''		---- DEFINE THE MAINTENANCE PLAN NAME HERE


IF EXISTS (SELECT 1 FROM msdb.dbo.sysssispackages WHERE name = @MaintenanceName)
	UPDATE msdb.dbo.sysssispackages
		SET [ownersid] = ISNULL((SELECT sid FROM sys.syslogins WHERE name = @Owner),0x01)
	WHERE [name] = @MaintenanceName
ELSE
	PRINT 'No Maintenance Plan found with this Name, please check again!'
GO