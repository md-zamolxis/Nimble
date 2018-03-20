SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Branch'	AND
			O.[type]	= 'P'				AND
			O.[name]	= 'Group.Filter'))
	DROP PROCEDURE [Owner.Branch].[Group.Filter];
GO

CREATE PROCEDURE [Owner.Branch].[Group.Filter]
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
		@amountFrom			DECIMAL(28, 9),
		@amountTo			DECIMAL(28, 9),
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/BranchGroups')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/BranchGroup');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Owner.Branch].[Group.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @group SELECT * FROM @entities;
				ELSE
					INSERT @group SELECT G.[GroupId] FROM [Owner.Branch].[Group] G
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/BranchSplitPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @split TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner.Branch].[Split.Filter]
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
					INSERT @group SELECT G.[GroupId] FROM [Owner.Branch].[Group] G
					INNER JOIN	@split	X	ON	G.[GroupSplitId]	= X.[Id];
				ELSE
					INSERT @group SELECT G.[GroupId] FROM [Owner.Branch].[Group] G
					LEFT JOIN	@split	X	ON	G.[GroupSplitId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT G.[GroupId] FROM [Owner.Branch].[Group] G
						INNER JOIN	@split	X	ON	G.[GroupSplitId]	= X.[Id]
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT G.[GroupId] FROM [Owner.Branch].[Group] G
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
			INSERT @group SELECT G.[GroupId] FROM [Owner.Branch].[Group] G
			INNER JOIN	[Owner.Branch].[Split]	S	ON	G.[GroupSplitId]		= S.[SplitId]
			INNER JOIN	@organisationIds		XO	ON	S.[SplitOrganisationId]	= XO.[Id];
		ELSE
			DELETE X FROM @group				X
			INNER JOIN	[Owner.Branch].[Group]	G	ON	X.[Id]					= G.[GroupId]
			INNER JOIN	[Owner.Branch].[Split]	S	ON	G.[GroupSplitId]		= S.[SplitId]
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
					INSERT @group SELECT DISTINCT G.[GroupId] FROM [Owner.Branch].[Group] G
					INNER JOIN	@codes	X	ON	G.[GroupCode]	LIKE X.[Code];
				ELSE 
					INSERT @group SELECT DISTINCT G.[GroupId] FROM [Owner.Branch].[Group] G
					LEFT JOIN	@codes	X	ON	G.[GroupCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT DISTINCT G.[GroupId] FROM [Owner.Branch].[Group] G
						INNER JOIN	@codes	X	ON	G.[GroupCode]	LIKE X.[Code]
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT DISTINCT G.[GroupId] FROM [Owner.Branch].[Group] G
						LEFT JOIN	@codes	X	ON	G.[GroupCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by index
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Index')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @amountFrom = NULL, @amountTo = NULL;
		SELECT 
			@amountFrom	= X.[AmountFrom], 
			@amountTo	= X.[AmountTo] 
		FROM [Common].[AmountInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@amountFrom, @amountTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @group SELECT G.[GroupId] FROM [Owner.Branch].[Group] G
					WHERE G.[GroupIndex] BETWEEN ISNULL(@amountFrom, G.[GroupIndex]) AND ISNULL(@amountTo, G.[GroupIndex]);
				ELSE 
					INSERT @group SELECT G.[GroupId] FROM [Owner.Branch].[Group] G
					WHERE G.[GroupIndex] NOT BETWEEN ISNULL(@amountFrom, G.[GroupIndex]) AND ISNULL(@amountTo, G.[GroupIndex]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT G.[GroupId] FROM [Owner.Branch].[Group] G
						WHERE G.[GroupIndex] BETWEEN ISNULL(@amountFrom, G.[GroupIndex]) AND ISNULL(@amountTo, G.[GroupIndex])
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT G.[GroupId] FROM [Owner.Branch].[Group] G
						WHERE G.[GroupIndex] NOT BETWEEN ISNULL(@amountFrom, G.[GroupIndex]) AND ISNULL(@amountTo, G.[GroupIndex])
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by default status
	DECLARE @isDefault BIT;
	SET @isDefault = [Common].[Bool.Entity](@predicate.query('/*/IsDefault'));
	IF (@isDefault IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @group SELECT G.[GroupId] FROM [Owner.Branch].[Group] G
			WHERE G.[GroupIsDefault] = @isDefault;
		ELSE
			DELETE X FROM @group	X
			LEFT JOIN
			(
				SELECT G.[GroupId] FROM [Owner.Branch].[Group] G
				WHERE G.[GroupIsDefault] = @isDefault
			)	G	ON	X.[Id]	= G.[GroupId]
			WHERE G.[GroupId]	IS NULL;
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
					INSERT @group SELECT DISTINCT G.[GroupId] FROM [Owner.Branch].[Group] G
					INNER JOIN	@names	X	ON	G.[GroupName]	LIKE X.[Name];
				ELSE 
					INSERT @group SELECT DISTINCT G.[GroupId] FROM [Owner.Branch].[Group] G
					LEFT JOIN	@names	X	ON	G.[GroupName]	LIKE X.[Name]
					WHERE X.[Name] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT DISTINCT G.[GroupId] FROM [Owner.Branch].[Group] G
						INNER JOIN	@names	X	ON	G.[GroupName]	LIKE X.[Name]
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT DISTINCT G.[GroupId] FROM [Owner.Branch].[Group] G
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
					INSERT @group SELECT DISTINCT G.[GroupId] FROM [Owner.Branch].[Group] G
					INNER JOIN	@descriptions	X	ON	G.[GroupDescription]	LIKE X.[Description];
				ELSE 
					INSERT @group SELECT DISTINCT G.[GroupId] FROM [Owner.Branch].[Group] G
					LEFT JOIN	@descriptions	X	ON	G.[GroupDescription]	LIKE X.[Description]
					WHERE X.[Description] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT DISTINCT G.[GroupId] FROM [Owner.Branch].[Group] G
						INNER JOIN	@descriptions	X	ON	G.[GroupDescription]	LIKE X.[Description]
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT DISTINCT G.[GroupId] FROM [Owner.Branch].[Group] G
						LEFT JOIN	@descriptions	X	ON	G.[GroupDescription]	LIKE X.[Description]
						WHERE X.[Description] IS NULL
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by branch predicate
	DECLARE 
		@branchPredicate	XML,
		@branchIsCountable	BIT,
		@branchGuids		XML,
		@branchIsFiltered	BIT,
		@branchNumber		INT;
	SELECT 
		@branchPredicate	= X.[Criteria],
		@branchIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/BranchPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @branch TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner].[Branch.Filter]
			@predicate,
			@emplacementId,
			@applicationId,
			@organisations,
			@branches,
			@isCountable,
			@guids		OUTPUT,
			@isExcluded OUTPUT,
			@isFiltered OUTPUT,
			@number		OUTPUT',
			N'@predicate	XML,
			@emplacementId	UNIQUEIDENTIFIER,
			@applicationId	UNIQUEIDENTIFIER,
			@organisations	XML,
			@branches		XML,
			@isCountable	BIT,
			@guids			XML OUTPUT,
			@isExcluded		BIT OUTPUT,
			@isFiltered		BIT OUTPUT,
			@number			INT OUTPUT',
			@predicate		= @branchPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@branches		= NULL,
			@isCountable	= @branchIsCountable,
			@guids			= @branchGuids		OUTPUT,
			@isExcluded		= @isExcluded		OUTPUT,
			@isFiltered		= @branchIsFiltered	OUTPUT,
			@number			= @branchNumber		OUTPUT;
		INSERT @branch SELECT * FROM [Common].[Guid.Entities](@branchGuids);
		IF (@branchIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @group SELECT DISTINCT B.[BondGroupId] FROM [Owner.Branch].[Bond] B
					INNER JOIN	@branch	X	ON	B.[BondBranchId]	= X.[Id];
				ELSE
					INSERT @group SELECT DISTINCT B.[BondGroupId] FROM [Owner.Branch].[Bond] B
					LEFT JOIN	@branch	X	ON	B.[BondBranchId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT DISTINCT B.[BondGroupId] [GroupId]
						FROM [Owner.Branch].[Bond] B
						INNER JOIN	@branch	X	ON	B.[BondBranchId]	= X.[Id]
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @group	X
					LEFT JOIN
					(
						SELECT DISTINCT B.[BondGroupId] [GroupId]
						FROM [Owner.Branch].[Bond] B
						LEFT JOIN	@branch	X	ON	B.[BondBranchId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	G	ON	X.[Id]	= G.[GroupId]
					WHERE G.[GroupId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @group SELECT G.[GroupId] FROM [Owner.Branch].[Group]	G
			INNER JOIN	[Owner.Branch].[Split]								S	ON	G.[GroupSplitId]		= S.[SplitId]
			INNER JOIN	[Owner].[Organisation]								O	ON	S.[SplitOrganisationId] = O.[OrganisationId]
			WHERE O.[OrganisationEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @group	X
			LEFT JOIN	(
				SELECT G.[GroupId] FROM [Owner.Branch].[Group]	G
				INNER JOIN	[Owner.Branch].[Split]				S	ON	G.[GroupSplitId]		= S.[SplitId]
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
		SELECT @number = COUNT(*) FROM [Owner.Branch].[Group] G;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @group X;
		ELSE
			IF (@organisations IS NULL)      
				SELECT @number = COUNT(*) FROM [Owner.Branch].[Group]	G
				INNER JOIN	[Owner.Branch].[Split]	S	ON	G.[GroupSplitId]		= S.[SplitId]
				INNER JOIN	[Owner].[Organisation]	O	ON	S.[SplitOrganisationId]	= O.[OrganisationId]
				LEFT JOIN	@group					X	ON	G.[GroupId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId]	= ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE
				SELECT @number = COUNT(*) FROM [Owner.Branch].[Group]	G
				INNER JOIN	[Owner.Branch].[Split]	S	ON	G.[GroupSplitId]		= S.[SplitId]
				INNER JOIN	[Owner].[Organisation]	O	ON	S.[SplitOrganisationId]	= O.[OrganisationId]
				INNER JOIN	@organisationIds		XO	ON	O.[OrganisationId]		= XO.[Id]
				LEFT JOIN	@group					X	ON	G.[GroupId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;

END
GO
