--select * 
--from sys.objects
----where object_id = 7671075
----select * 
----from sys.tables

--SELECT * 
--FROM sys.sql_expression_dependencies 

DROP VIEW [dbo].[DEPENDENCIES]
GO

CREATE VIEW [dbo].[DEPENDENCIES] 
WITH VIEW_METADATA
AS
SELECT 
	dp.referencing_id AS [ObjectID],
	CONVERT(VARCHAR(50),OBJECT_NAME(dp.referencing_id)) AS [ObjectName],
	SCHEMA_NAME(ob.SCHEMA_ID) AS [ObjectSchema],
	ob.type_desc AS [ObjetcType],
	dp.referenced_clASs_desc AS [ReferenceDescription],
	dp.referenced_id AS [RelativeID],
	dp.referenced_entity_name AS [RelativeName],
	dp.referenced_schema_name AS [RelativeSchema],
	(
		SELECT TOP 1 type_desc FROM sys.objects
		WHERE OBJECT_ID = dp.referenced_id
	) AS [RelativeType]
FROM sys.sql_expression_dependencies AS dp
	INNER JOIN sys.objects AS ob
		ON dp.referencing_id = ob.OBJECT_ID
GO

SELECT * FROM DEPENDENCIES
WHERE RelativeName='Person'


----
-- Aplicado na Apisul --

--DROP VIEW [vDependencies]
--GO

CREATE VIEW [vDependencies] AS
SELECT DISTINCT 
	DependentObj.name AS [DependentObj], 
	DependentObj.Type_desc AS [DependentObjType],  
	ReferencedObj.name AS [ReferencedObj], 
	ReferencedObj.Type_desc AS [ReferencedObjType]
FROM sys.sql_dependencies AS D
    JOIN sys.objects AS ReferencedObj
        ON ReferencedObj.object_id = D.referenced_major_id 
    JOIN sys.objects AS DependentObj
        ON DependentObj.object_id = D.object_id 
GO

CREATE PROCEDURE usp_ViewReferences (
    @Objname varchar(50)
) AS
	SELECT * FROM vDependencies
    WHERE [ReferencedObj] = @Objname
GO
CREATE PROCEDURE usp_ViewDependences (
    @Objname varchar(50)
) AS
	SELECT * FROM vDependencies
    WHERE [DependentObj] = @Objname
GO


EXEC usp_ViewDependences 'ALTERA_PP'
GO
EXEC usp_ViewReferences 'ALTERA_PP'
GO