/* 
------------------------ CHANGE LOG ------------------------
03/04/2011 - Thiago Reque
	- Criação da auditoria.SQL
*/

PRINT '----- Relatório de Auditoria de segurança : '+convert(varchar(15),getdate(),103)+' -----'
PRINT '-------------------------------------------------------------------------------------------'
PRINT ''

USE master
GO

DECLARE @texto VARCHAR (MAX)

SET @texto = '
SET NOCOUNT ON

-- Cria a tabela temporária
CREATE TABLE #RoleMember
	(RoleName VARCHAR(30),
	UserName VARCHAR(60),
	UserSid VARCHAR(MAX)
	)

EXEC sp_MSforeachdb ''	
INSERT INTO #RoleMember
EXEC sp_helpsrvrolemember
''

PRINT ''------ Usuários com permissões de Admin ------''
SELECT DISTINCT RoleName,UserName 
FROM #RoleMember 
WHERE UserName IN (
	SELECT name 
	FROM sys.server_principals 
	WHERE type IN (''S'',''U'',''G'')
)
AND RoleName IN (''serveradmin'',''sysadmin'')

PRINT ''------ Usuários sem a politica de senhas habilitada ------''
SELECT CONVERT(varchar(30),name) as UserName,
	CONVERT(varchar(15),type_desc) as TipoLogin,
	create_date as DataCriado,
	modify_date as DataModificado 
FROM sys.sql_logins 
WHERE is_policy_checked=0 and is_expiration_checked=0

PRINT ''''
PRINT ''------ Falhas de Login dos usuários administradores ------''
SELECT 	CONVERT (VARCHAR(2), DATEPART(DD,DATA)) + ''/'' +
		CONVERT (VARCHAR(2), DATEPART(MM,DATA)) + ''/'' +
		CONVERT (VARCHAR(4), DATEPART(YYYY,DATA)) AS Data,
		CONVERT(VARCHAR(30),LOGIN) AS UserName 
FROM DBA.dbo.DBA_CONSULTALOGINFAIL
WHERE LOGIN IN (
	SELECT DISTINCT UserName 
	FROM #RoleMember 
	WHERE UserName IN (
		SELECT DISTINCT name 
		FROM sys.server_principals 
		WHERE type IN (''S'')
	)
	AND RoleName IN (''serveradmin'',''sysadmin'')
)
AND DATA BETWEEN GETDATE() - 1 AND GETDATE()

PRINT ''''
PRINT ''------ Alterações realizadas por usuários administradores ------''
SELECT CONVERT(VARCHAR(30),DATABASENAME) AS DatabaseName,
	CONVERT(VARCHAR(30),LOGINNAME) AS UserName,
	CONVERT (VARCHAR(2), DATEPART(DD,DATA_ALTERACAO)) + ''/'' +
	CONVERT (VARCHAR(2), DATEPART(MM,DATA_ALTERACAO)) + ''/'' +
	CONVERT (VARCHAR(4), DATEPART(YYYY,DATA_ALTERACAO)) AS DataAlteracao,
	CONVERT(VARCHAR(50),SCRIPT) AS Instrucao 
FROM DBA.dbo.DBA_HISTORICOALTERACOES 
WHERE LOGINNAME IN (
	SELECT DISTINCT UserName 
	FROM #RoleMember 
	WHERE UserName IN (
		SELECT DISTINCT name 
		FROM sys.server_principals 
		WHERE type IN (''S'')
	)
	AND RoleName IN (''serveradmin'',''sysadmin'')
)
AND DATA_ALTERACAO BETWEEN GETDATE() - 1 AND GETDATE()

PRINT ''''
PRINT ''------ Servidor com acesso externo ------''
PRINT ''Executar o seguinte comando no CMD da sua máquina e postar o resultado aqui''
PRINT ''telnet <ip_externo> <porta_banco(default_is_1433)>''

PRINT ''''
PRINT ''------ Versão atual do sistema ------''
SELECT CONVERT (VARCHAR(40),SERVERPROPERTY (''edition'')) AS Edicao, 
	CONVERT (VARCHAR(8),SERVERPROPERTY (''productlevel'')) AS Versao,
	CONVERT (VARCHAR(15),SERVERPROPERTY(''productversion'')) AS NumeroVersao

DROP TABLE #RoleMember

PRINT ''''
PRINT ''''
PRINT ''-------------------------------------------------------------------------------------------''
PRINT ''Relatório Finalizado''
PRINT ''Encaminhar o ticket para o Account Manager do cliente''
'

exec (@texto)