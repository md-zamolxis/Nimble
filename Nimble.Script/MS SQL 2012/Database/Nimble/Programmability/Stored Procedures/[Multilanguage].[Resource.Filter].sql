SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multilanguage'	AND
			O.[type]	= 'P'				AND
			O.[name]	= 'Resource.Filter'))
	DROP PROCEDURE [Multilanguage].[Resource.Filter];
GO

CREATE PROCEDURE [Multilanguage].[Resource.Filter]
(
	@predicate		XML,
	@emplacementId	UNIQUEIDENTIFIER	= NULL,
	@applicationId	UNIQUEIDENTIFIER	= NULL,
	@organisations	XML					= NULL,
	@isCountable	BIT					= NULL,
	@guids			XML							OUTPUT,
	@isExcluded		BIT							OUTPUT,
	@isFiltered		BIT							OUTPUT,
	@number			INT							OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @resource TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
	DECLARE
		@criteria			XML,
		@criteriaExist		BIT,
		@criteriaIsNull		BIT,
		@criteriaValue		XML,
		@criteriaValueExist	BIT,
		@dateFrom			DATETIMEOFFSET,
		@dateTo				DATETIMEOFFSET;
	
	SET @isFiltered = 0;

--	Filter by entities
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Resources')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Resource');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Multilanguage].[Resource.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @resource SELECT * FROM @entities;
				ELSE
					INSERT @resource SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
					WHERE R.[ResourceId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @resource X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @resource X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

--	Filter by emplacement predicate
	DECLARE 
		@emplacementPredicate	XML,
		@emplacementIsCountable	BIT,
		@emplacementGuids		XML,
		@emplacementIsFiltered	BIT,
		@emplacementNumber		INT;
	SELECT 
		@emplacementPredicate	= X.[Criteria],
		@emplacementIsCountable	= 0,
		@criteriaExist			= X.[CriteriaExist],
		@isExcluded				= X.[CriteriaIsExcluded],
		@criteriaIsNull			= X.[CriteriaIsNull],
		@criteriaValue			= X.[CriteriaValue],
		@criteriaValueExist		= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/EmplacementPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @emplacement TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Security].[Emplacement.Filter]
			@predicate,
			@emplacementId,
			@applicationId,
			@organisations,
			@isCountable,
			@guids		OUTPUT,
			@isExcluded OUTPUT,
			@isFiltered OUTPUT,
			@number		OUTPUT',
			N'@predicate	XML,
			@emplacementId	UNIQUEIDENTIFIER,
			@applicationId	UNIQUEIDENTIFIER,
			@organisations	XML,
			@isCountable	BIT,
			@guids			XML OUTPUT,
			@isExcluded		BIT OUTPUT,
			@isFiltered		BIT OUTPUT,
			@number			INT OUTPUT',
			@predicate		= @emplacementPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @emplacementIsCountable,
			@guids			= @emplacementGuids			OUTPUT,
			@isExcluded		= @isExcluded				OUTPUT,
			@isFiltered		= @emplacementIsFiltered	OUTPUT,
			@number			= @emplacementNumber		OUTPUT;
		INSERT @emplacement SELECT * FROM [Common].[Guid.Entities](@emplacementGuids);
		IF (@emplacementIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @resource SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
					INNER JOIN	@emplacement	X	ON	R.[ResourceEmplacementId]	= X.[Id];
				ELSE
					INSERT @resource SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
					LEFT JOIN	@emplacement	X	ON	R.[ResourceEmplacementId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @resource	X
					LEFT JOIN (
						SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
						INNER JOIN	@emplacement	X	ON	R.[ResourceEmplacementId]	= X.[Id]
					)	R	ON	X.[Id]	= R.[ResourceId]
					WHERE R.[ResourceId] IS NULL;
				ELSE
					DELETE X FROM @resource	X
					LEFT JOIN (
						SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
						LEFT JOIN	@emplacement	X	ON	R.[ResourceEmplacementId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	R	ON	X.[Id]	= R.[ResourceId]
					WHERE R.[ResourceId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by application predicate
	DECLARE 
		@applicationPredicate	XML,
		@applicationIsCountable	BIT,
		@applicationGuids		XML,
		@applicationIsFiltered	BIT,
		@applicationNumber		INT;
	SELECT 
		@applicationPredicate	= X.[Criteria],
		@applicationIsCountable	= 0,
		@criteriaExist			= X.[CriteriaExist],
		@isExcluded				= X.[CriteriaIsExcluded],
		@criteriaIsNull			= X.[CriteriaIsNull],
		@criteriaValue			= X.[CriteriaValue],
		@criteriaValueExist		= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/ApplicationPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @application TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Security].[Application.Filter]
			@predicate,
			@emplacementId,
			@applicationId,
			@organisations,
			@isCountable,
			@guids		OUTPUT,
			@isExcluded OUTPUT,
			@isFiltered OUTPUT,
			@number		OUTPUT',
			N'@predicate	XML,
			@emplacementId	UNIQUEIDENTIFIER,
			@applicationId	UNIQUEIDENTIFIER,
			@organisations	XML,
			@isCountable	BIT,
			@guids			XML OUTPUT,
			@isExcluded		BIT OUTPUT,
			@isFiltered		BIT OUTPUT,
			@number			INT OUTPUT',
			@predicate		= @applicationPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @applicationIsCountable,
			@guids			= @applicationGuids			OUTPUT,
			@isExcluded		= @isExcluded				OUTPUT,
			@isFiltered		= @applicationIsFiltered	OUTPUT,
			@number			= @applicationNumber		OUTPUT;
		INSERT @application SELECT * FROM [Common].[Guid.Entities](@applicationGuids);
		IF (@applicationIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @resource SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
					INNER JOIN	@application	X	ON	R.[ResourceApplicationId]	= X.[Id];
				ELSE
					INSERT @resource SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
					LEFT JOIN	@application	X	ON	R.[ResourceApplicationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @resource	X
					LEFT JOIN (
						SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
						INNER JOIN	@application	X	ON	R.[ResourceApplicationId]	= X.[Id]
					)	R	ON	X.[Id]	= R.[ResourceId]
					WHERE R.[ResourceId] IS NULL;
				ELSE
					DELETE X FROM @resource	X
					LEFT JOIN (
						SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
						LEFT JOIN	@application	X	ON	R.[ResourceApplicationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	R	ON	X.[Id]	= R.[ResourceId]
					WHERE R.[ResourceId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @resource SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
			WHERE R.[ResourceEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @resource	X
			LEFT JOIN	(
				SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
				WHERE R.[ResourceEmplacementId] = @emplacementId
			)	R	ON	X.[Id]	= R.[ResourceId]
			WHERE R.[ResourceId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by application
	IF (@applicationId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @resource SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
			WHERE R.[ResourceApplicationId] = @applicationId;
		ELSE
			DELETE X FROM @resource	X
			LEFT JOIN	(
				SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
				WHERE R.[ResourceApplicationId] = @applicationId
			)	R	ON	X.[Id]	= R.[ResourceId]
			WHERE R.[ResourceId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by codes
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Codes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @codes TABLE ([Code] NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CS_AS);
		INSERT @codes SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @resource SELECT DISTINCT R.[ResourceId] FROM [Multilanguage].[Resource] R
					INNER JOIN	@codes	X	ON	R.[ResourceCode]	LIKE X.[Code];
				ELSE 
					INSERT @resource SELECT DISTINCT R.[ResourceId] FROM [Multilanguage].[Resource] R
					LEFT JOIN	@codes	X	ON	R.[ResourceCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @resource	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[ResourceId] FROM [Multilanguage].[Resource] R
						INNER JOIN	@codes	X	ON	R.[ResourceCode]	LIKE X.[Code]
					)	R	ON	X.[Id]	= R.[ResourceId]
					WHERE R.[ResourceId] IS NULL;
				ELSE
					DELETE X FROM @resource	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[ResourceId] FROM [Multilanguage].[Resource] R
						LEFT JOIN	@codes	X	ON	R.[ResourceCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	R	ON	X.[Id]	= R.[ResourceId]
					WHERE R.[ResourceId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by categories
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Categories')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @categories TABLE ([Category] NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CS_AS);
		INSERT @categories SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @resource SELECT DISTINCT R.[ResourceId] FROM [Multilanguage].[Resource] R
					INNER JOIN	@categories	X	ON	R.[ResourceCategory]	LIKE X.[Category];
				ELSE 
					INSERT @resource SELECT DISTINCT R.[ResourceId] FROM [Multilanguage].[Resource] R
					LEFT JOIN	@categories	X	ON	R.[ResourceCategory]	LIKE X.[Category]
					WHERE X.[Category] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @resource	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[ResourceId] FROM [Multilanguage].[Resource] R
						INNER JOIN	@categories	X	ON	R.[ResourceCategory]	LIKE X.[Category]
					)	R	ON	X.[Id]	= R.[ResourceId]
					WHERE R.[ResourceId] IS NULL;
				ELSE
					DELETE X FROM @resource	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[ResourceId] FROM [Multilanguage].[Resource] R
						LEFT JOIN	@categories	X	ON	R.[ResourceCategory]	LIKE X.[Category]
						WHERE X.[Category] IS NULL
					)	R	ON	X.[Id]	= R.[ResourceId]
					WHERE R.[ResourceId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by indexes
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Indexes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @indexes TABLE ([Index] NVARCHAR(MAX));
		INSERT @indexes SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @resource SELECT DISTINCT R.[ResourceId] FROM [Multilanguage].[Resource] R
					INNER JOIN	@indexes	X	ON	R.[ResourceIndex]	LIKE X.[Index];
				ELSE 
					INSERT @resource SELECT DISTINCT R.[ResourceId] FROM [Multilanguage].[Resource] R
					LEFT JOIN	@indexes	X	ON	R.[ResourceIndex]	LIKE X.[Index]
					WHERE X.[Index] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @resource	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[ResourceId] FROM [Multilanguage].[Resource] R
						INNER JOIN	@indexes	X	ON	R.[ResourceIndex]	LIKE X.[Index]
					)	R	ON	X.[Id]	= R.[ResourceId]
					WHERE R.[ResourceId] IS NULL;
				ELSE
					DELETE X FROM @resource	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[ResourceId] FROM [Multilanguage].[Resource] R
						LEFT JOIN	@indexes	X	ON	R.[ResourceIndex]	LIKE X.[Index]
						WHERE X.[Index] IS NULL
					)	R	ON	X.[Id]	= R.[ResourceId]
					WHERE R.[ResourceId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by created datetime offset
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/CreatedOn')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @dateFrom = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @resource SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
					WHERE R.[ResourceCreatedOn] BETWEEN ISNULL(@dateFrom, R.[ResourceCreatedOn]) AND ISNULL(@dateTo, R.[ResourceCreatedOn]);
				ELSE 
					INSERT @resource SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
					WHERE R.[ResourceCreatedOn] NOT BETWEEN ISNULL(@dateFrom, R.[ResourceCreatedOn]) AND ISNULL(@dateTo, R.[ResourceCreatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @resource	X
					LEFT JOIN
					(
						SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
						WHERE R.[ResourceCreatedOn] BETWEEN ISNULL(@dateFrom, R.[ResourceCreatedOn]) AND ISNULL(@dateTo, R.[ResourceCreatedOn])
					)	R	ON	X.[Id]	= R.[ResourceId]
					WHERE R.[ResourceId] IS NULL;
				ELSE
					DELETE X FROM @resource	X
					LEFT JOIN
					(
						SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
						WHERE R.[ResourceCreatedOn] NOT BETWEEN ISNULL(@dateFrom, R.[ResourceCreatedOn]) AND ISNULL(@dateTo, R.[ResourceCreatedOn])
					)	R	ON	X.[Id]	= R.[ResourceId]
					WHERE R.[ResourceId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by last used datetime offset
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/LastUsedOn')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @dateFrom = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @resource SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
					WHERE R.[ResourceLastUsedOn] BETWEEN ISNULL(@dateFrom, R.[ResourceLastUsedOn]) AND ISNULL(@dateTo, R.[ResourceLastUsedOn]);
				ELSE 
					INSERT @resource SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
					WHERE R.[ResourceLastUsedOn] NOT BETWEEN ISNULL(@dateFrom, R.[ResourceLastUsedOn]) AND ISNULL(@dateTo, R.[ResourceLastUsedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @resource	X
					LEFT JOIN
					(
						SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
						WHERE R.[ResourceLastUsedOn] BETWEEN ISNULL(@dateFrom, R.[ResourceLastUsedOn]) AND ISNULL(@dateTo, R.[ResourceLastUsedOn])
					)	R	ON	X.[Id]	= R.[ResourceId]
					WHERE R.[ResourceId] IS NULL;
				ELSE
					DELETE X FROM @resource	X
					LEFT JOIN
					(
						SELECT R.[ResourceId] FROM [Multilanguage].[Resource] R
						WHERE R.[ResourceLastUsedOn] NOT BETWEEN ISNULL(@dateFrom, R.[ResourceLastUsedOn]) AND ISNULL(@dateTo, R.[ResourceLastUsedOn])
					)	R	ON	X.[Id]	= R.[ResourceId]
					WHERE R.[ResourceId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @resource X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Multilanguage].[Resource] R;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @resource X;
		ELSE
			SELECT @number = COUNT(*) FROM [Multilanguage].[Resource] R
			LEFT JOIN	@resource	X	ON	R.[ResourceId] = X.[Id]
			WHERE 
				R.[ResourceEmplacementId]	= ISNULL(@emplacementId, R.[ResourceEmplacementId])	AND
				R.[ResourceApplicationId]	= ISNULL(@applicationId, R.[ResourceApplicationId])	AND
				X.[Id] IS NULL;

END
GO
