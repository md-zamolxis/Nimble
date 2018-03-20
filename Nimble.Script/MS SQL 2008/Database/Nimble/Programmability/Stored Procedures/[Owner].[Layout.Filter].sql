SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner'	AND
			O.[type]	= 'P'		AND
			O.[name]	= 'Layout.Filter'))
	DROP PROCEDURE [Owner].[Layout.Filter];
GO

CREATE PROCEDURE [Owner].[Layout.Filter]
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

	DECLARE @layout TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Layouts')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Layout');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Owner].[Layout.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @layout SELECT * FROM @entities;
				ELSE
					INSERT @layout SELECT L.[LayoutId] FROM [Owner].[Layout] L
					WHERE L.[LayoutId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @layout X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @layout X WHERE X.[Id] IN (SELECT * FROM @entities);
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
					INSERT @layout SELECT L.[LayoutId] FROM [Owner].[Layout] L
					INNER JOIN	@organisation	X	ON	L.[LayoutOrganisationId]	= X.[Id];
				ELSE
					INSERT @layout SELECT L.[LayoutId] FROM [Owner].[Layout] L
					LEFT JOIN	@organisation	X	ON	L.[LayoutOrganisationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @layout	X
					LEFT JOIN
					(
						SELECT L.[LayoutId] FROM [Owner].[Layout] L
						INNER JOIN	@organisation	X	ON	L.[LayoutOrganisationId]	= X.[Id]
					)	L	ON	X.[Id]	= L.[LayoutId]
					WHERE L.[LayoutId] IS NULL;
				ELSE
					DELETE X FROM @layout	X
					LEFT JOIN
					(
						SELECT L.[LayoutId] FROM [Owner].[Layout] L
						LEFT JOIN	@organisation	X	ON	L.[LayoutOrganisationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	L	ON	X.[Id]	= L.[LayoutId]
					WHERE L.[LayoutId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@organisations IS NOT NULL) BEGIN
		INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
		IF (@isFiltered = 0)
			INSERT @layout SELECT L.[LayoutId] FROM [Owner].[Layout] L
			INNER JOIN	@organisationIds	XO	ON	L.[LayoutOrganisationId]	= XO.[Id];
		ELSE
			DELETE X FROM @layout			X 
			INNER JOIN	[Owner].[Layout]	L	ON	X.[Id]						= L.[LayoutId]
			LEFT JOIN	@organisationIds	XO	ON	L.[LayoutOrganisationId]	= XO.[Id]
			WHERE XO.[Id] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by layout entity types
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/LayoutEntityTypes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @layoutEntityTypes TABLE ([LayoutEntityType] NVARCHAR(MAX));
		INSERT @layoutEntityTypes SELECT DISTINCT * FROM [Common].[Enum.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @layout SELECT DISTINCT L.[LayoutId] FROM [Owner].[Layout] L
					INNER JOIN	@layoutEntityTypes	X	ON	L.[LayoutEntityType]	LIKE X.[LayoutEntityType];
				ELSE 
					INSERT @layout SELECT DISTINCT L.[LayoutId] FROM [Owner].[Layout] L
					LEFT JOIN	@layoutEntityTypes	X	ON	L.[LayoutEntityType]	LIKE X.[LayoutEntityType]
					WHERE X.[LayoutEntityType] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @layout	X
					LEFT JOIN
					(
						SELECT DISTINCT L.[LayoutId] FROM [Owner].[Layout] L
						INNER JOIN	@layoutEntityTypes		X	ON	L.[LayoutEntityType]	LIKE X.[LayoutEntityType]
					)	L	ON	X.[Id]	= L.[LayoutId]
					WHERE L.[LayoutId] IS NULL;
				ELSE
					DELETE X FROM @layout	X
					LEFT JOIN
					(
						SELECT DISTINCT L.[LayoutId] FROM [Owner].[Layout] L
						LEFT JOIN	@layoutEntityTypes		X	ON	L.[LayoutEntityType]	LIKE X.[LayoutEntityType]
						WHERE X.[LayoutEntityType] IS NULL
					)	L	ON	X.[Id]	= L.[LayoutId]
					WHERE L.[LayoutId] IS NULL;
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
					INSERT @layout SELECT DISTINCT L.[LayoutId] FROM [Owner].[Layout] L
					INNER JOIN	@codes	X	ON	L.[LayoutCode]	LIKE X.[Code];
				ELSE 
					INSERT @layout SELECT DISTINCT L.[LayoutId] FROM [Owner].[Layout] L
					LEFT JOIN	@codes	X	ON	L.[LayoutCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @layout	X
					LEFT JOIN
					(
						SELECT DISTINCT L.[LayoutId] FROM [Owner].[Layout] L
						INNER JOIN	@codes	X	ON	L.[LayoutCode]	LIKE X.[Code]
					)	L	ON	X.[Id]	= L.[LayoutId]
					WHERE L.[LayoutId] IS NULL;
				ELSE
					DELETE X FROM @layout	X
					LEFT JOIN
					(
						SELECT DISTINCT L.[LayoutId] FROM [Owner].[Layout] L
						LEFT JOIN	@codes	X	ON	L.[LayoutCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	L	ON	X.[Id]	= L.[LayoutId]
					WHERE L.[LayoutId] IS NULL;
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
					INSERT @layout SELECT DISTINCT L.[LayoutId] FROM [Owner].[Layout] L
					INNER JOIN	@names	X	ON	L.[LayoutName]	LIKE X.[Name];
				ELSE 
					INSERT @layout SELECT DISTINCT L.[LayoutId] FROM [Owner].[Layout] L
					LEFT JOIN	@names	X	ON	L.[LayoutName]	LIKE X.[Name]
					WHERE X.[Name] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @layout	X
					LEFT JOIN
					(
						SELECT DISTINCT L.[LayoutId] FROM [Owner].[Layout] L
						INNER JOIN	@names	X	ON	L.[LayoutName]	LIKE X.[Name]
					)	L	ON	X.[Id]	= L.[LayoutId]
					WHERE L.[LayoutId] IS NULL;
				ELSE
					DELETE X FROM @layout	X
					LEFT JOIN
					(
						SELECT DISTINCT L.[LayoutId] FROM [Owner].[Layout] L
						LEFT JOIN	@names	X	ON	L.[LayoutName]	LIKE X.[Name]
						WHERE X.[Name] IS NULL
					)	L	ON	X.[Id]	= L.[LayoutId]
					WHERE L.[LayoutId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by descriptions
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Descriptions')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @descriptions TABLE ([Description] NVARCHAR(MAX));
		INSERT @descriptions SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @layout SELECT DISTINCT L.[LayoutId] FROM [Owner].[Layout] L
					INNER JOIN	@descriptions	X	ON	L.[LayoutDescription]	LIKE X.[Description];
				ELSE 
					INSERT @layout SELECT DISTINCT L.[LayoutId] FROM [Owner].[Layout] L
					LEFT JOIN	@descriptions	X	ON	L.[LayoutDescription]	LIKE X.[Description]
					WHERE X.[Description] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @layout	X
					LEFT JOIN
					(
						SELECT DISTINCT L.[LayoutId] FROM [Owner].[Layout] L
						INNER JOIN	@descriptions	X	ON	L.[LayoutDescription]	LIKE X.[Description]
					)	L	ON	X.[Id]	= L.[LayoutId]
					WHERE L.[LayoutId] IS NULL;
				ELSE
					DELETE X FROM @layout	X
					LEFT JOIN
					(
						SELECT DISTINCT L.[LayoutId] FROM [Owner].[Layout] L
						LEFT JOIN	@descriptions	X	ON	L.[LayoutDescription]	LIKE X.[Description]
						WHERE X.[Description] IS NULL
					)	L	ON	X.[Id]	= L.[LayoutId]
					WHERE L.[LayoutId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @layout SELECT L.[LayoutId] FROM [Owner].[Layout] L
			INNER JOIN	[Owner].[Organisation]	O	ON	L.[LayoutOrganisationId]	= O.[OrganisationId]
			WHERE O.[OrganisationEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @layout	X
			LEFT JOIN	(
				SELECT L.[LayoutId] FROM [Owner].[Layout] L
				INNER JOIN	[Owner].[Organisation]	O	ON	L.[LayoutOrganisationId]	= O.[OrganisationId]
				WHERE O.[OrganisationEmplacementId] = @emplacementId
			)	L	ON	X.[Id]	= L.[LayoutId]
			WHERE L.[LayoutId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @layout X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Owner].[Layout] L;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @layout X;
		ELSE
			IF (@organisations IS NULL)
				SELECT @number = COUNT(*) FROM [Owner].[Layout]	L
				INNER JOIN	[Owner].[Organisation]	O	ON	L.[LayoutOrganisationId]	= O.[OrganisationId]
				LEFT JOIN	@layout					X	ON	L.[LayoutId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId]	= ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE
				SELECT @number = COUNT(*) FROM [Owner].[Layout]	L
				INNER JOIN	[Owner].[Organisation]	O	ON	L.[LayoutOrganisationId]	= O.[OrganisationId]
				INNER JOIN	@organisationIds		XO	ON	O.[OrganisationId]			= XO.[Id]
				LEFT JOIN	@layout					X	ON	L.[LayoutId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;

END
GO
