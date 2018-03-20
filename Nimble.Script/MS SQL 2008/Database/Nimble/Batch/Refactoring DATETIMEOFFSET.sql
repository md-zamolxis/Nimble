SET NOCOUNT ON;

DECLARE @dateTimeColumns TABLE (
	[Index]			INT				IDENTITY(1, 1),
	[SchemaName]	NVARCHAR(MAX),
	[TableName]		NVARCHAR(MAX),
	[ColumnIndex]	INT,
	[ColumnName]	NVARCHAR(MAX)
);

DECLARE @dateTimeTables TABLE (
	[Index]			INT				IDENTITY(1, 1),
	[SchemaName]	NVARCHAR(MAX),
	[TableName]		NVARCHAR(MAX)
);

INSERT @dateTimeColumns
SELECT 
	--*,
	S.[name],
	O.[name],
	C.[column_id],
	C.[name]
FROM [sys].[columns] C
INNER JOIN [sys].[objects] O ON C.[object_id] = O.[object_id]
INNER JOIN [sys].[schemas] S ON O.[schema_id] = S.[schema_id]
WHERE 
		C.[system_type_id] = 61 -- DATETIME
		--C.[system_type_id] = 43 -- DATETIMEOFFSET
	AND	O.[type] = 'U'
ORDER BY 
	S.[name],
	O.[name],
	C.[column_id];

--SELECT * FROM @dateTimeColumns X;

INSERT @dateTimeTables
SELECT DISTINCT
	X.[SchemaName],
	X.[TableName]
FROM @dateTimeColumns X
ORDER BY 
	X.[SchemaName],
	X.[TableName]

--SELECT * FROM @dateTimeTables X;

DECLARE 
	@offsetMinutes	NVARCHAR(MAX)	= '120',
	@schemaName		NVARCHAR(MAX),
	@tableName		NVARCHAR(MAX),
	@command		NVARCHAR(MAX),
	@index			INT				= 1,
	@count			INT				= @@ROWCOUNT;

--SELECT @count;

WHILE (@index <= @count) BEGIN
	SELECT 
		@schemaName	= X.[SchemaName],
		@tableName	= X.[TableName],
		@command	= ''
	FROM @dateTimeTables X
	WHERE X.[Index] = @index;
	SELECT
		--@command = 'ALTER TABLE [' + X.[SchemaName] + '].[' + X.[TableName] + '] ALTER COLUMN [' + X.[ColumnName] + '] DATETIMEOFFSET;'
		@command += 'X.[' + X.[ColumnName] + '] = SWITCHOFFSET(X.[' + X.[ColumnName] + '], ' + @offsetMinutes + '), '
	FROM @dateTimeColumns X
	WHERE 
		X.[SchemaName]	= @schemaName	AND
		X.[TableName]	= @tableName;
	SET @command = 'UPDATE X SET ' + SUBSTRING(@command, 1, LEN(@command) - 1) + ' FROM [' + @schemaName + '].[' + @tableName + '] X;'
	PRINT @command;
	--EXEC @command;
	SET @index = @index + 1;
END;
