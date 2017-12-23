/*----------------------------------------------------------*/
/*----------------------------------------------------------*/
/*			Script Criado para Sincronização de DBs			*/
/*		Por: Thiago Reque e Thiago Leite - ilegra			*/
/*----------------------------------------------------------*/
/*----------------------------------------------------------*/

/*
COMANDO PARA O CMD

sqlcmd -S "ILEGRA-NEW" -U "sa" -P "pass" -i "C:\SQL\DBSYNC.sql" -v DBORIGEM = "AdventureWorks2012" -v DBDESTINO = "AdventureWorks2012_HLG"
sqlcmd -S "ILEGRA-NEW" -E -i "C:\SQL\DBSYNC.sql" -v DBORIGEM = "AdventureWorks2012" -v DBDESTINO = "AdventureWorks2012_HLG"

*/

USE [$(DBDESTINO)]

SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON

IF OBJECT_ID('TEMPDB..##SCRIPT_DROP') IS NOT NULL
	  DROP TABLE ##SCRIPT_DROP

	IF OBJECT_ID('TEMPDB..##SCRIPT_TRUNCATE') IS NOT NULL
	  DROP TABLE ##SCRIPT_TRUNCATE

	IF OBJECT_ID('TEMPDB..##SCRIPT_INSERT') IS NOT NULL
	  DROP TABLE ##SCRIPT_INSERT

	IF OBJECT_ID('TEMPDB..##SCRIPT_CREATE') IS NOT NULL
	  DROP TABLE ##SCRIPT_CREATE

	CREATE TABLE ##SCRIPT_DROP(COMANDO VARCHAR(MAX))	
    CREATE TABLE ##SCRIPT_TRUNCATE(COMANDO VARCHAR(MAX))
	CREATE TABLE ##SCRIPT_INSERT(COMANDO VARCHAR(MAX))
    CREATE TABLE ##SCRIPT_CREATE(COMANDO VARCHAR(MAX))

	DECLARE @OBJ_SOURCE VARCHAR(MAX) 
	DECLARE @OBJ_DEST VARCHAR(MAX)
	DECLARE @SCH_OBJ_SOURCE VARCHAR(MAX) 
	DECLARE @SCH_OBJ_DEST VARCHAR(MAX)
	DECLARE @COL_SOURCE VARCHAR(MAX)
	DECLARE @COL_DEST VARCHAR(MAX)
	DECLARE @FK_NAME VARCHAR(MAX)
	DECLARE @CNSTISNOTTRUSTED INT
	DECLARE @CONTADOR INT
	
	DECLARE @CONTADOR_COLUNA INT
	DECLARE @AUX_COL_SOURCE VARCHAR(MAX)
	DECLARE @AUX_COL_DEST VARCHAR(MAX)
	DECLARE @AUX_OBJ_SOURCE VARCHAR(MAX) 
	DECLARE @AUX_OBJ_DEST VARCHAR(MAX)
	DECLARE @AUX_SCH_OBJ_SOURCE VARCHAR(MAX) 
	DECLARE @AUX_SCH_OBJ_DEST VARCHAR(MAX)
	DECLARE @AUX_FK_NAME VARCHAR(MAX)
	DECLARE @AUX_CNSTISNOTTRUSTED INT

	--// CURSOR DO INSERT
	DECLARE @INSERT_COLUMNS VARCHAR(MAX)
	DECLARE @SELECT_COLUMNS VARCHAR(MAX)
	DECLARE @TABLE_NAME VARCHAR(MAX)
	DECLARE @COLUMN_NAME VARCHAR(MAX)
	--//CURSOR DAS VIEWS
	DECLARE @VIEW_DEFINITION VARCHAR(MAX)
	DECLARE @VIEW_NAME VARCHAR(MAX)

	DECLARE @SQL VARCHAR(MAX)
	DECLARE @SQL_EXEC NVARCHAR(MAX)

	DECLARE CUR_FOREIGNKEY_DROP CURSOR READ_ONLY
	FOR SELECT DISTINCT OBJECT_SCHEMA_NAME(fky.fkeyid)+'].['+OBJECT_NAME(fky.fkeyid) AS OBJ_SOURCE, 
			   obj.name FK_NAME		
		FROM sys.sysforeignkeys fky
			 INNER JOIN sys.sysconstraints cons
				on fky.constid = cons.constid
			 INNER JOIN sys.sysobjects obj
				on obj.id = cons.constid
			 

	DECLARE CUR_FOREIGNKEY CURSOR READ_ONLY
	FOR SELECT OBJECT_SCHEMA_NAME(fky.fkeyid)+'].['+OBJECT_NAME(fky.fkeyid) AS OBJ_SOURCE, 
			   OBJECT_SCHEMA_NAME(fky.rkeyid)+'].['+OBJECT_NAME(fky.rkeyid) AS OBJ_DEST, 
			   cols.name COL_SOURCE,
			   cold.name COL_DEST,	
			   obj.name FK_NAME,
			   TOTAIS.CONTADOR, 
			   OBJECTPROPERTY(obj.id, 'CnstIsNotTrusted') AS CNSTISNOTTRUSTED
		FROM sys.sysforeignkeys fky
			 INNER JOIN sys.sysconstraints cons
				on fky.constid = cons.constid
			 INNER JOIN sys.syscolumns cols
				on cols.colid = fky.fkey
				and cols.id = fky.fkeyid
			 INNER JOIN sys.syscolumns cold
				on cold.colid = fky.rkey
				and cold.id = fky.rkeyid
			 INNER JOIN sys.sysobjects obj
				on obj.id = cons.constid
			 INNER JOIN (SELECT COUNT(1) CONTADOR, 
							   cons.constid 
						FROM sys.sysforeignkeys fky
							 INNER JOIN sys.sysconstraints cons
								on fky.constid = cons.constid
						GROUP BY cons.constid) as TOTAIS
				on TOTAIS.constid = cons.constid


	DECLARE CUR_INSERTED CURSOR READ_ONLY
	FOR SELECT '['+SCHEMA_NAME(schema_id)+'].['+name+']' AS TABLE_NAME
		FROM sys.tables
		
	DECLARE CUR_VIEW_DROP CURSOR READ_ONLY
	FOR SELECT '['+SCHEMA_NAME(schema_id)+'].['+name+']' AS VIEW_NAME
		FROM sys.views
	
	DECLARE CUR_VIEW_CREATE CURSOR READ_ONLY
	FOR SELECT md.definition
		FROM sys.views vw 
			INNER JOIN sys.sql_modules md
				ON vw.object_id = md.object_id

	---------------------------------------------------------------------------
	-----------------------------GERA SCRIPT DROP------------------------------
	---------------------------------------------------------------------------
	OPEN CUR_FOREIGNKEY_DROP

	FETCH NEXT FROM CUR_FOREIGNKEY_DROP
	INTO @OBJ_SOURCE,
		 @FK_NAME

	WHILE @@FETCH_STATUS = 0
	BEGIN             
		SET @SQL = 'ALTER TABLE [' + @OBJ_SOURCE + '] DROP CONSTRAINT [' + @FK_NAME + ']'

		INSERT INTO ##SCRIPT_DROP
		VALUES(@SQL)
		
		FETCH NEXT FROM CUR_FOREIGNKEY_DROP
		INTO @OBJ_SOURCE,		 
			 @FK_NAME

	END
	CLOSE CUR_FOREIGNKEY_DROP
	DEALLOCATE CUR_FOREIGNKEY_DROP

	OPEN CUR_VIEW_DROP

	FETCH NEXT FROM CUR_VIEW_DROP
	INTO @VIEW_NAME

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SQL = 'DROP VIEW '+@VIEW_NAME

		INSERT INTO ##SCRIPT_DROP
		VALUES(@SQL)

		FETCH NEXT FROM CUR_VIEW_DROP
		INTO @VIEW_NAME

	END
	CLOSE CUR_VIEW_DROP
	DEALLOCATE CUR_VIEW_DROP

	---------------------------------------------------------------------------
	----------------------------------TRUNCATE---------------------------------
	---------------------------------------------------------------------------
	INSERT INTO ##SCRIPT_TRUNCATE
	EXEC sp_msforeachtable 'SELECT ''TRUNCATE TABLE ?'''

	---------------------------------------------------------------------------
	-----------------------------------INSERT----------------------------------
	---------------------------------------------------------------------------
	OPEN CUR_INSERTED

	FETCH NEXT FROM CUR_INSERTED
	INTO @TABLE_NAME
	
	WHILE @@FETCH_STATUS = 0
	BEGIN

		DECLARE CUR_INSERTCOLUMNS CURSOR READ_ONLY
		FOR SELECT name AS COLUMN_NAME
		FROM sys.syscolumns WHERE id = OBJECT_ID(@TABLE_NAME)
		
		SET @INSERT_COLUMNS = ''
		SET @SELECT_COLUMNS = ''
		OPEN CUR_INSERTCOLUMNS

		FETCH NEXT FROM CUR_INSERTCOLUMNS 
		INTO @COLUMN_NAME

		WHILE @@FETCH_STATUS = 0
		BEGIN

			SELECT @INSERT_COLUMNS = @INSERT_COLUMNS+CONVERT(VARCHAR(MAX),('['+name+'],')) 
			FROM sys.syscolumns 
			WHERE name = @COLUMN_NAME 
			AND id = OBJECT_ID(@TABLE_NAME) AND iscomputed = 0

			SELECT @SELECT_COLUMNS = CASE WHEN xtype = 241 THEN
				@SELECT_COLUMNS+CONVERT(VARCHAR(MAX),('CONVERT (XML,['+name+']),')) 
			ELSE
				@SELECT_COLUMNS+CONVERT(VARCHAR(MAX),('['+name+'],')) 
			END
			FROM sys.syscolumns 
			WHERE name = @COLUMN_NAME 
			AND id = OBJECT_ID(@TABLE_NAME) AND iscomputed = 0
		
			FETCH NEXT FROM CUR_INSERTCOLUMNS 
			INTO @COLUMN_NAME

		END

		SET @SQL = ' 
			IF (select count(1) from sys.identity_columns where object_id = object_id('''+@TABLE_NAME+''')) > 0
			BEGIN
			SET IDENTITY_INSERT '+@TABLE_NAME+' ON;
			END

			INSERT INTO '+@TABLE_NAME+ ' ('+SUBSTRING(@INSERT_COLUMNS, 1, LEN(@INSERT_COLUMNS) -1)+') 
			SELECT '+SUBSTRING(@SELECT_COLUMNS, 1, LEN(@SELECT_COLUMNS) -1)+' FROM [$(DBORIGEM)].' +@TABLE_NAME+ ';
			
			IF (select count(1) from sys.identity_columns where object_id = object_id('''+@TABLE_NAME+''')) > 0
			BEGIN
			SET IDENTITY_INSERT '+@TABLE_NAME+' OFF;
			END'

		INSERT INTO ##SCRIPT_INSERT
		VALUES(@SQL)	

		CLOSE CUR_INSERTCOLUMNS
		DEALLOCATE CUR_INSERTCOLUMNS
				
		FETCH NEXT FROM CUR_INSERTED
		INTO @TABLE_NAME
	
	END
	
	CLOSE CUR_INSERTED
	DEALLOCATE CUR_INSERTED
	
	---------------------------------------------------------------------------
	-----------------------------GERA SCRIPT CREATE----------------------------
	---------------------------------------------------------------------------

	OPEN CUR_FOREIGNKEY

	FETCH NEXT FROM CUR_FOREIGNKEY
	INTO @OBJ_SOURCE,
		 @OBJ_DEST,
		 @COL_SOURCE, 
		 @COL_DEST, 
		 @FK_NAME,
		 @CONTADOR, 
		 @CNSTISNOTTRUSTED


	WHILE @@FETCH_STATUS = 0
	BEGIN             

		SET @CONTADOR_COLUNA = 1

		SET @AUX_OBJ_SOURCE = @OBJ_SOURCE
		SET @AUX_OBJ_DEST = @OBJ_DEST
		SET @AUX_FK_NAME = @FK_NAME
		SET @AUX_COL_SOURCE = '[' + @COL_SOURCE + ']'		
  		SET @AUX_COL_DEST = '[' + @COL_DEST + ']'	
		SET @AUX_CNSTISNOTTRUSTED = @CNSTISNOTTRUSTED		                    

		IF @CONTADOR > 1 
		BEGIN
		
			WHILE @CONTADOR_COLUNA < @CONTADOR
			BEGIN		
				FETCH NEXT FROM CUR_FOREIGNKEY
				INTO @OBJ_SOURCE,
					 @OBJ_DEST,
					 @COL_SOURCE, 
					 @COL_DEST, 
					 @FK_NAME,
					 @CONTADOR, 
					 @CNSTISNOTTRUSTED
				
  				SET @AUX_COL_SOURCE = @AUX_COL_SOURCE + ', ' + '[' + @COL_SOURCE + ']'				
  				SET @AUX_COL_DEST = @AUX_COL_DEST + ', ' + '[' + @COL_DEST + ']'			                    

				SET @CONTADOR_COLUNA = @CONTADOR_COLUNA + 1			
			END

		END


		FETCH NEXT FROM CUR_FOREIGNKEY
		INTO @OBJ_SOURCE,
			 @OBJ_DEST,
			 @COL_SOURCE, 
			 @COL_DEST, 
			 @FK_NAME,
			 @CONTADOR, 
			 @CNSTISNOTTRUSTED
		
		SET @SQL = 'ALTER TABLE [' + @AUX_OBJ_SOURCE + '] WITH '+ CASE WHEN @AUX_CNSTISNOTTRUSTED = 1 THEN ' NOCHECK ' ELSE ' CHECK ' END + 
				   ' ADD CONSTRAINT [' + @AUX_FK_NAME + ']' +
		 		   ' FOREIGN KEY(' + @AUX_COL_SOURCE + ') ' + 
				   ' REFERENCES [' + @AUX_OBJ_DEST + '](' + @AUX_COL_DEST +')' 

		INSERT INTO ##SCRIPT_CREATE 
		VALUES(@SQL)
	END
	
	CLOSE CUR_FOREIGNKEY
	DEALLOCATE CUR_FOREIGNKEY

	OPEN CUR_VIEW_CREATE

	FETCH NEXT FROM CUR_VIEW_CREATE
	INTO @VIEW_DEFINITION

	WHILE @@FETCH_STATUS = 0
	BEGIN

		INSERT INTO ##SCRIPT_CREATE
		VALUES(@VIEW_DEFINITION)

		FETCH NEXT FROM CUR_VIEW_CREATE
		INTO @VIEW_DEFINITION

	END
	CLOSE CUR_VIEW_CREATE
	DEALLOCATE CUR_VIEW_CREATE
	
	---------------------------------------------------------------------------
	-----------------------------EXECUTAR COMANDOS-----------------------------
	---------------------------------------------------------------------------
	
	BEGIN TRAN
	
	DECLARE CUR_EXEC_DROP CURSOR READ_ONLY
	FOR SELECT COMANDO FROM ##SCRIPT_DROP

	OPEN CUR_EXEC_DROP

	FETCH NEXT FROM CUR_EXEC_DROP 
	INTO @SQL_EXEC
		
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC sp_executesql @SQL_EXEC

		FETCH NEXT FROM CUR_EXEC_DROP
		INTO @SQL_EXEC
	END

	CLOSE CUR_EXEC_DROP
	DEALLOCATE CUR_EXEC_DROP

	DECLARE CUR_EXEC_TRUNC CURSOR READ_ONLY
	FOR SELECT COMANDO FROM ##SCRIPT_TRUNCATE

	OPEN CUR_EXEC_TRUNC

	FETCH NEXT FROM CUR_EXEC_TRUNC
	INTO @SQL_EXEC
		
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC sp_executesql @SQL_EXEC

		FETCH NEXT FROM CUR_EXEC_TRUNC
		INTO @SQL_EXEC
	END

	CLOSE CUR_EXEC_TRUNC
	DEALLOCATE CUR_EXEC_TRUNC

	DECLARE CUR_EXEC_INS CURSOR READ_ONLY
	FOR SELECT COMANDO FROM ##SCRIPT_INSERT

	OPEN CUR_EXEC_INS

	FETCH NEXT FROM CUR_EXEC_INS
	INTO @SQL_EXEC
		
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC sp_executesql @SQL_EXEC

		FETCH NEXT FROM CUR_EXEC_INS
		INTO @SQL_EXEC
	END

	CLOSE CUR_EXEC_INS
	DEALLOCATE CUR_EXEC_INS

	DECLARE CUR_EXEC_CREATE CURSOR READ_ONLY
	FOR SELECT COMANDO FROM ##SCRIPT_CREATE

	OPEN CUR_EXEC_CREATE

	FETCH NEXT FROM CUR_EXEC_CREATE
	INTO @SQL_EXEC
		
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC sp_executesql @SQL_EXEC
				
		FETCH NEXT FROM CUR_EXEC_CREATE
		INTO @SQL_EXEC
	END

	CLOSE CUR_EXEC_CREATE
	DEALLOCATE CUR_EXEC_CREATE

	COMMIT
