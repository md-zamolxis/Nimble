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
			O.[name]	= 'Translation.Filter'))
	DROP PROCEDURE [Multilanguage].[Translation.Filter];
GO

CREATE PROCEDURE [Multilanguage].[Translation.Filter]
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

	DECLARE @translation TABLE
	(
		[ResourceId]	UNIQUEIDENTIFIER,
		[CultureId]		UNIQUEIDENTIFIER,
		PRIMARY KEY CLUSTERED 
		(
			[ResourceId],
			[CultureId]
		)
	);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Translations')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Translation');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Multilanguage].[Translation.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @translation SELECT
						T.[ResourceId],
						T.[CultureId]
					FROM [Multilanguage].[Entity.Translation]	T
					INNER JOIN	@entities						X	ON	T.[TranslationId]	= X.[Id];
				ELSE
					INSERT @translation SELECT
						T.[ResourceId],
						T.[CultureId]
					FROM [Multilanguage].[Entity.Translation]	T
					LEFT JOIN	@entities						X	ON	T.[TranslationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @translation	X
					LEFT JOIN
					(
						SELECT
							T.[ResourceId],
							T.[CultureId]
						FROM [Multilanguage].[Entity.Translation]	T
						INNER JOIN	@entities						X	ON	T.[TranslationId]	= X.[Id]
					)	T	ON	X.[ResourceId]	= T.[ResourceId]	AND
								X.[CultureId]	= T.[CultureId]
					WHERE COALESCE(T.[ResourceId], T.[CultureId]) IS NULL;
				ELSE
					DELETE X FROM @translation	X
					LEFT JOIN
					(
						SELECT DISTINCT 
							T.[ResourceId],
							T.[CultureId]
						FROM [Multilanguage].[Entity.Translation]	T
						LEFT JOIN	@entities						X	ON	T.[TranslationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	T	ON	X.[ResourceId]	= T.[ResourceId]	AND
								X.[CultureId]	= T.[CultureId]
					WHERE COALESCE(T.[ResourceId], T.[CultureId]) IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by resource predicate
	DECLARE 
		@resourcePredicate		XML,
		@resourceIsCountable	BIT,
		@resourceGuids			XML,
		@resourceIsFiltered		BIT,
		@resourceNumber			INT;
	SELECT 
		@resourcePredicate		= X.[Criteria],
		@resourceIsCountable	= 0,
		@criteriaExist			= X.[CriteriaExist],
		@isExcluded				= X.[CriteriaIsExcluded],
		@criteriaIsNull			= X.[CriteriaIsNull],
		@criteriaValue			= X.[CriteriaValue],
		@criteriaValueExist		= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/ResourcePredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @resource TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Multilanguage].[Resource.Filter]
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
			@predicate		= @resourcePredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @resourceIsCountable,
			@guids			= @resourceGuids		OUTPUT,
			@isExcluded		= @isExcluded			OUTPUT,
			@isFiltered		= @resourceIsFiltered	OUTPUT,
			@number			= @resourceNumber		OUTPUT;
		INSERT @resource SELECT * FROM [Common].[Guid.Entities](@resourceGuids);
		IF (@resourceIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @translation SELECT
						T.[ResourceId],
						T.[CultureId]
					FROM [Multilanguage].[Entity.Translation]	T
					INNER JOIN	@resource						X	ON	T.[ResourceId]	= X.[Id];
				ELSE
					INSERT @translation SELECT
						T.[ResourceId],
						T.[CultureId]
					FROM [Multilanguage].[Entity.Translation]	T
					LEFT JOIN	@resource						X	ON	T.[ResourceId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @translation	X
					LEFT JOIN
					(
						SELECT
							T.[ResourceId],
							T.[CultureId]
						FROM [Multilanguage].[Entity.Translation]	T
						INNER JOIN	@resource						X	ON	T.[ResourceId]	= X.[Id]
					)	T	ON	X.[ResourceId]	= T.[ResourceId]	AND
								X.[CultureId]	= T.[CultureId]
					WHERE COALESCE(T.[ResourceId], T.[CultureId]) IS NULL;
				ELSE
					DELETE X FROM @translation	X
					LEFT JOIN
					(
						SELECT
							T.[ResourceId],
							T.[CultureId]
						FROM [Multilanguage].[Entity.Translation]	T
						LEFT JOIN	@resource						X	ON	T.[ResourceId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	T	ON	X.[ResourceId]	= T.[ResourceId]	AND
								X.[CultureId]	= T.[CultureId]
					WHERE COALESCE(T.[ResourceId], T.[CultureId]) IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by culture predicate
	DECLARE 
		@culturePredicate	XML,
		@cultureIsCountable	BIT,
		@cultureGuids		XML,
		@cultureIsFiltered	BIT,
		@cultureNumber		INT;
	SELECT 
		@culturePredicate	= X.[Criteria],
		@cultureIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/CulturePredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @culture TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Multilanguage].[Culture.Filter]
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
			@predicate		= @culturePredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @cultureIsCountable,
			@guids			= @cultureGuids			OUTPUT,
			@isExcluded		= @isExcluded			OUTPUT,
			@isFiltered		= @cultureIsFiltered	OUTPUT,
			@number			= @cultureNumber		OUTPUT;
		INSERT @culture SELECT * FROM [Common].[Guid.Entities](@cultureGuids);
		IF (@cultureIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @translation SELECT
						T.[ResourceId],
						T.[CultureId]
					FROM [Multilanguage].[Entity.Translation]	T
					INNER JOIN	@culture						X	ON	T.[CultureId]	= X.[Id];
				ELSE
					INSERT @translation SELECT
						T.[ResourceId],
						T.[CultureId]
					FROM [Multilanguage].[Entity.Translation]	T
					LEFT JOIN	@culture						X	ON	T.[CultureId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @translation	X
					LEFT JOIN
					(
						SELECT
							T.[ResourceId],
							T.[CultureId]
						FROM [Multilanguage].[Entity.Translation]	T
						INNER JOIN	@culture						X	ON	T.[CultureId]	= X.[Id]
					)	T	ON	X.[ResourceId]	= T.[ResourceId]	AND
								X.[CultureId]	= T.[CultureId]
					WHERE COALESCE(T.[ResourceId], T.[CultureId]) IS NULL;
				ELSE
					DELETE X FROM @translation	X
					LEFT JOIN
					(
						SELECT
							T.[ResourceId],
							T.[CultureId]
						FROM [Multilanguage].[Entity.Translation]	T
						LEFT JOIN	@culture						X	ON	T.[CultureId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	T	ON	X.[ResourceId]	= T.[ResourceId]	AND
								X.[CultureId]	= T.[CultureId]
					WHERE COALESCE(T.[ResourceId], T.[CultureId]) IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @translation SELECT
				T.[ResourceId],
				T.[CultureId]
			FROM [Multilanguage].[Entity.Translation] T
			WHERE T.[EmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @translation	X
			LEFT JOIN
			(
				SELECT
					T.[ResourceId],
					T.[CultureId]
				FROM [Multilanguage].[Entity.Translation] T
				WHERE T.[EmplacementId] = @emplacementId
			)	T	ON	X.[ResourceId]	= T.[ResourceId]	AND
						X.[CultureId]	= T.[CultureId]
			WHERE COALESCE(T.[ResourceId], T.[CultureId]) IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by application
	IF (@applicationId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @translation SELECT
				T.[ResourceId],
				T.[CultureId]
			FROM [Multilanguage].[Entity.Translation] T
			WHERE T.[ApplicationId] = @applicationId;
		ELSE
			DELETE X FROM @translation	X
			LEFT JOIN
			(
				SELECT
					T.[ResourceId],
					T.[CultureId]
				FROM [Multilanguage].[Entity.Translation] T
				WHERE T.[ApplicationId] = @applicationId
			)	T	ON	X.[ResourceId]	= T.[ResourceId]	AND
						X.[CultureId]	= T.[CultureId]
			WHERE COALESCE(T.[ResourceId], T.[CultureId]) IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by senses
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Senses')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @senses TABLE ([Sense] NVARCHAR(MAX));
		INSERT @senses SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @translation SELECT DISTINCT 
						T.[ResourceId],
						T.[CultureId]
					FROM [Multilanguage].[Entity.Translation]	T
					INNER JOIN	@senses							X	ON	T.[TranslationSense]	LIKE X.[Sense];
				ELSE 
					INSERT @translation SELECT DISTINCT 
						T.[ResourceId],
						T.[CultureId]
					FROM [Multilanguage].[Entity.Translation]	T
					LEFT JOIN	@senses							X	ON	T.[TranslationSense]	LIKE X.[Sense]
					WHERE X.[Sense] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @translation	X
					LEFT JOIN
					(
						SELECT DISTINCT 
							T.[ResourceId],
							T.[CultureId]
						FROM [Multilanguage].[Entity.Translation]	T
						INNER JOIN	@senses							X	ON	T.[TranslationSense]	LIKE X.[Sense]
					)	T	ON	X.[ResourceId]	= T.[ResourceId]	AND
								X.[CultureId]	= T.[CultureId]
					WHERE COALESCE(T.[ResourceId], T.[CultureId]) IS NULL;
				ELSE
					DELETE X FROM @translation	X
					LEFT JOIN
					(
						SELECT DISTINCT 
							T.[ResourceId],
							T.[CultureId]
						FROM [Multilanguage].[Entity.Translation]	T
						LEFT JOIN	@senses							X	ON	T.[TranslationSense]	LIKE X.[Sense]
						WHERE X.[Sense] IS NULL
					)	T	ON	X.[ResourceId]	= T.[ResourceId]	AND
								X.[CultureId]	= T.[CultureId]
					WHERE COALESCE(T.[ResourceId], T.[CultureId]) IS NULL;
		SET @isFiltered = 1;
	END
	
--	Filter by translated status
	DECLARE @translated BIT;
	SET @translated = [Common].[Bool.Entity](@predicate.query('/*/Translated'));
	IF (@translated IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @translation SELECT
				T.[ResourceId],
				T.[CultureId]
			FROM [Multilanguage].[Entity.Translation] T
			WHERE 
				(
					@translated = 1	AND
					T.[TranslationId] IS NOT NULL
				)	OR
				(
					@translated = 0	AND
					T.[TranslationId] IS NULL
				);
		ELSE
			DELETE X FROM @translation	X
			LEFT JOIN
			(
				SELECT
					T.[ResourceId],
					T.[CultureId]
				FROM [Multilanguage].[Entity.Translation] T
				WHERE 
					(
						@translated = 1	AND
						T.[TranslationId] IS NOT NULL
					)	OR
					(
						@translated = 0	AND
						T.[TranslationId] IS NULL
					)
			)	T	ON	X.[ResourceId]	= T.[ResourceId]	AND
						X.[CultureId]	= T.[CultureId]
			WHERE COALESCE(T.[ResourceId], T.[CultureId]) IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT * FROM @translation X FOR XML PATH('guid'), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Multilanguage].[Entity.Translation] T;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @translation X;
		ELSE
			SELECT @number = COUNT(*) FROM [Multilanguage].[Entity.Translation] T
			LEFT JOIN	@translation	X	ON	T.[ResourceId]	= X.[ResourceId]	AND
												T.[CultureId]	= X.[CultureId]
			WHERE 
				T.[EmplacementId]	= ISNULL(@emplacementId, T.[EmplacementId])	AND
				T.[ApplicationId]	= ISNULL(@applicationId, T.[ApplicationId])	AND
				COALESCE(X.[ResourceId], X.[CultureId]) IS NULL;

END
GO
