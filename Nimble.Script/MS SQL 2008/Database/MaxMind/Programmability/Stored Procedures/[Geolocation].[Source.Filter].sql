SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Geolocation'	AND
			O.[type]	= 'P'			AND
			O.[name]	= 'Source.Filter'))
	DROP PROCEDURE [Geolocation].[Source.Filter];
GO

CREATE PROCEDURE [Geolocation].[Source.Filter]
(
	@predicate		XML,
	@isCountable	BIT			= NULL,
	@guids			XML	OUTPUT,
	@isExcluded		BIT	OUTPUT,
	@isFiltered		BIT	OUTPUT,
	@number			INT	OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @source TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
	DECLARE 
		@dateFrom	DATETIMEOFFSET,
		@dateTo		DATETIMEOFFSET;
	
	SET @isFiltered = 0;

--	Filter by codes
	DECLARE @codes TABLE ([Code] NVARCHAR(MAX));
	INSERT @codes SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/Codes/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/Codes/IsExcluded')), 0);
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @source SELECT DISTINCT S.[SourceId] FROM [Geolocation].[Source] S
				INNER JOIN	@codes	X	ON	S.[SourceCode]	LIKE X.[Code];
			ELSE 
				INSERT @source SELECT DISTINCT S.[SourceId] FROM [Geolocation].[Source] S
				LEFT JOIN	@codes	X	ON	S.[SourceCode]	LIKE X.[Code]
				WHERE X.[Code] IS NULL;
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @source	X
				LEFT JOIN
				(
					SELECT DISTINCT S.[SourceId] FROM [Geolocation].[Source] S
					INNER JOIN	@codes	X	ON	S.[SourceCode]	LIKE X.[Code]
				)	S	ON	X.[Id]	= S.[SourceId]
				WHERE S.[SourceId]	IS NULL;
			ELSE
				DELETE X FROM @source	X
				LEFT JOIN
				(
					SELECT DISTINCT S.[SourceId] FROM [Geolocation].[Source] S
					LEFT JOIN	@codes	X	ON	S.[SourceCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL
				)	S	ON	X.[Id]	= S.[SourceId]
				WHERE S.[SourceId]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by source input types
	DECLARE @sourceInputTypes TABLE ([SourceInputType] NVARCHAR(MAX));
	INSERT @sourceInputTypes SELECT DISTINCT LTRIM(X.[Entity].value('(text())[1]', 'NVARCHAR(MAX)')) [SourceInputType]
	FROM @predicate.nodes('/*/SourceInputTypes/Value/SourceInputType') X ([Entity])
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/SourceInputTypes/IsExcluded')), 0);
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @source SELECT DISTINCT S.[SourceId] FROM [Geolocation].[Source] S
				INNER JOIN	@sourceInputTypes	X	ON S.[SourceInputType]	LIKE X.[SourceInputType];
			ELSE 
				INSERT @source SELECT DISTINCT S.[SourceId] FROM [Geolocation].[Source] S
				LEFT JOIN	@sourceInputTypes	X	ON S.[SourceInputType]	LIKE X.[SourceInputType]
				WHERE X.[SourceInputType] IS NULL;
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @source	X
				LEFT JOIN
				(
					SELECT DISTINCT S.[SourceId] FROM [Geolocation].[Source] S
					INNER JOIN	@sourceInputTypes	X	ON S.[SourceInputType]	LIKE X.[SourceInputType]
				)	S	ON	X.[Id]	= S.[SourceId]
				WHERE S.[SourceId] IS NULL;
			ELSE
				DELETE X FROM @source	X
				LEFT JOIN
				(
					SELECT DISTINCT S.[SourceId] FROM [Geolocation].[Source] S
					LEFT JOIN	@sourceInputTypes	X	ON S.[SourceInputType]	LIKE X.[SourceInputType]
					WHERE X.[SourceInputType] IS NULL
				)	S	ON	X.[Id]	= S.[SourceId]
				WHERE S.[SourceId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by descriptions
	DECLARE @descriptions TABLE ([Description] NVARCHAR(MAX));
	INSERT @descriptions SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/Descriptions/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/Descriptions/IsExcluded')), 0);
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @source SELECT DISTINCT S.[SourceId] FROM [Geolocation].[Source] S
				INNER JOIN	@descriptions	X	ON	S.[SourceDescription]	LIKE X.[Description];
			ELSE 
				INSERT @source SELECT DISTINCT S.[SourceId] FROM [Geolocation].[Source] S
				LEFT JOIN	@descriptions	X	ON	S.[SourceDescription]	LIKE X.[Description]
				WHERE X.[Description] IS NULL;
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @source	X
				LEFT JOIN
				(
					SELECT DISTINCT S.[SourceId] FROM [Geolocation].[Source] S
					INNER JOIN	@descriptions	X	ON	S.[SourceDescription]	LIKE X.[Description]
				)	S	ON	X.[Id]	= S.[SourceId]
				WHERE S.[SourceId]	IS NULL;
			ELSE
				DELETE X FROM @source	X
				LEFT JOIN
				(
					SELECT DISTINCT S.[SourceId] FROM [Geolocation].[Source] S
					LEFT JOIN	@descriptions	X	ON	S.[SourceDescription]	LIKE X.[Description]
					WHERE X.[Description] IS NULL
				)	S	ON	X.[Id]	= S.[SourceId]
				WHERE S.[SourceId]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by created datetime offset
	SELECT @dateFrom = NULL, @dateTo = NULL;
	SELECT 
		@dateFrom	= X.[DateFrom], 
		@dateTo		= X.[DateTo] 
	FROM [Common].[DateInterval.Entity](@predicate.query('/*/CreatedOn/Value')) X;
	IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL) BEGIN 
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/CreatedOn/IsExcluded')), 0);
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @source SELECT S.[SourceId] FROM [Geolocation].[Source] S
				WHERE S.[SourceCreatedOn] BETWEEN ISNULL(@dateFrom, S.[SourceCreatedOn]) AND ISNULL(@dateTo, S.[SourceCreatedOn]);
			ELSE 
				INSERT @source SELECT S.[SourceId] FROM [Geolocation].[Source] S
				WHERE S.[SourceCreatedOn] NOT BETWEEN ISNULL(@dateFrom, S.[SourceCreatedOn]) AND ISNULL(@dateTo, S.[SourceCreatedOn]);
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @source	X
				LEFT JOIN
				(
					SELECT S.[SourceId] FROM [Geolocation].[Source] S
					WHERE S.[SourceCreatedOn] BETWEEN ISNULL(@dateFrom, S.[SourceCreatedOn]) AND ISNULL(@dateTo, S.[SourceCreatedOn])
				)	S	ON	X.[Id]	= S.[SourceId]
				WHERE S.[SourceId] IS NULL;
			ELSE
				DELETE X FROM @source	X
				LEFT JOIN
				(
					SELECT S.[SourceId] FROM [Geolocation].[Source] S
					WHERE S.[SourceCreatedOn] NOT BETWEEN ISNULL(@dateFrom, S.[SourceCreatedOn]) AND ISNULL(@dateTo, S.[SourceCreatedOn])
				)	S	ON	X.[Id]	= S.[SourceId]
				WHERE S.[SourceId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by approved datetime offset
	SELECT @dateFrom = NULL, @dateTo = NULL;
	SELECT 
		@dateFrom	= X.[DateFrom], 
		@dateTo		= X.[DateTo] 
	FROM [Common].[DateInterval.Entity](@predicate.query('/*/ApprovedOn/Value')) X;
	IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL) BEGIN 
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/ApprovedOn/IsExcluded')), 0);
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @source SELECT S.[SourceId] FROM [Geolocation].[Source] S
				WHERE S.[SourceApprovedOn] BETWEEN ISNULL(@dateFrom, S.[SourceApprovedOn]) AND ISNULL(@dateTo, S.[SourceApprovedOn]);
			ELSE 
				INSERT @source SELECT S.[SourceId] FROM [Geolocation].[Source] S
				WHERE S.[SourceApprovedOn] NOT BETWEEN ISNULL(@dateFrom, S.[SourceApprovedOn]) AND ISNULL(@dateTo, S.[SourceApprovedOn]);
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @source	X
				LEFT JOIN
				(
					SELECT S.[SourceId] FROM [Geolocation].[Source] S
					WHERE S.[SourceApprovedOn] BETWEEN ISNULL(@dateFrom, S.[SourceApprovedOn]) AND ISNULL(@dateTo, S.[SourceApprovedOn])
				)	S	ON	X.[Id]	= S.[SourceId]
				WHERE S.[SourceId] IS NULL;
			ELSE
				DELETE X FROM @source	X
				LEFT JOIN
				(
					SELECT S.[SourceId] FROM [Geolocation].[Source] S
					WHERE S.[SourceApprovedOn] NOT BETWEEN ISNULL(@dateFrom, S.[SourceApprovedOn]) AND ISNULL(@dateTo, S.[SourceApprovedOn])
				)	S	ON	X.[Id]	= S.[SourceId]
				WHERE S.[SourceId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by entities
	DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
	INSERT @entities SELECT DISTINCT E.[Id]
	FROM [Common].[Generic.Entities](@predicate.query('/*/Sources/Value/Source')) X
	CROSS APPLY [Geolocation].[Source.Entity](X.[Entity]) E;
	IF (@@ROWCOUNT > 0) BEGIN
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/Sources/IsExcluded')), 0);
		DELETE X FROM @entities X WHERE X.[Id] IS NULL;
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @source SELECT * FROM @entities;
			ELSE
				INSERT @source SELECT S.[SourceId] FROM [Geolocation].[Source] S
				WHERE S.[SourceId] NOT IN (SELECT * FROM @entities);
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @source X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
			ELSE
				DELETE X FROM @source X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

	SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/IsExcluded')), 0);

	SET @guids = (SELECT X.[Id] [guid] FROM @source X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Geolocation].[Source] S;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @source X;
		ELSE
			SELECT @number = COUNT(*) FROM [Geolocation].[Source] S
			LEFT JOIN	@source	X	ON	S.[SourceId] = X.[Id]
			WHERE X.[Id] IS NULL;

END
GO
