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
			O.[name]	= 'Bond.Filter'))
	DROP PROCEDURE [Owner.Branch].[Bond.Filter];
GO

CREATE PROCEDURE [Owner.Branch].[Bond.Filter]
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
		[BranchId]	UNIQUEIDENTIFIER,
		[GroupId]	UNIQUEIDENTIFIER,
		PRIMARY KEY CLUSTERED 
		(
			[BranchId],
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/BranchBonds')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/BranchBond');
		DECLARE @entities TABLE 
		(
			[BranchId] UNIQUEIDENTIFIER,
			[GroupId]	UNIQUEIDENTIFIER
		);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.*
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Owner.Branch].[Bond.Entity](X.[Entity]) E
		) E
		WHERE E.[BranchId] IS NOT NULL AND E.[GroupId] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @bond SELECT * FROM @entities;
				ELSE
					INSERT @bond SELECT 
						B.[BondBranchId]	[BranchId],
						B.[BondGroupId]		[GroupId]
					FROM [Owner.Branch].[Bond]	B
					LEFT JOIN	@entities		X	ON	B.[BondBranchId]	= X.[BranchId]	AND
														B.[BondGroupId]		= X.[GroupId]
					WHERE X.[BranchId] IS NULL OR X.[GroupId] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @bond		X 
					LEFT JOIN	@entities	B	ON	X.[BranchId]	= B.[BranchId]	AND
													X.[GroupId]		= B.[GroupId]
					WHERE B.[BranchId] IS NULL OR B.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @bond X 
					LEFT JOIN
					(
						SELECT 
							B.[BondBranchId]	[BranchId],
							B.[BondGroupId]		[GroupId]
						FROM [Owner.Branch].[Bond]	B
						LEFT JOIN	@entities		X	ON	B.[BondBranchId]	= X.[BranchId]	AND
															B.[BondGroupId]		= X.[GroupId]
						WHERE X.[BranchId] IS NULL OR X.[GroupId] IS NULL
					)	B	ON	X.[BranchId]	= B.[BranchId]	AND
								X.[GroupId]		= B.[GroupId]
					WHERE B.[BranchId] IS NULL OR B.[GroupId] IS NULL;
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
						B.[BondBranchId]	[BranchId],
						B.[BondGroupId]		[GroupId]
					FROM [Owner.Branch].[Bond]	B
					INNER JOIN	@branch			X	ON	B.[BondBranchId]	= X.[Id];
				ELSE
					INSERT @bond SELECT
						B.[BondBranchId]	[BranchId],
						B.[BondGroupId]		[GroupId]
					FROM [Owner.Branch].[Bond]	B
					LEFT JOIN	@branch			X	ON	B.[BondBranchId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @bond	X
					LEFT JOIN
					(
						SELECT
							B.[BondBranchId]	[BranchId],
							B.[BondGroupId]		[GroupId]
						FROM [Owner.Branch].[Bond]	B
						INNER JOIN	@branch			X	ON	B.[BondBranchId]	= X.[Id]
					)	B	ON	X.[BranchId]	= B.[BranchId]	AND
								X.[GroupId]		= B.[GroupId]
					WHERE B.[BranchId] IS NULL OR B.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @bond	X
					LEFT JOIN
					(
						SELECT
							B.[BondBranchId]	[BranchId],
							B.[BondGroupId]		[GroupId]
						FROM [Owner.Branch].[Bond]	B
						LEFT JOIN	@branch			X	ON	B.[BondBranchId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	B	ON	X.[BranchId]	= B.[BranchId]	AND
								X.[GroupId]		= B.[GroupId]
					WHERE B.[BranchId] IS NULL OR B.[GroupId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by group predicate
	DECLARE 
		@branchGroupPredicate	XML,
		@branchGroupIsCountable	BIT,
		@branchGroupGuids		XML,
		@branchGroupIsFiltered	BIT,
		@branchGroupNumber		INT;
	SELECT 
		@branchGroupPredicate	= X.[Criteria],
		@branchGroupIsCountable	= 0,
		@criteriaExist			= X.[CriteriaExist],
		@isExcluded				= X.[CriteriaIsExcluded],
		@criteriaIsNull			= X.[CriteriaIsNull],
		@criteriaValue			= X.[CriteriaValue],
		@criteriaValueExist		= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/BranchGroupPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @branchGroup TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner.Branch].[Group.Filter]
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
			@predicate		= @branchGroupPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @branchGroupIsCountable,
			@guids			= @branchGroupGuids			OUTPUT,
			@isExcluded		= @isExcluded				OUTPUT,
			@isFiltered		= @branchGroupIsFiltered	OUTPUT,
			@number			= @branchGroupNumber		OUTPUT;
		INSERT @branchGroup SELECT * FROM [Common].[Guid.Entities](@branchGroupGuids);
		IF (@branchGroupIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @bond SELECT
						B.[BondBranchId]	[BranchId],
						B.[BondGroupId]		[GroupId]
					FROM [Owner.Branch].[Bond]	B
					INNER JOIN	@branchGroup	X	ON	B.[BondGroupId]	= X.[Id];
				ELSE
					INSERT @bond SELECT
						B.[BondBranchId]	[BranchId],
						B.[BondGroupId]		[GroupId]
					FROM [Owner.Branch].[Bond]	B
					LEFT JOIN	@branchGroup	X	ON	B.[BondGroupId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @bond	X
					LEFT JOIN
					(
						SELECT
							B.[BondBranchId]	[BranchId],
							B.[BondGroupId]		[GroupId]
						FROM [Owner.Branch].[Bond]	B
						INNER JOIN	@branchGroup	X	ON	B.[BondGroupId]	= X.[Id]
					)	B	ON	X.[BranchId]	= B.[BranchId]	AND
								X.[GroupId]		= B.[GroupId]
					WHERE B.[BranchId] IS NULL OR B.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @bond	X
					LEFT JOIN
					(
						SELECT
							B.[BondBranchId]	[BranchId],
							B.[BondGroupId]		[GroupId]
						FROM [Owner.Branch].[Bond]	B
						LEFT JOIN	@branchGroup	X	ON	B.[BondGroupId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	B	ON	X.[BranchId]	= B.[BranchId]	AND
								X.[GroupId]		= B.[GroupId]
					WHERE B.[BranchId] IS NULL OR B.[GroupId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@organisations IS NOT NULL) BEGIN
		INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
		IF (@isFiltered = 0)
			INSERT @bond SELECT
				B.[BondBranchId]	[BranchId],
				B.[BondGroupId]		[GroupId]
			FROM [Owner.Branch].[Bond]		B
			INNER JOIN	[Owner].[Branch]	BR	ON	B.[BondBranchId]			= BR.[BranchId]
			INNER JOIN	@organisationIds	XO	ON	BR.[BranchOrganisationId]	= XO.[Id];
		ELSE
			DELETE X FROM @bond	X
			LEFT JOIN	
			(
				SELECT
					B.[BondBranchId]	[BranchId],
					B.[BondGroupId]		[GroupId]
				FROM [Owner.Branch].[Bond]		B
				INNER JOIN	[Owner].[Branch]	BR	ON	B.[BondBranchId]			= BR.[BranchId]
				INNER JOIN	@organisationIds	XO	ON	BR.[BranchOrganisationId]	= XO.[Id]
			)	B	ON	X.[BranchId]	= B.[BranchId]	AND
						X.[GroupId]		= B.[GroupId]
			WHERE B.[BranchId] IS NULL OR B.[GroupId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @bond SELECT
				B.[BondBranchId]	[BranchId],
				B.[BondGroupId]		[GroupId]
			FROM [Owner.Branch].[Bond]			B
			INNER JOIN	[Owner].[Branch]		BR	ON	B.[BondBranchId]			= BR.[BranchId]
			INNER JOIN	[Owner].[Organisation]	O	ON	BR.[BranchOrganisationId]	= O.[OrganisationId]
			WHERE O.[OrganisationEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @bond	X
			LEFT JOIN	
			(
				SELECT
					B.[BondBranchId]	[BranchId],
					B.[BondGroupId]		[GroupId]
				FROM [Owner.Branch].[Bond]			B
				INNER JOIN	[Owner].[Branch]		BR	ON	B.[BondBranchId]			= BR.[BranchId]
				INNER JOIN	[Owner].[Organisation]	O	ON	BR.[BranchOrganisationId]	= O.[OrganisationId]
				WHERE O.[OrganisationEmplacementId] = @emplacementId
			)	B	ON	X.[BranchId]	= B.[BranchId]	AND
						X.[GroupId]		= B.[GroupId]
			WHERE B.[BranchId] IS NULL OR B.[GroupId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT * FROM @bond X FOR XML PATH('guid'), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Owner.Branch].[Bond] B;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @bond X;
		ELSE
			IF (@organisations IS NULL)
				SELECT @number = COUNT(*) FROM [Owner.Branch].[Bond] B
				INNER JOIN	[Owner].[Branch]		BR	ON	B.[BondBranchId]			= BR.[BranchId]
				INNER JOIN	[Owner].[Organisation]	O	ON	BR.[BranchOrganisationId]	= O.[OrganisationId]
				LEFT JOIN	@bond					X	ON	B.[BondBranchId]			= X.[BranchId]	AND
															B.[BondGroupId]				= X.[GroupId]
				WHERE 
					O.[OrganisationEmplacementId]	= ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					(X.[BranchId] IS NULL OR X.[GroupId] IS NULL);
			ELSE
				SELECT @number = COUNT(*) FROM [Owner.Branch].[Bond] B
				INNER JOIN	[Owner].[Branch]		BR	ON	B.[BondBranchId]			= BR.[BranchId]
				INNER JOIN	[Owner].[Organisation]	O	ON	BR.[BranchOrganisationId]	= O.[OrganisationId]
				INNER JOIN	@organisationIds		XO	ON	O.[OrganisationId]			= XO.[Id]
				LEFT JOIN	@bond					X	ON	B.[BondBranchId]			= X.[BranchId]	AND
															B.[BondGroupId]				= X.[GroupId]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					(X.[BranchId] IS NULL OR X.[GroupId] IS NULL);

END
GO
