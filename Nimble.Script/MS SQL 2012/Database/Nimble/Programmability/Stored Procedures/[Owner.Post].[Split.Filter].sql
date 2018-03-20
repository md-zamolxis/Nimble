SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Post'	AND
			O.[type]	= 'P'			AND
			O.[name]	= 'Split.Filter'))
	DROP PROCEDURE [Owner.Post].[Split.Filter];
GO

CREATE PROCEDURE [Owner.Post].[Split.Filter]
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/PostSplits')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/PostSplit');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Owner.Post].[Split.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @split SELECT * FROM @entities;
				ELSE
					INSERT @split SELECT S.[SplitId] FROM [Owner.Post].[Split] S
					WHERE S.[SplitId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @split X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @split X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

--	Filter by organisation predicate
	DECLARE 
		@organisationPredicate		XML,
		@organisationIsCountable	BIT,
		@organisationGuids			XML,
		@organisationIsFiltered		BIT,
		@organisationNumber			INT;
	SELECT 
		@organisationPredicate		= X.[Criteria],
		@organisationIsCountable	= 0,
		@criteriaExist				= X.[CriteriaExist],
		@isExcluded					= X.[CriteriaIsExcluded],
		@criteriaIsNull				= X.[CriteriaIsNull],
		@criteriaValue				= X.[CriteriaValue],
		@criteriaValueExist			= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/OrganisationPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @organisation TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner].[Organisation.Filter]
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
			@predicate		= @organisationPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @organisationIsCountable,
			@guids			= @organisationGuids		OUTPUT,
			@isExcluded		= @isExcluded				OUTPUT,
			@isFiltered		= @organisationIsFiltered	OUTPUT,
			@number			= @organisationNumber		OUTPUT;
		INSERT @organisation SELECT * FROM [Common].[Guid.Entities](@organisationGuids);
		IF (@organisationIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @split SELECT S.[SplitId] FROM [Owner.Post].[Split] S
					INNER JOIN	@organisation	X	ON	S.[SplitOrganisationId]	= X.[Id];
				ELSE
					INSERT @split SELECT S.[SplitId] FROM [Owner.Post].[Split] S
					LEFT JOIN	@organisation	X	ON	S.[SplitOrganisationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @split	X
					LEFT JOIN
					(
						SELECT S.[SplitId] FROM [Owner.Post].[Split] S
						INNER JOIN	@organisation	X	ON	S.[SplitOrganisationId]	= X.[Id]
					)	S	ON	X.[Id]	= S.[SplitId]
					WHERE S.[SplitId] IS NULL;
				ELSE
					DELETE X FROM @split	X
					LEFT JOIN
					(
						SELECT S.[SplitId] FROM [Owner.Post].[Split] S
						LEFT JOIN	@organisation	X	ON	S.[SplitOrganisationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	S	ON	X.[Id]	= S.[SplitId]
					WHERE S.[SplitId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@organisations IS NOT NULL) BEGIN
		INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
		IF (@isFiltered = 0)
			INSERT @split SELECT S.[SplitId] FROM [Owner.Post].[Split] S
			INNER JOIN	@organisationIds		XO	ON	S.[SplitOrganisationId]	= XO.[Id];
		ELSE
			DELETE X FROM @split				X 
			INNER JOIN	[Owner.Post].[Split]	S	ON	X.[Id]					= S.[SplitId]
			LEFT JOIN	@organisationIds		XO	ON	S.[SplitOrganisationId]	= XO.[Id]
			WHERE XO.[Id] IS NULL;
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
					INSERT @split SELECT DISTINCT S.[SplitId] FROM [Owner.Post].[Split] S
					INNER JOIN	@codes	X	ON	S.[SplitCode]	LIKE X.[Code];
				ELSE 
					INSERT @split SELECT DISTINCT S.[SplitId] FROM [Owner.Post].[Split] S
					LEFT JOIN	@codes	X	ON	S.[SplitCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @split	X
					LEFT JOIN
					(
						SELECT DISTINCT S.[SplitId] FROM [Owner.Post].[Split] S
						INNER JOIN	@codes	X	ON	S.[SplitCode]	LIKE X.[Code]
					)	S	ON	X.[Id]	= S.[SplitId]
					WHERE S.[SplitId] IS NULL;
				ELSE
					DELETE X FROM @split	X
					LEFT JOIN
					(
						SELECT DISTINCT S.[SplitId] FROM [Owner.Post].[Split] S
						LEFT JOIN	@codes	X	ON	S.[SplitCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	S	ON	X.[Id]	= S.[SplitId]
					WHERE S.[SplitId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by split post types
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/SplitPostTypes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @splitPostTypes TABLE ([SplitPostType] NVARCHAR(MAX));
		INSERT @splitPostTypes SELECT DISTINCT * FROM [Common].[Enum.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @split SELECT DISTINCT S.[SplitId] FROM [Owner.Post].[Split] S
					INNER JOIN	@splitPostTypes	X	ON	S.[SplitPostType]	LIKE X.[SplitPostType];
				ELSE 
					INSERT @split SELECT DISTINCT S.[SplitId] FROM [Owner.Post].[Split] S
					LEFT JOIN	@splitPostTypes	X	ON	S.[SplitPostType]	LIKE X.[SplitPostType]
					WHERE X.[SplitPostType] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @split	X
					LEFT JOIN
					(
						SELECT DISTINCT S.[SplitId] FROM [Owner.Post].[Split] S
						INNER JOIN	@splitPostTypes		X	ON	S.[SplitPostType]	LIKE X.[SplitPostType]
					)	S	ON	X.[Id]	= S.[SplitId]
					WHERE S.[SplitId] IS NULL;
				ELSE
					DELETE X FROM @split	X
					LEFT JOIN
					(
						SELECT DISTINCT S.[SplitId] FROM [Owner.Post].[Split] S
						LEFT JOIN	@splitPostTypes		X	ON	S.[SplitPostType]	LIKE X.[SplitPostType]
						WHERE X.[SplitPostType] IS NULL
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
					INSERT @split SELECT DISTINCT S.[SplitId] FROM [Owner.Post].[Split] S
					INNER JOIN	@names	X	ON	S.[SplitName]	LIKE X.[Name];
				ELSE 
					INSERT @split SELECT DISTINCT S.[SplitId] FROM [Owner.Post].[Split] S
					LEFT JOIN	@names	X	ON	S.[SplitName]	LIKE X.[Name]
					WHERE X.[Name] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @split	X
					LEFT JOIN
					(
						SELECT DISTINCT S.[SplitId] FROM [Owner.Post].[Split] S
						INNER JOIN	@names	X	ON	S.[SplitName]	LIKE X.[Name]
					)	S	ON	X.[Id]	= S.[SplitId]
					WHERE S.[SplitId] IS NULL;
				ELSE
					DELETE X FROM @split	X
					LEFT JOIN
					(
						SELECT DISTINCT S.[SplitId] FROM [Owner.Post].[Split] S
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
			INSERT @split SELECT S.[SplitId] FROM [Owner.Post].[Split] S
			WHERE S.[SplitIsSystem] = @isSystem;
		ELSE
			DELETE X FROM @split	X
			LEFT JOIN
			(
				SELECT S.[SplitId] FROM [Owner.Post].[Split] S
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
			INSERT @split SELECT S.[SplitId] FROM [Owner.Post].[Split] S
			WHERE S.[SplitIsExclusive] = @isExclusive;
		ELSE
			DELETE X FROM @split	X
			LEFT JOIN
			(
				SELECT S.[SplitId] FROM [Owner.Post].[Split] S
				WHERE S.[SplitIsExclusive] = @isExclusive
			)	S	ON	X.[Id]	= S.[SplitId]
			WHERE S.[SplitId]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @split SELECT S.[SplitId] FROM [Owner.Post].[Split] S
			INNER JOIN	[Owner].[Organisation]	O	ON	S.[SplitOrganisationId]	= O.[OrganisationId]
			WHERE O.[OrganisationEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @split	X
			LEFT JOIN	(
				SELECT S.[SplitId] FROM [Owner.Post].[Split] S
				INNER JOIN	[Owner].[Organisation]	O	ON	S.[SplitOrganisationId]	= O.[OrganisationId]
				WHERE O.[OrganisationEmplacementId] = @emplacementId
			)	S	ON	X.[Id]	= S.[SplitId]
			WHERE S.[SplitId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @split X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Owner.Post].[Split] S;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @split X;
		ELSE
			IF (@organisations IS NULL)      
				SELECT @number = COUNT(*) FROM [Owner.Post].[Split]	S
				INNER JOIN	[Owner].[Organisation]	O	ON	S.[SplitOrganisationId]	= O.[OrganisationId]
				LEFT JOIN	@split					X	ON	S.[SplitId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId]	= ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE
				SELECT @number = COUNT(*) FROM [Owner.Post].[Split]	S
				INNER JOIN	[Owner].[Organisation]	O	ON	S.[SplitOrganisationId]	= O.[OrganisationId]
				INNER JOIN	@organisationIds		XO	ON	O.[OrganisationId]		= XO.[Id]
				LEFT JOIN	@split					X	ON	S.[SplitId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;

END
GO
