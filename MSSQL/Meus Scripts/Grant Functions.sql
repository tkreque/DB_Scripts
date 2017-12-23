SET NOCOUNT ON

DECLARE @NOME VARCHAR(256) = 'USER'

select 'GRANT EXECUTE ON '+name+' TO ['+@NOME+'];' from integra_onixsat.sys.objects
where type_desc like '%FUNCTION%' AND type NOT IN ('TF','FT','IF')

select 'GRANT SELECT ON '+name+' TO ['+@NOME+'];' from integra_onixsat.sys.objects
where type_desc like '%FUNCTION%' AND type IN ('TF','FT','IF')

select 'GRANT EXECUTE ON '+name+' TO ['+@NOME+'];' from omnilink.sys.objects
where type_desc like '%FUNCTION%' AND type NOT IN ('TF','FT','IF')

select 'GRANT SELECT ON '+name+' TO ['+@NOME+'];' from omnilink.sys.objects
where type_desc like '%FUNCTION%' AND type IN ('TF','FT','IF')

select 'GRANT EXECUTE ON '+name+' TO ['+@NOME+'];' from Integra.sys.objects
where type_desc like '%FUNCTION%' AND type NOT IN ('TF','FT','IF')

select 'GRANT SELECT ON '+name+' TO ['+@NOME+'];' from Integra.sys.objects
where type_desc like '%FUNCTION%' AND type IN ('TF','FT','IF')
