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
			O.[name]	= 'Culture.Filter'))
	DROP PROCEDURE [Multilanguage].[Culture.Filter];
GO

CREATE PROCEDURE [Multilanguage].[Culture.Filter]
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
	
	DECLARE @culture TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
	DECLARE 
		@criteria			XML,
		@criteriaExist		BIT,
		@criteriaIsNull		BIT,
		@criteriaValue		XML,
		@criteriaValueExist	BIT;
	
	SET @isFiltered = 0;

--	Filter by entities
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Cultures')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Culture');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Multilanguage].[Culture.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @culture SELECT * FROM @entities;
				ELSE
					INSERT @culture SELECT C.[CultureId] FROM [Multilanguage].[Culture] C
					WHERE C.[CultureId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @culture X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @culture X WHERE X.[Id] IN (SELECT * FROM @entities);
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
					INSERT @culture SELECT C.[CultureId] FROM [Multilanguage].[Culture] C
					INNER JOIN	@emplacement	X	ON	C.[CultureEmplacementId]	= X.[Id];
				ELSE
					INSERT @culture SELECT C.[CultureId] FROM [Multilanguage].[Culture] C
					LEFT JOIN	@emplacement	X	ON	C.[CultureEmplacementId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @culture	X
					LEFT JOIN
					(
						SELECT C.[CultureId] FROM [Multilanguage].[Culture] C
						INNER JOIN	@emplacement	X	ON	C.[CultureEmplacementId]	= X.[Id]
					)	C	ON	X.[Id]	= C.[CultureId]
					WHERE C.[CultureId]	IS NULL;
				ELSE
					DELETE X FROM @culture	X
					LEFT JOIN
					(
						SELECT C.[CultureId] FROM [Multilanguage].[Culture] C
						LEFT JOIN	@emplacement	X	ON	C.[CultureEmplacementId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	C	ON	X.[Id]	= C.[CultureId]
					WHERE C.[CultureId]	IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @culture SELECT C.[CultureId] FROM [Multilanguage].[Culture] C
			WHERE C.[CultureEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @culture	X
			LEFT JOIN
			(
				SELECT C.[CultureId] FROM [Multilanguage].[Culture] C
				WHERE C.[CultureEmplacementId] = @emplacementId
			)	C	ON	X.[Id]	= C.[CultureId]
			WHERE C.[CultureId]	IS NULL;
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
		DECLARE @codes TABLE ([Code] NVARCHAR(MAX));
		INSERT @codes SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @culture SELECT DISTINCT C.[CultureId] FROM [Multilanguage].[Culture] C
					INNER JOIN	@codes	X	ON	C.[CultureCode]	LIKE X.[Code];
				ELSE 
					INSERT @culture SELECT DISTINCT C.[CultureId] FROM [Multilanguage].[Culture] C
					LEFT JOIN	@codes	X	ON	C.[CultureCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @culture	X
					LEFT JOIN
					(
						SELECT DISTINCT C.[CultureId] FROM [Multilanguage].[Culture] C
						INNER JOIN	@codes	X	ON	C.[CultureCode]	LIKE X.[Code]
					)	C	ON	X.[Id]	= C.[CultureId]
					WHERE C.[CultureId]	IS NULL;
				ELSE
					DELETE X FROM @culture	X
					LEFT JOIN
					(
						SELECT DISTINCT C.[CultureId] FROM [Multilanguage].[Culture] C
						LEFT JOIN	@codes	X	ON	C.[CultureCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	C	ON	X.[Id]	= C.[CultureId]
					WHERE C.[CultureId]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by names
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Names')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @names TABLE ([Name] NVARCHAR(MAX));
		INSERT @names SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @culture SELECT DISTINCT C.[CultureId] FROM [Multilanguage].[Culture] C
					INNER JOIN	@names	X	ON	C.[CultureName]	LIKE X.[Name];
				ELSE 
					INSERT @culture SELECT DISTINCT C.[CultureId] FROM [Multilanguage].[Culture] C
					LEFT JOIN	@names	X	ON	C.[CultureName]	LIKE X.[Name]
					WHERE X.[Name] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @culture	X
					LEFT JOIN
					(
						SELECT DISTINCT C.[CultureId] FROM [Multilanguage].[Culture] C
						INNER JOIN	@names	X	ON	C.[CultureName]	LIKE X.[Name]
					)	C	ON	X.[Id]	= C.[CultureId]
					WHERE C.[CultureId]	IS NULL;
				ELSE
					DELETE X FROM @culture	X
					LEFT JOIN
					(
						SELECT DISTINCT C.[CultureId] FROM [Multilanguage].[Culture] C
						LEFT JOIN	@names	X	ON	C.[CultureName]	LIKE X.[Name]
						WHERE X.[Name] IS NULL
					)	C	ON	X.[Id]	= C.[CultureId]
					WHERE C.[CultureId]	IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @culture X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Multilanguage].[Culture] C;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @culture X;
		ELSE
			SELECT @number = COUNT(*) FROM [Multilanguage].[Culture] C
			LEFT JOIN	@culture	X	ON	C.[CultureId] = X.[Id]
			WHERE 
				C.[CultureEmplacementId] = ISNULL(@emplacementId, C.[CultureEmplacementId])	AND
				X.[Id] IS NULL;

END
GO
