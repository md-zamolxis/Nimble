SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Post'	AND
			O.[type]	= 'P'				AND
			O.[name]	= 'Group.Filter'))
	DROP PROCEDURE [Owner.Post].[Group.Filter];
GO

CREATE PROCEDURE [Owner.Post].[Group.Filter]
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
	
	DECLARE @group TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/PostGroups')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/PostGroup');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Owner.Post].[Group.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @group SELECT * FROM @entities;
				ELSE
					INSERT @group SELECT G.[GroupId] FROM [Owner.Post].[Group] G
					WHERE G.[GroupId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @group X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

--	Filter by split predicate
	DECLARE 
		@splitPredicate		XML,
		@splitIsCountable	BIT,
		@splitGuids			XML,
		@splitIsFiltered	BIT,
		@splitNumber		INT;
	SELECT 
		@splitPredicate		= X.[Criteria],
		@splitIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/PostSplitPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @split TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner.Post].[Split.Filter]
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
			@predicate		= @splitPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @splitIsCountable,
			@guids			= @splitGuids		OUTPUT,
			@isExcluded		= @isExcluded		OUTPUT,
			@isFiltered		= @splitIsFiltered	OUTPUT,
			@number			= @splitNumber		OUTPUT;
		INSERT @split SELECT * FROM [Common].[Guid.Entities](@splitGuids);
		IF (@splitIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @group SELECT G.[GroupId] FROM [Owner.Post].[Group] G
					INNER JOIN	@split	X	ON	G.[GroupSplitId]	= X.[Id];
				ELSE
					INSERT @group SELECT G.[GroupId] FROM [Owner.Post].[Group] G
					LEFT JOIN	@split	X	ON	G.[GroupSplitId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT G.[GroupId] FROM [Owner.Post].[Group] G
						INNER JOIN	@split	X	ON	G.[GroupSplitId]	= X.[Id]
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT G.[GroupId] FROM [Owner.Post].[Group] G
						LEFT JOIN	@split	X	ON	G.[GroupSplitId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@organisations IS NOT NULL) BEGIN
		INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
		IF (@isFiltered = 0)
			INSERT @group SELECT G.[GroupId] FROM [Owner.Post].[Group]	G
			INNER JOIN	[Owner.Post].[Split]	S	ON	G.[GroupSplitId]		= S.[SplitId]
			INNER JOIN	@organisationIds		XO	ON	S.[SplitOrganisationId]	= XO.[Id];
		ELSE
			DELETE X FROM @group				X
			INNER JOIN	[Owner.Post].[Group]	G	ON	X.[Id]					= G.[GroupId]
			INNER JOIN	[Owner.Post].[Split]	S	ON	G.[GroupSplitId]		= S.[SplitId]
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
					INSERT @group SELECT DISTINCT G.[GroupId] FROM [Owner.Post].[Group] G
					INNER JOIN	@codes	X	ON	G.[GroupCode]	LIKE X.[Code];
				ELSE 
					INSERT @group SELECT DISTINCT G.[GroupId] FROM [Owner.Post].[Group] G
					LEFT JOIN	@codes	X	ON	G.[GroupCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT DISTINCT G.[GroupId] FROM [Owner.Post].[Group] G
						INNER JOIN	@codes	X	ON	G.[GroupCode]	LIKE X.[Code]
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT DISTINCT G.[GroupId] FROM [Owner.Post].[Group] G
						LEFT JOIN	@codes	X	ON	G.[GroupCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
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
					INSERT @group SELECT DISTINCT G.[GroupId] FROM [Owner.Post].[Group] G
					INNER JOIN	@names	X	ON	G.[GroupName]	LIKE X.[Name];
				ELSE 
					INSERT @group SELECT DISTINCT G.[GroupId] FROM [Owner.Post].[Group] G
					LEFT JOIN	@names	X	ON	G.[GroupName]	LIKE X.[Name]
					WHERE X.[Name] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT DISTINCT G.[GroupId] FROM [Owner.Post].[Group] G
						INNER JOIN	@names	X	ON	G.[GroupName]	LIKE X.[Name]
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT DISTINCT G.[GroupId] FROM [Owner.Post].[Group] G
						LEFT JOIN	@names	X	ON	G.[GroupName]	LIKE X.[Name]
						WHERE X.[Name] IS NULL
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
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
					INSERT @group SELECT DISTINCT G.[GroupId] FROM [Owner.Post].[Group] G
					INNER JOIN	@descriptions	X	ON	G.[GroupDescription]	LIKE X.[Description];
				ELSE 
					INSERT @group SELECT DISTINCT G.[GroupId] FROM [Owner.Post].[Group] G
					LEFT JOIN	@descriptions	X	ON	G.[GroupDescription]	LIKE X.[Description]
					WHERE X.[Description] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT DISTINCT G.[GroupId] FROM [Owner.Post].[Group] G
						INNER JOIN	@descriptions	X	ON	G.[GroupDescription]	LIKE X.[Description]
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT DISTINCT G.[GroupId] FROM [Owner.Post].[Group] G
						LEFT JOIN	@descriptions	X	ON	G.[GroupDescription]	LIKE X.[Description]
						WHERE X.[Description] IS NULL
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by default status
	DECLARE @isDefault BIT;
	SET @isDefault = [Common].[Bool.Entity](@predicate.query('/*/IsDefault'));
	IF (@isDefault IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @group SELECT G.[GroupId] FROM [Owner.Post].[Group] G
			WHERE G.[GroupIsDefault] = @isDefault;
		ELSE
			DELETE X FROM @group	X
			LEFT JOIN
			(
				SELECT G.[GroupId] FROM [Owner.Post].[Group] G
				WHERE G.[GroupIsDefault] = @isDefault
			)	G	ON	X.[Id]	= G.[GroupId]
			WHERE G.[GroupId]	IS NULL;
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
					INSERT @group SELECT G.[GroupId] FROM [Owner.Post].[Group] G
					WHERE G.[GroupCreatedOn] BETWEEN ISNULL(@dateFrom, G.[GroupCreatedOn]) AND ISNULL(@dateTo, G.[GroupCreatedOn]);
				ELSE 
					INSERT @group SELECT G.[GroupId] FROM [Owner.Post].[Group] G
					WHERE G.[GroupCreatedOn] NOT BETWEEN ISNULL(@dateFrom, G.[GroupCreatedOn]) AND ISNULL(@dateTo, G.[GroupCreatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT G.[GroupId] FROM [Owner.Post].[Group] G
						WHERE G.[GroupCreatedOn] BETWEEN ISNULL(@dateFrom, G.[GroupCreatedOn]) AND ISNULL(@dateTo, G.[GroupCreatedOn])
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT G.[GroupId] FROM [Owner.Post].[Group] G
						WHERE G.[GroupCreatedOn] NOT BETWEEN ISNULL(@dateFrom, G.[GroupCreatedOn]) AND ISNULL(@dateTo, G.[GroupCreatedOn])
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by updated datetime offset
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/UpdatedOn')) X;
	IF (@criteriaExist = 1) BEGIN
		SELECT @dateFrom = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @group SELECT G.[GroupId] FROM [Owner.Post].[Group] G
					WHERE G.[GroupUpdatedOn] BETWEEN ISNULL(@dateFrom, G.[GroupUpdatedOn]) AND ISNULL(@dateTo, G.[GroupUpdatedOn]);
				ELSE 
					INSERT @group SELECT G.[GroupId] FROM [Owner.Post].[Group] G
					WHERE G.[GroupUpdatedOn] NOT BETWEEN ISNULL(@dateFrom, G.[GroupUpdatedOn]) AND ISNULL(@dateTo, G.[GroupUpdatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT G.[GroupId] FROM [Owner.Post].[Group] G
						WHERE G.[GroupUpdatedOn] BETWEEN ISNULL(@dateFrom, G.[GroupUpdatedOn]) AND ISNULL(@dateTo, G.[GroupUpdatedOn])
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT G.[GroupId] FROM [Owner.Post].[Group] G
						WHERE G.[GroupUpdatedOn] NOT BETWEEN ISNULL(@dateFrom, G.[GroupUpdatedOn]) AND ISNULL(@dateTo, G.[GroupUpdatedOn])
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
		ELSE
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @group SELECT G.[GroupId] FROM [Owner.Post].[Group] G
					WHERE G.[GroupUpdatedOn] IS NULL;
				ELSE 
					INSERT @group SELECT G.[GroupId] FROM [Owner.Post].[Group] G
					WHERE G.[GroupUpdatedOn] IS NOT NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT G.[GroupId] FROM [Owner.Post].[Group] G
						WHERE G.[GroupUpdatedOn] IS NULL
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT G.[GroupId] FROM [Owner.Post].[Group] G
						WHERE G.[GroupUpdatedOn] IS NOT NULL
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by deleted datetime offset
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/DeletedOn')) X;
	IF (@criteriaExist = 1) BEGIN
		SELECT @dateFrom = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @group SELECT G.[GroupId] FROM [Owner.Post].[Group] G
					WHERE G.[GroupDeletedOn] BETWEEN ISNULL(@dateFrom, G.[GroupDeletedOn]) AND ISNULL(@dateTo, G.[GroupDeletedOn]);
				ELSE 
					INSERT @group SELECT G.[GroupId] FROM [Owner.Post].[Group] G
					WHERE G.[GroupDeletedOn] NOT BETWEEN ISNULL(@dateFrom, G.[GroupDeletedOn]) AND ISNULL(@dateTo, G.[GroupDeletedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT G.[GroupId] FROM [Owner.Post].[Group] G
						WHERE G.[GroupDeletedOn] BETWEEN ISNULL(@dateFrom, G.[GroupDeletedOn]) AND ISNULL(@dateTo, G.[GroupDeletedOn])
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT G.[GroupId] FROM [Owner.Post].[Group] G
						WHERE G.[GroupDeletedOn] NOT BETWEEN ISNULL(@dateFrom, G.[GroupDeletedOn]) AND ISNULL(@dateTo, G.[GroupDeletedOn])
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
		ELSE
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @group SELECT G.[GroupId] FROM [Owner.Post].[Group] G
					WHERE G.[GroupDeletedOn] IS NULL;
				ELSE 
					INSERT @group SELECT G.[GroupId] FROM [Owner.Post].[Group] G
					WHERE G.[GroupDeletedOn] IS NOT NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT G.[GroupId] FROM [Owner.Post].[Group] G
						WHERE G.[GroupDeletedOn] IS NULL
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT G.[GroupId] FROM [Owner.Post].[Group] G
						WHERE G.[GroupDeletedOn] IS NOT NULL
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
		SET @isFiltered = 1;
	END 

--	Filter by post predicate
	DECLARE 
		@postPredicate		XML,
		@postIsCountable	BIT,
		@postGuids			XML,
		@postIsFiltered		BIT,
		@postNumber			INT;
	SELECT 
		@postPredicate		= X.[Criteria],
		@postIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/PostPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @post TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner].[Post.Filter]
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
			@predicate		= @postPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @postIsCountable,
			@guids			= @postGuids		OUTPUT,
			@isExcluded		= @isExcluded		OUTPUT,
			@isFiltered		= @postIsFiltered	OUTPUT,
			@number			= @postNumber		OUTPUT;
		INSERT @post SELECT * FROM [Common].[Guid.Entities](@postGuids);
		IF (@postIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @group SELECT DISTINCT B.[BondGroupId] FROM [Owner.Post].[Bond] B
					INNER JOIN	@post	X	ON	B.[BondPostId]	= X.[Id];
				ELSE
					INSERT @group SELECT DISTINCT B.[BondGroupId] FROM [Owner.Post].[Bond] B
					LEFT JOIN	@post	X	ON	B.[BondPostId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT DISTINCT B.[BondGroupId] [GroupId]
						FROM [Owner.Post].[Bond]	B
						INNER JOIN	@post			X	ON	B.[BondPostId]	= X.[Id]
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT DISTINCT B.[BondGroupId] [GroupId]
						FROM [Owner.Post].[Bond]	B
						LEFT JOIN	@post			X	ON	B.[BondPostId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @group SELECT G.[GroupId] FROM [Owner.Post].[Group]	G
			INNER JOIN	[Owner.Post].[Split]							S	ON	G.[GroupSplitId]		= S.[SplitId]
			INNER JOIN	[Owner].[Organisation]							O	ON	S.[SplitOrganisationId] = O.[OrganisationId]
			WHERE O.[OrganisationEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @group	X
			LEFT JOIN	(
				SELECT G.[GroupId] FROM [Owner.Post].[Group]	G
				INNER JOIN	[Owner.Post].[Split]				S	ON	G.[GroupSplitId]		= S.[SplitId]
				INNER JOIN	[Owner].[Organisation]				O	ON	S.[SplitOrganisationId] = O.[OrganisationId]
				WHERE O.[OrganisationEmplacementId] = @emplacementId
			)	G	ON	X.[Id]	= G.[GroupId]
			WHERE G.[GroupId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @group X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Owner.Post].[Group] G;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @group X;
		ELSE
			IF (@organisations IS NULL)      
				SELECT @number = COUNT(*) FROM [Owner.Post].[Group]	G
				INNER JOIN	[Owner.Post].[Split]	S	ON	G.[GroupSplitId]		= S.[SplitId]
				INNER JOIN	[Owner].[Organisation]	O	ON	S.[SplitOrganisationId]	= O.[OrganisationId]
				LEFT JOIN	@group					X	ON	G.[GroupId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId]	= ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE
				SELECT @number = COUNT(*) FROM [Owner.Post].[Group]	G
				INNER JOIN	[Owner.Post].[Split]	S	ON	G.[GroupSplitId]		= S.[SplitId]
				INNER JOIN	[Owner].[Organisation]	O	ON	S.[SplitOrganisationId]	= O.[OrganisationId]
				INNER JOIN	@organisationIds		XO	ON	O.[OrganisationId]		= XO.[Id]
				LEFT JOIN	@group					X	ON	G.[GroupId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;

END
GO
