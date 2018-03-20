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
			O.[name]	= 'Bond.Filter'))
	DROP PROCEDURE [Owner.Post].[Bond.Filter];
GO

CREATE PROCEDURE [Owner.Post].[Bond.Filter]
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
		[PostId]	UNIQUEIDENTIFIER,
		[GroupId]	UNIQUEIDENTIFIER,
		PRIMARY KEY CLUSTERED 
		(
			[PostId],
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/PostBonds')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/PostBond');
		DECLARE @entities TABLE 
		(
			[PostId] UNIQUEIDENTIFIER,
			[GroupId]	UNIQUEIDENTIFIER
		);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.*
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Owner.Post].[Bond.Entity](X.[Entity]) E
		) E
		WHERE E.[PostId] IS NOT NULL AND E.[GroupId] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @bond SELECT * FROM @entities;
				ELSE
					INSERT @bond SELECT 
						B.[BondPostId]		[PostId],
						B.[BondGroupId]		[GroupId]
					FROM [Owner.Post].[Bond]	B
					LEFT JOIN	@entities		X	ON	B.[BondPostId]	= X.[PostId]	AND
														B.[BondGroupId]	= X.[GroupId]
					WHERE X.[PostId] IS NULL OR X.[GroupId] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @bond		X 
					LEFT JOIN	@entities	B	ON	X.[PostId]	= B.[PostId]	AND
													X.[GroupId]	= B.[GroupId]
					WHERE B.[PostId] IS NULL OR B.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @bond X 
					LEFT JOIN
					(
						SELECT 
							B.[BondPostId]		[PostId],
							B.[BondGroupId]		[GroupId]
						FROM [Owner.Post].[Bond]	B
						LEFT JOIN	@entities		X	ON	B.[BondPostId]	= X.[PostId]	AND
															B.[BondGroupId]	= X.[GroupId]
						WHERE X.[PostId] IS NULL OR X.[GroupId] IS NULL
					)	B	ON	X.[PostId]	= B.[PostId]	AND
								X.[GroupId]	= B.[GroupId]
					WHERE B.[PostId] IS NULL OR B.[GroupId] IS NULL;
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
					INSERT @bond SELECT
						B.[BondPostId]	[PostId],
						B.[BondGroupId]	[GroupId]
					FROM [Owner.Post].[Bond]	B
					INNER JOIN	@post			X	ON	B.[BondPostId]	= X.[Id];
				ELSE
					INSERT @bond SELECT
						B.[BondPostId]	[PostId],
						B.[BondGroupId]	[GroupId]
					FROM [Owner.Post].[Bond]	B
					LEFT JOIN	@post			X	ON	B.[BondPostId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @bond	X
					LEFT JOIN
					(
						SELECT
							B.[BondPostId]	[PostId],
							B.[BondGroupId]	[GroupId]
						FROM [Owner.Post].[Bond]	B
						INNER JOIN	@post			X	ON	B.[BondPostId]	= X.[Id]
					)	B	ON	X.[PostId]	= B.[PostId]	AND
								X.[GroupId]	= B.[GroupId]
					WHERE B.[PostId] IS NULL OR B.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @bond	X
					LEFT JOIN
					(
						SELECT
							B.[BondPostId]	[PostId],
							B.[BondGroupId]	[GroupId]
						FROM [Owner.Post].[Bond]	B
						LEFT JOIN	@post			X	ON	B.[BondPostId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	B	ON	X.[PostId]	= B.[PostId]	AND
								X.[GroupId]	= B.[GroupId]
					WHERE B.[PostId] IS NULL OR B.[GroupId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by post group predicate
	DECLARE 
		@postGroupPredicate		XML,
		@postGroupIsCountable	BIT,
		@postGroupGuids			XML,
		@postGroupIsFiltered	BIT,
		@postGroupNumber		INT;
	SELECT 
		@postGroupPredicate		= X.[Criteria],
		@postGroupIsCountable	= 0,
		@criteriaExist			= X.[CriteriaExist],
		@isExcluded				= X.[CriteriaIsExcluded],
		@criteriaIsNull			= X.[CriteriaIsNull],
		@criteriaValue			= X.[CriteriaValue],
		@criteriaValueExist		= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/PostGroupPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @postGroup TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner.Post].[Group.Filter]
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
			@predicate		= @postGroupPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @postGroupIsCountable,
			@guids			= @postGroupGuids		OUTPUT,
			@isExcluded		= @isExcluded			OUTPUT,
			@isFiltered		= @postGroupIsFiltered	OUTPUT,
			@number			= @postGroupNumber		OUTPUT;
		INSERT @postGroup SELECT * FROM [Common].[Guid.Entities](@postGroupGuids);
		IF (@postGroupIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @bond SELECT
						B.[BondPostId]	[PostId],
						B.[BondGroupId]	[GroupId]
					FROM [Owner.Post].[Bond]	B
					INNER JOIN	@postGroup		X	ON	B.[BondGroupId]	= X.[Id];
				ELSE
					INSERT @bond SELECT
						B.[BondPostId]	[PostId],
						B.[BondGroupId]	[GroupId]
					FROM [Owner.Post].[Bond]	B
					LEFT JOIN	@postGroup		X	ON	B.[BondGroupId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @bond	X
					LEFT JOIN
					(
						SELECT
							B.[BondPostId]	[PostId],
							B.[BondGroupId]	[GroupId]
						FROM [Owner.Post].[Bond]	B
						INNER JOIN	@postGroup		X	ON	B.[BondGroupId]	= X.[Id]
					)	B	ON	X.[PostId]	= B.[PostId]	AND
								X.[GroupId]		= B.[GroupId]
					WHERE B.[PostId] IS NULL OR B.[GroupId] IS NULL;
				ELSE
					DELETE X FROM @bond	X
					LEFT JOIN
					(
						SELECT
							B.[BondPostId]	[PostId],
							B.[BondGroupId]	[GroupId]
						FROM [Owner.Post].[Bond]	B
						LEFT JOIN	@postGroup		X	ON	B.[BondGroupId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	B	ON	X.[PostId]	= B.[PostId]	AND
								X.[GroupId]		= B.[GroupId]
					WHERE B.[PostId] IS NULL OR B.[GroupId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@organisations IS NOT NULL) BEGIN
		INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
		IF (@isFiltered = 0)
			INSERT @bond SELECT
				B.[BondPostId]	[PostId],
				B.[BondGroupId]	[GroupId]
			FROM [Owner.Post].[Bond]		B
			INNER JOIN	[Owner].[Post]		P	ON	B.[BondPostId]			= P.[PostId]
			INNER JOIN	@organisationIds	XO	ON	P.[PostOrganisationId]	= XO.[Id];
		ELSE
			DELETE X FROM @bond	X
			LEFT JOIN	
			(
				SELECT
					B.[BondPostId]	[PostId],
					B.[BondGroupId]	[GroupId]
				FROM [Owner.Post].[Bond]		B
				INNER JOIN	[Owner].[Post]		P	ON	B.[BondPostId]			= P.[PostId]
				INNER JOIN	@organisationIds	XO	ON	P.[PostOrganisationId]	= XO.[Id]
			)	B	ON	X.[PostId]	= B.[PostId]	AND
						X.[GroupId]	= B.[GroupId]
			WHERE B.[PostId] IS NULL OR B.[GroupId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @bond SELECT
				B.[BondPostId]	[PostId],
				B.[BondGroupId]	[GroupId]
			FROM [Owner.Post].[Bond]			B
			INNER JOIN	[Owner].[Post]			P	ON	B.[BondPostId]			= P.[PostId]
			INNER JOIN	[Owner].[Organisation]	O	ON	P.[PostOrganisationId]	= O.[OrganisationId]
			WHERE O.[OrganisationEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @bond	X
			LEFT JOIN	
			(
				SELECT
					B.[BondPostId]	[PostId],
					B.[BondGroupId]	[GroupId]
				FROM [Owner.Post].[Bond]			B
				INNER JOIN	[Owner].[Post]			P	ON	B.[BondPostId]			= P.[PostId]
				INNER JOIN	[Owner].[Organisation]	O	ON	P.[PostOrganisationId]	= O.[OrganisationId]
				WHERE O.[OrganisationEmplacementId] = @emplacementId
			)	B	ON	X.[PostId]	= B.[PostId]	AND
						X.[GroupId]	= B.[GroupId]
			WHERE B.[PostId] IS NULL OR B.[GroupId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT * FROM @bond X FOR XML PATH('guid'), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Owner.Post].[Bond] B;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @bond X;
		ELSE
			IF (@organisations IS NULL)
				SELECT @number = COUNT(*) FROM [Owner.Post].[Bond] B
				INNER JOIN	[Owner].[Post]			P	ON	B.[BondPostId]			= P.[PostId]
				INNER JOIN	[Owner].[Organisation]	O	ON	P.[PostOrganisationId]	= O.[OrganisationId]
				LEFT JOIN	@bond					X	ON	B.[BondPostId]			= X.[PostId]	AND
															B.[BondGroupId]			= X.[GroupId]
				WHERE 
					O.[OrganisationEmplacementId]	= ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					(X.[PostId] IS NULL OR X.[GroupId] IS NULL);
			ELSE
				SELECT @number = COUNT(*) FROM [Owner.Post].[Bond] B
				INNER JOIN	[Owner].[Post]			P	ON	B.[BondPostId]			= P.[PostId]
				INNER JOIN	[Owner].[Organisation]	O	ON	P.[PostOrganisationId]	= O.[OrganisationId]
				INNER JOIN	@organisationIds		XO	ON	O.[OrganisationId]		= XO.[Id]
				LEFT JOIN	@bond					X	ON	B.[BondPostId]			= X.[PostId]	AND
															B.[BondGroupId]			= X.[GroupId]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					(X.[PostId] IS NULL OR X.[GroupId] IS NULL);

END
GO
