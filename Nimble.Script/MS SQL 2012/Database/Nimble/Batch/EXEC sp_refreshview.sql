DECLARE @views TABLE 
(
	[Index]	INT,
	[Name]	NVARCHAR(MAX)
);

DECLARE 
	@index	INT,
	@count	INT,
	@name	NVARCHAR(MAX);

INSERT @views 
SELECT 
	ROW_NUMBER() OVER (ORDER BY S.[name], SO.[name])	[Index],
	'[' + S.[name] + '].[' + SO.[name] + ']'			[Name]
FROM [sys].[objects]		SO 
INNER JOIN [sys].[schemas]	S	ON	SO.[schema_id]	= S.[schema_id]
WHERE SO.[type] = 'V';

SELECT 
	@index	= 1,
	@count	= @@ROWCOUNT;

/*
SELECT * FROM @views;

SELECT 
	@index,
	@count;
*/

WHILE (@index <= @count) BEGIN
	SELECT @name = V.[Name] FROM @views V WHERE V.[Index] = @index;
	EXEC sp_refreshview @viewname = @name;
	SET @index = @index + 1;
END


/*
SELECT
    DISTINCT 'EXEC sp_refreshview @viewname = ''[' + S.[name] + '].[' + SO.[name] + ']'';'
FROM 
    [sys].[objects] SO 
    INNER JOIN [sys].[schemas] S
        ON SO.[schema_id] = S.[schema_id]
    INNER JOIN [sys].[sql_expression_dependencies] SED 
        ON SO.[object_id] = SED.[referencing_id]
WHERE SO.[type] = 'V';
*/

/*
EXEC sp_refreshview @viewname = '[Security].[Entity.User]';
EXEC sp_refreshview @viewname = '[Security].[Entity.Account]';
EXEC sp_refreshview @viewname = '[Security].[Entity.Log]';
EXEC sp_refreshview @viewname = '[Security].[Entity.Permission]';
EXEC sp_refreshview @viewname = '[Security].[Entity.Role]';

EXEC sp_refreshview @viewname = '[Multilanguage].[Entity.Culture]';
EXEC sp_refreshview @viewname = '[Multilanguage].[Entity.Resource]';
EXEC sp_refreshview @viewname = '[Multilanguage].[Entity.Translation]';

EXEC sp_refreshview @viewname = '[Maintenance].[Entity.Operation]';

EXEC sp_refreshview @viewname = '[Owner].[Entity.Person]';
EXEC sp_refreshview @viewname = '[Owner].[Entity.Organisation]';
EXEC sp_refreshview @viewname = '[Owner].[Entity.Employee]';
EXEC sp_refreshview @viewname = '[Owner].[Entity.Branch]';
EXEC sp_refreshview @viewname = '[Owner].[Entity.Range]';

EXEC sp_refreshview @viewname = '[Multicurrency].[Entity.Currency]';
EXEC sp_refreshview @viewname = '[Multicurrency].[Entity.Trade]';
EXEC sp_refreshview @viewname = '[Multicurrency].[Entity.Rate]';

EXEC sp_refreshview @viewname = '[Common].[Entity.Split]';
EXEC sp_refreshview @viewname = '[Common].[Entity.Group]';
EXEC sp_refreshview @viewname = '[Common].[Entity.Preset]';
EXEC sp_refreshview @viewname = '[Common].[Entity.Filestream]';
*/