SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'P'		AND
			O.[name]	= 'Split.Filter'))
	DROP PROCEDURE [Common].[Split.Filter];
GO

CREATE PROCEDURE [Common].[Split.Filter]
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
	
	DECLARE @split TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Splits')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Split');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Common].[Split.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @split SELECT * FROM @entities;
				ELSE
					INSERT @split SELECT S.[SplitId] FROM [Common].[Split] S
					WHERE S.[SplitId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @split X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @split X WHERE X.[Id] IN (SELECT * FROM @entities);
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
					INSERT @split SELECT S.[SplitId] FROM [Common].[Split] S
					INNER JOIN	@emplacement	X	ON	S.[SplitEmplacementId]	= X.[Id];
				ELSE
					INSERT @split SELECT S.[SplitId] FROM [Common].[Split] S
					LEFT JOIN	@emplacement	X	ON	S.[SplitEmplacementId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @split	X
					LEFT JOIN
					(
						SELECT S.[SplitId] FROM [Common].[Split] S
						INNER JOIN	@emplacement	X	ON	S.[SplitEmplacementId]	= X.[Id]
					)	S	ON	X.[Id]	= S.[SplitId]
					WHERE S.[SplitId] IS NULL;
				ELSE
					DELETE X FROM @split	X
					LEFT JOIN
					(
						SELECT S.[SplitId] FROM [Common].[Split] S
						LEFT JOIN	@emplacement	X	ON	S.[SplitEmplacementId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	S	ON	X.[Id]	= S.[SplitId]
					WHERE S.[SplitId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @split SELECT S.[SplitId] FROM [Common].[Split] S
			WHERE S.[SplitEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @split	X
			LEFT JOIN	(
				SELECT S.[SplitId] FROM [Common].[Split] S
				WHERE S.[SplitEmplacementId] = @emplacementId
			)	S	ON	X.[Id]	= S.[SplitId]
			WHERE S.[SplitId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by split entity types
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/SplitEntityTypes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @splitEntityTypes TABLE ([SplitEntityType] NVARCHAR(MAX));
		INSERT @splitEntityTypes SELECT DISTINCT * FROM [Common].[Enum.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @split SELECT DISTINCT S.[SplitId] FROM [Common].[Split] S
					INNER JOIN	@splitEntityTypes		X	ON	S.[SplitEntityType]	LIKE X.[SplitEntityType];
				ELSE 
					INSERT @split SELECT DISTINCT S.[SplitId] FROM [Common].[Split] S
					LEFT JOIN	@splitEntityTypes		X	ON	S.[SplitEntityType]	LIKE X.[SplitEntityType]
					WHERE X.[SplitEntityType] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @split	X
					LEFT JOIN
					(
						SELECT DISTINCT S.[SplitId] FROM [Common].[Split] S
						INNER JOIN	@splitEntityTypes		X	ON	S.[SplitEntityType]	LIKE X.[SplitEntityType]
					)	S	ON	X.[Id]	= S.[SplitId]
					WHERE S.[SplitId] IS NULL;
				ELSE
					DELETE X FROM @split	X
					LEFT JOIN
					(
						SELECT DISTINCT S.[SplitId] FROM [Common].[Split] S
						LEFT JOIN	@splitEntityTypes		X	ON	S.[SplitEntityType]	LIKE X.[SplitEntityType]
						WHERE X.[SplitEntityType] IS NULL
					)	S	ON	X.[Id]	= S.[SplitId]
					WHERE S.[SplitId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by split entity codes
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/SplitEntityCodes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @splitEntityCodes TABLE ([SplitEntityCode] NVARCHAR(MAX));
		INSERT @splitEntityCodes SELECT * FROM [Common].[Enum.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @split SELECT DISTINCT S.[SplitId] FROM [Common].[Split] S
					INNER JOIN	@splitEntityCodes		X	ON	S.[SplitEntityCode]	LIKE X.[SplitEntityCode];
				ELSE 
					INSERT @split SELECT DISTINCT S.[SplitId] FROM [Common].[Split] S
					LEFT JOIN	@splitEntityCodes		X	ON	S.[SplitEntityCode]	LIKE X.[SplitEntityCode]
					WHERE X.[SplitEntityCode] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @split	X
					LEFT JOIN
					(
						SELECT DISTINCT S.[SplitId] FROM [Common].[Split] S
						INNER JOIN	@splitEntityCodes		X	ON	S.[SplitEntityCode]	LIKE X.[SplitEntityCode]
					)	S	ON	X.[Id]	= S.[SplitId]
					WHERE S.[SplitId] IS NULL;
				ELSE
					DELETE X FROM @split	X
					LEFT JOIN
					(
						SELECT DISTINCT S.[SplitId] FROM [Common].[Split] S
						LEFT JOIN	@splitEntityCodes		X	ON	S.[SplitEntityCode]	LIKE X.[SplitEntityCode]
						WHERE X.[SplitEntityCode] IS NULL
					)	S	ON	X.[Id]	= S.[SplitId]
					WHERE S.[SplitId] IS NULL;
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
					INSERT @split SELECT DISTINCT S.[SplitId] FROM [Common].[Split] S
					INNER JOIN	@names	X	ON	S.[SplitName]	LIKE X.[Name];
				ELSE 
					INSERT @split SELECT DISTINCT S.[SplitId] FROM [Common].[Split] S
					LEFT JOIN	@names	X	ON	S.[SplitName]	LIKE X.[Name]
					WHERE X.[Name] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @split	X
					LEFT JOIN
					(
						SELECT DISTINCT S.[SplitId] FROM [Common].[Split] S
						INNER JOIN	@names	X	ON	S.[SplitName]	LIKE X.[Name]
					)	S	ON	X.[Id]	= S.[SplitId]
					WHERE S.[SplitId] IS NULL;
				ELSE
					DELETE X FROM @split	X
					LEFT JOIN
					(
						SELECT DISTINCT S.[SplitId] FROM [Common].[Split] S
						LEFT JOIN	@names	X	ON	S.[SplitName]	LIKE X.[Name]
						WHERE X.[Name] IS NULL
					)	S	ON	X.[Id]	= S.[SplitId]
					WHERE S.[SplitId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by system status
	DECLARE @isSystem BIT;
	SET @isSystem = [Common].[Bool.Entity](@predicate.query('/*/IsSystem'));
	IF (@isSystem IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @split SELECT S.[SplitId] FROM [Common].[Split] S
			WHERE S.[SplitIsSystem] = @isSystem;
		ELSE
			DELETE X FROM @split	X
			LEFT JOIN
			(
				SELECT S.[SplitId] FROM [Common].[Split] S
				WHERE S.[SplitIsSystem] = @isSystem
			)	S	ON	X.[Id]	= S.[SplitId]
			WHERE S.[SplitId]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by exclusive status
	DECLARE @isExclusive BIT;
	SET @isExclusive = [Common].[Bool.Entity](@predicate.query('/*/IsExclusive'));
	IF (@isExclusive IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @split SELECT S.[SplitId] FROM [Common].[Split] S
			WHERE S.[SplitIsExclusive] = @isExclusive;
		ELSE
			DELETE X FROM @split	X
			LEFT JOIN
			(
				SELECT S.[SplitId] FROM [Common].[Split] S
				WHERE S.[SplitIsExclusive] = @isExclusive
			)	S	ON	X.[Id]	= S.[SplitId]
			WHERE S.[SplitId]	IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @split X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Common].[Split] S;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @split X;
		ELSE
			SELECT @number = COUNT(*) FROM [Common].[Split]	S
			LEFT JOIN	@split								X	ON	S.[SplitId]	= X.[Id]
			WHERE 
				S.[SplitEmplacementId]	= ISNULL(@emplacementId, S.[SplitEmplacementId])	AND
				X.[Id] IS NULL;

END
GO
