DECLARE 
	 @tableSchema	NVARCHAR(MAX)
	,@tableName		NVARCHAR(MAX)
	,@objectName	NVARCHAR(MAX)
	,@tableType		NVARCHAR(MAX)	= 'BASE TABLE'
	,@measureUnit	NVARCHAR(MAX)	= ' KB'
	,@execCommand	NVARCHAR(MAX)	= 'EXEC sp_spaceused @objname = '''
	,@totalName		NVARCHAR(MAX)	= 'Total, GB'
	,@measureValue	MONEY			= 1024*1024;

DECLARE @spaceUsed TABLE 
(
	 [Name]     NVARCHAR(MAX)
	,[Rows]     NVARCHAR(MAX)
	,[Reserved]	NVARCHAR(MAX)
	,[Data]     NVARCHAR(MAX)
	,[Index]    NVARCHAR(MAX)
	,[Unused]   NVARCHAR(MAX)
);

DECLARE @tableSpaces TABLE 
(
	 [Name]     NVARCHAR(MAX)
	,[Columns]	BIGINT
	,[Rows]     BIGINT
	,[Reserved] MONEY
	,[Data]     MONEY
	,[Index]    MONEY
	,[Unused]   MONEY
	,[Space]	MONEY 
);

DECLARE databaseTables CURSOR FOR
SELECT 
	 IST.[TABLE_SCHEMA]
	,IST.[TABLE_NAME]
FROM 
	[INFORMATION_SCHEMA].[TABLES] IST
WHERE 
	IST.[TABLE_TYPE] = @tableType;

OPEN databaseTables;

FETCH NEXT FROM databaseTables 
INTO 
	 @tableSchema
	,@tableName;

WHILE @@FETCH_STATUS = 0 
BEGIN
	SET @objectName = '[' + @tableSchema + '].[' + @tableName + ']';
	INSERT @spaceUsed EXEC (@execCommand + @objectName + '''');

	WITH 
	 C AS
	(
		SELECT 
			COUNT(*) [Columns]
		FROM 
			[INFORMATION_SCHEMA].[COLUMNS] ISC
		WHERE
				ISC.[TABLE_SCHEMA]	= @tableSchema
			AND	ISC.[TABLE_NAME]	= @tableName
	)  
	,SU AS
	(
		SELECT
			 CAST(SU.[Rows]									AS BIGINT)					[Rows]
			,CAST(REPLACE(SU.[Reserved], @measureUnit, '')	AS BIGINT)/@measureValue	[Reserved]
			,CAST(REPLACE(SU.[Data],     @measureUnit, '')	AS BIGINT)/@measureValue	[Data]
			,CAST(REPLACE(SU.[Index],    @measureUnit, '')	AS BIGINT)/@measureValue	[Index]
			,CAST(REPLACE(SU.[Unused],   @measureUnit, '')	AS BIGINT)/@measureValue	[Unused]
		FROM
			@spaceUsed SU
	)
	INSERT @tableSpaces
	SELECT
		 @objectName
		,C.[Columns]
		,SU.*
		,SU.[Data] + SU.[Index]
	FROM 
		 C
		,SU; 
	
	DELETE FROM @spaceUsed;

	FETCH NEXT FROM databaseTables 
	INTO 
		 @tableSchema
		,@tableName;
END

CLOSE databaseTables;

DEALLOCATE databaseTables;

INSERT @tableSpaces
SELECT
	 @totalName
	,SUM(TS.[Columns])
	,SUM(TS.[Rows])
	,SUM(TS.[Reserved])
	,SUM(TS.[Data])
	,SUM(TS.[Index])
	,SUM(TS.[Unused])
	,SUM(TS.[Space])
FROM 
	@tableSpaces TS
WHERE
	TS.[Rows] > 0;

WITH T AS
(
	SELECT *
	FROM 
		@tableSpaces TS
	WHERE
		TS.[Name] = @totalName
)
SELECT 
	 TS.[Name]
	,TS.[Columns]
	,TS.[Columns]/ISNULL(NULLIF(CAST(T.[Columns] AS MONEY), 0), 1)*100	[%]
	,TS.[Rows]
	,TS.[Rows]/ISNULL(NULLIF(CAST(T.[Rows] AS MONEY), 0), 1)*100		[%]
	,TS.[Reserved]
	,TS.[Reserved]/ISNULL(NULLIF(T.[Reserved], 0), 1)*100				[%]
	,TS.[Data]
	,TS.[Data]/ISNULL(NULLIF(T.[Data], 0), 1)*100						[%]
	,TS.[Index]
	,TS.[Index]/ISNULL(NULLIF(T.[Index], 0), 1)*100						[%]
	,TS.[Unused]
	,TS.[Unused]/ISNULL(NULLIF(T.[Unused], 0), 1)*100					[%]
	,TS.[Space]
	,TS.[Space]/ISNULL(NULLIF(T.[Space], 0), 1)*100						[%]
FROM 
	 T
	,@tableSpaces TS
ORDER BY 
	 TS.[Space] DESC
	,TS.[Rows] DESC   
	,TS.[Name] ASC;
