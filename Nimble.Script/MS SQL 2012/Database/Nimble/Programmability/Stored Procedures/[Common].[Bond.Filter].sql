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
			O.[name]	= 'Bond.Filter'))
	DROP PROCEDURE [Common].[Bond.Filter];
GO

CREATE PROCEDURE [Common].[Bond.Filter]
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

	DECLARE @bond TABLE
	(
		[EntityId]	UNIQUEIDENTIFIER,
		[GroupId]	UNIQUEIDENTIFIER,
		PRIMARY KEY CLUSTERED 
		(
			[EntityId],
			[GroupId]
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Bonds')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Bond');
		DECLARE @entities TABLE 
		(
			[EntityId] UNIQUEIDENTIFIER,
			[GroupId]	UNIQUEIDENTIFIER
		);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.*
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Common].[Bond.Entity](X.[Entity]) E
		) E
		WHERE E.[EntityId] IS NOT NULL AND E.[GroupId] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @bond SELECT * FROM @entities;
				ELSE
					INSERT @bond SELECT 
						B.[BondEntityId]	[EntityId],
						B.[BondGroupId]		[GroupId]
					FROM [Common].[Bond]	B
					LEFT JOIN	@entities	X	ON	B.[BondEntityId]	= X.[EntityId]	AND
													B.[BondGroupId]		= X.[GroupId]
					WHERE X.[EntityId] IS NULL OR X.[GroupId] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @bond		X 
					LEFT JOIN	@entities	B	ON	X.[EntityId]	= B.[EntityId]	AND
													X.[GroupId]		= B.[GroupId]
					WHERE B.[EntityId] IS NULL OR B.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @bond X 
					LEFT JOIN
					(
						SELECT 
							B.[BondEntityId]	[EntityId],
							B.[BondGroupId]		[GroupId]
						FROM [Common].[Bond]	B
						LEFT JOIN	@entities	X	ON	B.[BondEntityId]	= X.[EntityId]	AND
														B.[BondGroupId]		= X.[GroupId]
						WHERE X.[EntityId] IS NULL OR X.[GroupId] IS NULL
					)	B	ON	X.[EntityId]	= B.[EntityId]	AND
								X.[GroupId]		= B.[GroupId]
					WHERE B.[EntityId] IS NULL OR B.[GroupId] IS NULL;
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
					INSERT @bond SELECT
						B.[BondEntityId]	[EntityId],
						B.[BondGroupId]		[GroupId]
					FROM [Common].[Bond]	B
					INNER JOIN	@branch			X	ON	B.[BondEntityId]	= X.[Id];
				ELSE
					INSERT @bond SELECT
						B.[BondEntityId]	[EntityId],
						B.[BondGroupId]		[GroupId]
					FROM [Common].[Bond]	B
					LEFT JOIN	@branch			X	ON	B.[BondEntityId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @bond	X
					LEFT JOIN
					(
						SELECT
							B.[BondEntityId]	[EntityId],
							B.[BondGroupId]		[GroupId]
						FROM [Common].[Bond]	B
						INNER JOIN	@branch			X	ON	B.[BondEntityId]	= X.[Id]
					)	B	ON	X.[EntityId]	= B.[EntityId]	AND
								X.[GroupId]		= B.[GroupId]
					WHERE B.[EntityId] IS NULL OR B.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @bond	X
					LEFT JOIN
					(
						SELECT
							B.[BondEntityId]	[EntityId],
							B.[BondGroupId]		[GroupId]
						FROM [Common].[Bond]	B
						LEFT JOIN	@branch			X	ON	B.[BondEntityId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	B	ON	X.[EntityId]	= B.[EntityId]	AND
								X.[GroupId]		= B.[GroupId]
					WHERE B.[EntityId] IS NULL OR B.[GroupId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by group predicate
	DECLARE 
		@groupPredicate		XML,
		@groupIsCountable	BIT,
		@groupGuids			XML,
		@groupIsFiltered	BIT,
		@groupNumber		INT;
	SELECT 
		@groupPredicate		= X.[Criteria],
		@groupIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/GroupPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @group TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Common].[Group.Filter]
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
			@guids			XML	OUTPUT,
			@isExcluded		BIT OUTPUT,
			@isFiltered		BIT OUTPUT,
			@number			INT OUTPUT',
			@predicate		= @groupPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @groupIsCountable,
			@guids			= @groupGuids		OUTPUT,
			@isExcluded		= @isExcluded		OUTPUT,
			@isFiltered		= @groupIsFiltered	OUTPUT,
			@number			= @groupNumber		OUTPUT;
		INSERT @group SELECT * FROM [Common].[Guid.Entities](@groupGuids);
		IF (@groupIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @bond SELECT
						B.[BondEntityId]	[EntityId],
						B.[BondGroupId]		[GroupId]
					FROM [Common].[Bond]	B
					INNER JOIN	@group		X	ON	B.[BondGroupId]	= X.[Id];
				ELSE
					INSERT @bond SELECT
						B.[BondEntityId]	[EntityId],
						B.[BondGroupId]		[GroupId]
					FROM [Common].[Bond]	B
					LEFT JOIN	@group		X	ON	B.[BondGroupId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @bond	X
					LEFT JOIN
					(
						SELECT
							B.[BondEntityId]	[EntityId],
							B.[BondGroupId]		[GroupId]
						FROM [Common].[Bond]	B
						INNER JOIN	@group		X	ON	B.[BondGroupId]	= X.[Id]
					)	B	ON	X.[EntityId]	= B.[EntityId]	AND
								X.[GroupId]		= B.[GroupId]
					WHERE B.[EntityId] IS NULL OR B.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @bond	X
					LEFT JOIN
					(
						SELECT
							B.[BondEntityId]	[EntityId],
							B.[BondGroupId]		[GroupId]
						FROM [Common].[Bond]	B
						LEFT JOIN	@group		X	ON	B.[BondGroupId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	B	ON	X.[EntityId]	= B.[EntityId]	AND
								X.[GroupId]		= B.[GroupId]
					WHERE B.[EntityId] IS NULL OR B.[GroupId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @bond SELECT
				B.[BondEntityId]	[EntityId],
				B.[BondGroupId]		[GroupId]
			FROM [Common].[Bond]			B
			INNER JOIN	[Common].[Group]	G	ON	B.[BondGroupId]		= G.[GroupId]
			INNER JOIN	[Common].[Split]	S	ON	G.[GroupSplitId]	= S.[SplitId]
			WHERE S.[SplitEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @bond	X
			LEFT JOIN	
			(
				SELECT
					B.[BondEntityId]	[EntityId],
					B.[BondGroupId]		[GroupId]
				FROM [Common].[Bond]			B
				INNER JOIN	[Common].[Group]	G	ON	B.[BondGroupId]		= G.[GroupId]
				INNER JOIN	[Common].[Split]	S	ON	G.[GroupSplitId]	= S.[SplitId]
				WHERE S.[SplitEmplacementId] = @emplacementId
			)	B	ON	X.[EntityId]	= B.[EntityId]	AND
						X.[GroupId]		= B.[GroupId]
			WHERE B.[EntityId] IS NULL OR B.[GroupId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT * FROM @bond X FOR XML PATH('guid'), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Common].[Bond] B;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @bond X;
		ELSE
			SELECT @number = COUNT(*) FROM [Common].[Bond] B
			INNER JOIN	[Common].[Group]	G	ON	B.[BondGroupId]		= G.[GroupId]
			INNER JOIN	[Common].[Split]	S	ON	G.[GroupSplitId]	= S.[SplitId]
			LEFT JOIN	@bond				X	ON	B.[BondEntityId]	= X.[EntityId]	AND
													B.[BondGroupId]		= X.[GroupId]
			WHERE 
				S.[SplitEmplacementId]	= ISNULL(@emplacementId, S.[SplitEmplacementId])	AND
				(X.[EntityId] IS NULL OR X.[GroupId] IS NULL);

END
GO
