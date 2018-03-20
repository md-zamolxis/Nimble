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
			O.[name]	= 'Post.Filter'))
	DROP PROCEDURE [Owner].[Post.Filter];
GO

CREATE PROCEDURE [Owner].[Post.Filter]
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
	
	DECLARE @post TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
	DECLARE 
		@criteria			XML,
		@criteriaExist		BIT,
		@criteriaIsNull		BIT,
		@criteriaValue		XML,
		@criteriaValueExist	BIT,
		@dateFrom			DATETIMEOFFSET,
		@dateTo				DATETIMEOFFSET,
		@flagsNumber		INT,
		@flagsIsExact		BIT;
	
	SET @isFiltered = 0;

--	Filter by entities
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Posts')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Post');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Owner].[Post.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @post SELECT * FROM @entities;
				ELSE
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					WHERE P.[PostId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @post X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @post X WHERE X.[Id] IN (SELECT * FROM @entities);
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
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					INNER JOIN	@organisation	X	ON	P.[PostOrganisationId]	= X.[Id];
				ELSE
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					LEFT JOIN	@organisation	X	ON	P.[PostOrganisationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT P.[PostId] FROM [Owner].[Post] P
						INNER JOIN	@organisation	X	ON	P.[PostOrganisationId]	= X.[Id]
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
				ELSE
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT P.[PostId] FROM [Owner].[Post] P
						LEFT JOIN	@organisation	X	ON	P.[PostOrganisationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@organisations IS NOT NULL) BEGIN
		INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
		IF (@isFiltered = 0)
			INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
			INNER JOIN	@organisationIds	XO	ON	P.[PostOrganisationId]	= XO.[Id];
		ELSE
			DELETE X FROM @post				X 
			INNER JOIN	[Owner].[Post]		P	ON	X.[Id]					= P.[PostId]
			LEFT JOIN	@organisationIds	XO	ON	P.[PostOrganisationId]	= XO.[Id]
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
					INSERT @post SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
					INNER JOIN	@codes	X	ON	P.[PostCode]	LIKE X.[Code];
				ELSE 
					INSERT @post SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
					LEFT JOIN	@codes	X	ON	P.[PostCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
						INNER JOIN	@codes	X	ON	P.[PostCode]	LIKE X.[Code]
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
				ELSE
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
						LEFT JOIN	@codes	X	ON	P.[PostCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by date datetime offset
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Date')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @dateFrom = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					WHERE P.[PostDate] BETWEEN ISNULL(@dateFrom, P.[PostDate]) AND ISNULL(@dateTo, P.[PostDate]);
				ELSE 
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					WHERE P.[PostDate] NOT BETWEEN ISNULL(@dateFrom, P.[PostDate]) AND ISNULL(@dateTo, P.[PostDate]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT P.[PostId] FROM [Owner].[Post] P
						WHERE P.[PostDate] BETWEEN ISNULL(@dateFrom, P.[PostDate]) AND ISNULL(@dateTo, P.[PostDate])
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
				ELSE
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT P.[PostId] FROM [Owner].[Post] P
						WHERE P.[PostDate] NOT BETWEEN ISNULL(@dateFrom, P.[PostDate]) AND ISNULL(@dateTo, P.[PostDate])
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by titles
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Titles')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @titles TABLE ([Title] NVARCHAR(MAX));
		INSERT @titles SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @post SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
					INNER JOIN	@titles	X	ON	P.[PostTitle]	LIKE X.[Title];
				ELSE 
					INSERT @post SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
					LEFT JOIN	@titles	X	ON	P.[PostTitle]	LIKE X.[Title]
					WHERE X.[Title] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
						INNER JOIN	@titles	X	ON	P.[PostTitle]	LIKE X.[Title]
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
				ELSE
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
						LEFT JOIN	@titles	X	ON	P.[PostTitle]	LIKE X.[Title]
						WHERE X.[Title] IS NULL
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by subjects
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Subjects')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @subjects TABLE ([Subject] NVARCHAR(MAX));
		INSERT @subjects SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @post SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
					INNER JOIN	@subjects	X	ON	P.[PostSubject]	LIKE X.[Subject];
				ELSE 
					INSERT @post SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
					LEFT JOIN	@subjects	X	ON	P.[PostSubject]	LIKE X.[Subject]
					WHERE X.[Subject] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
						INNER JOIN	@subjects	X	ON	P.[PostSubject]	LIKE X.[Subject]
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
				ELSE
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
						LEFT JOIN	@subjects	X	ON	P.[PostSubject]	LIKE X.[Subject]
						WHERE X.[Subject] IS NULL
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by bodies
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Bodies')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @bodies TABLE ([Body] NVARCHAR(MAX));
		INSERT @bodies SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @post SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
					INNER JOIN	@bodies	X	ON	P.[PostBody]	LIKE X.[Body];
				ELSE 
					INSERT @post SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
					LEFT JOIN	@bodies	X	ON	P.[PostBody]	LIKE X.[Body]
					WHERE X.[Body] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
						INNER JOIN	@bodies	X	ON	P.[PostBody]	LIKE X.[Body]
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
				ELSE
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
						LEFT JOIN	@bodies	X	ON	P.[PostBody]	LIKE X.[Body]
						WHERE X.[Body] IS NULL
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
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
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					WHERE P.[PostCreatedOn] BETWEEN ISNULL(@dateFrom, P.[PostCreatedOn]) AND ISNULL(@dateTo, P.[PostCreatedOn]);
				ELSE 
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					WHERE P.[PostCreatedOn] NOT BETWEEN ISNULL(@dateFrom, P.[PostCreatedOn]) AND ISNULL(@dateTo, P.[PostCreatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT P.[PostId] FROM [Owner].[Post] P
						WHERE P.[PostCreatedOn] BETWEEN ISNULL(@dateFrom, P.[PostCreatedOn]) AND ISNULL(@dateTo, P.[PostCreatedOn])
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
				ELSE
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT P.[PostId] FROM [Owner].[Post] P
						WHERE P.[PostCreatedOn] NOT BETWEEN ISNULL(@dateFrom, P.[PostCreatedOn]) AND ISNULL(@dateTo, P.[PostCreatedOn])
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
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
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					WHERE P.[PostUpdatedOn] BETWEEN ISNULL(@dateFrom, P.[PostUpdatedOn]) AND ISNULL(@dateTo, P.[PostUpdatedOn]);
				ELSE 
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					WHERE P.[PostUpdatedOn] NOT BETWEEN ISNULL(@dateFrom, P.[PostUpdatedOn]) AND ISNULL(@dateTo, P.[PostUpdatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT P.[PostId] FROM [Owner].[Post] P
						WHERE P.[PostUpdatedOn] BETWEEN ISNULL(@dateFrom, P.[PostUpdatedOn]) AND ISNULL(@dateTo, P.[PostUpdatedOn])
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
				ELSE
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT P.[PostId] FROM [Owner].[Post] P
						WHERE P.[PostUpdatedOn] NOT BETWEEN ISNULL(@dateFrom, P.[PostUpdatedOn]) AND ISNULL(@dateTo, P.[PostUpdatedOn])
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
		ELSE
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					WHERE P.[PostUpdatedOn] IS NULL;
				ELSE 
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					WHERE P.[PostUpdatedOn] IS NOT NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT P.[PostId] FROM [Owner].[Post] P
						WHERE P.[PostUpdatedOn] IS NULL
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
				ELSE
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT P.[PostId] FROM [Owner].[Post] P
						WHERE P.[PostUpdatedOn] IS NOT NULL
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
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
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					WHERE P.[PostDeletedOn] BETWEEN ISNULL(@dateFrom, P.[PostDeletedOn]) AND ISNULL(@dateTo, P.[PostDeletedOn]);
				ELSE 
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					WHERE P.[PostDeletedOn] NOT BETWEEN ISNULL(@dateFrom, P.[PostDeletedOn]) AND ISNULL(@dateTo, P.[PostDeletedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT P.[PostId] FROM [Owner].[Post] P
						WHERE P.[PostDeletedOn] BETWEEN ISNULL(@dateFrom, P.[PostDeletedOn]) AND ISNULL(@dateTo, P.[PostDeletedOn])
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
				ELSE
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT P.[PostId] FROM [Owner].[Post] P
						WHERE P.[PostDeletedOn] NOT BETWEEN ISNULL(@dateFrom, P.[PostDeletedOn]) AND ISNULL(@dateTo, P.[PostDeletedOn])
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
		ELSE
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					WHERE P.[PostDeletedOn] IS NULL;
				ELSE 
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					WHERE P.[PostDeletedOn] IS NOT NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT P.[PostId] FROM [Owner].[Post] P
						WHERE P.[PostDeletedOn] IS NULL
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
				ELSE
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT P.[PostId] FROM [Owner].[Post] P
						WHERE P.[PostDeletedOn] IS NOT NULL
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by post action type
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/PostActionType')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @flagsNumber = NULL, @flagsIsExact = NULL;
		SELECT 
			@flagsNumber	= X.[Number], 
			@flagsIsExact	= X.[IsExact] 
		FROM [Common].[Flags.Entity](@criteriaValue) X;
		IF (@flagsNumber > 0 OR @flagsIsExact = 1)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					WHERE [Common].[Flags.NumberIsEqual](P.[PostActionType], @flagsNumber, @flagsIsExact) = 1;
				ELSE 
					INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
					WHERE [Common].[Flags.NumberIsEqual](P.[PostActionType], @flagsNumber, @flagsIsExact) = 0;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT P.[PostId] FROM [Owner].[Post] P
						WHERE [Common].[Flags.NumberIsEqual](P.[PostActionType], @flagsNumber, @flagsIsExact) = 1
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
				ELSE
					DELETE X FROM @post	X
					LEFT JOIN
					(
						SELECT P.[PostId] FROM [Owner].[Post] P
						WHERE [Common].[Flags.NumberIsEqual](P.[PostActionType], @flagsNumber, @flagsIsExact) = 0
					)	P	ON	X.[Id]	= P.[PostId]
					WHERE P.[PostId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by group predicate
	DECLARE 
		@postGroupPredicate		XML,
		@postGroupIsCountable	BIT,
		@postGroupGuids			XML,
		@postGroupIsFiltered	BIT,
		@postGroupNumber		INT,
		@splitNumber			INT;
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
		IF (ISNULL([Common].[Bool.Entity](@predicate.query('/*/PostGroupPredicate/PostSplitIntersect')), 0) = 0) BEGIN
			IF (ISNULL([Common].[Bool.Entity](@predicate.query('/*/PostGroupExclude')), 0) = 0) BEGIN
				IF (@postGroupIsFiltered = 1) BEGIN
					IF (@isFiltered = 0)
						IF (@isExcluded = 0)
							INSERT @post SELECT DISTINCT B.[BondPostId] FROM [Owner.Post].[Bond] B
							INNER JOIN	@postGroup	X	ON	B.[BondGroupId]	= X.[Id];
						ELSE
							INSERT @post SELECT DISTINCT B.[BondPostId] FROM [Owner.Post].[Bond] B
							LEFT JOIN	@postGroup	X	ON	B.[BondGroupId]	= X.[Id]
							WHERE X.[Id] IS NULL;
					ELSE
						IF (@isExcluded = 0)
							DELETE X FROM @post	X
							LEFT JOIN
							(
								SELECT DISTINCT B.[BondPostId]
								FROM [Owner.Post].[Bond]	B
								INNER JOIN	@postGroup		X	ON	B.[BondGroupId]	= X.[Id]
							)	B	ON	X.[Id]	= B.[BondPostId]
							WHERE B.[BondPostId] IS NULL;
						ELSE
							DELETE X FROM @post	X
							LEFT JOIN
							(
								SELECT DISTINCT B.[BondPostId]
								FROM [Owner.Post].[Bond]	B
								LEFT JOIN	@postGroup		X	ON	B.[BondGroupId]	= X.[Id]
								WHERE X.[Id] IS NULL
							)	B	ON	X.[Id]	= B.[BondPostId]
							WHERE B.[BondPostId] IS NULL;
					SET @isFiltered = 1;
				END
			END
			ELSE BEGIN
				IF (@postGroupIsFiltered = 1) BEGIN
					IF (@isFiltered = 0)
						IF (@isExcluded = 0)
							INSERT @post SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
							LEFT JOIN 
							(
								SELECT DISTINCT B.[BondPostId] 
								FROM [Owner.Post].[Bond]	B
								INNER JOIN	@postGroup		X	ON	B.[BondGroupId]	= X.[Id]
							)	G	ON	P.[PostId]	= G.[BondPostId]
							WHERE G.[BondPostId] IS NULL;
						ELSE
							INSERT @post SELECT DISTINCT P.[PostId] FROM [Owner].[Post] P
							LEFT JOIN 
							(
								SELECT DISTINCT B.[BondPostId] 
								FROM [Owner.Post].[Bond]	B
								LEFT JOIN	@postGroup		X	ON	B.[BondGroupId]	= X.[Id]
								WHERE X.[Id] IS NULL
							)	G	ON	P.[PostId]	= G.[BondPostId]
							WHERE G.[BondPostId] IS NULL;
					ELSE
						IF (@isExcluded = 0)
							DELETE X FROM @post	X
							INNER JOIN
							(
								SELECT DISTINCT B.[BondPostId] 
								FROM [Owner.Post].[Bond]	B
								INNER JOIN	@postGroup		X	ON	B.[BondGroupId]	= X.[Id]
							)	G	ON	X.[Id]	= G.[BondPostId];
						ELSE
							DELETE X FROM @post	X
							INNER JOIN
							(
								SELECT DISTINCT B.[BondPostId] 
								FROM [Owner.Post].[Bond]	B
								LEFT JOIN	@postGroup		X	ON	B.[BondGroupId]	= X.[Id]
								WHERE X.[Id] IS NULL
							)	G	ON	X.[Id]	= G.[BondPostId];
					SET @isFiltered = 1;
				END
			END
		END
		ELSE BEGIN
			IF (@postGroupIsFiltered = 1) BEGIN
				SELECT @splitNumber = COUNT(DISTINCT G.[GroupSplitId]) FROM @postGroup X
				INNER JOIN	[Owner.Post].[Group]	G	ON	X.[Id] = G.[GroupId];
				IF (@isFiltered = 0)
					IF (@isExcluded = 0)
						INSERT @post SELECT DISTINCT B.[BondPostId]
						FROM [Owner.Post].[Bond]			B
						INNER JOIN	[Owner.Post].[Group]	G	ON	B.[BondGroupId]	= G.[GroupId]
						INNER JOIN	@postGroup				X	ON	B.[BondGroupId]	= X.[Id]
						GROUP BY B.[BondPostId]
						HAVING COUNT(DISTINCT G.[GroupSplitId]) = @splitNumber;
					ELSE
						INSERT @post SELECT DISTINCT B.[BondPostId]
						FROM [Owner.Post].[Bond]			B
						INNER JOIN	[Owner.Post].[Group]	G	ON	B.[BondGroupId]	= G.[GroupId]
						INNER JOIN	@postGroup				X	ON	B.[BondGroupId]	= X.[Id]
						GROUP BY B.[BondPostId]
						HAVING COUNT(DISTINCT G.[GroupSplitId]) <> @splitNumber;
				ELSE
					IF (@isExcluded = 0)
						DELETE X FROM @post	X
						LEFT JOIN
						(
							SELECT DISTINCT B.[BondPostId]
							FROM [Owner.Post].[Bond]			B
							INNER JOIN	[Owner.Post].[Group]	G	ON	B.[BondGroupId]	= G.[GroupId]
							INNER JOIN	@postGroup				X	ON	B.[BondGroupId]	= X.[Id]
							GROUP BY B.[BondPostId]
							HAVING COUNT(DISTINCT G.[GroupSplitId]) = @splitNumber
						)	B	ON	X.[Id]	= B.[BondPostId]
						WHERE B.[BondPostId] IS NULL;
					ELSE
						DELETE X FROM @post	X
						LEFT JOIN
						(
							SELECT DISTINCT B.[BondPostId]
							FROM [Owner.Post].[Bond]			B
							INNER JOIN	[Owner.Post].[Group]	G	ON	B.[BondGroupId]	= G.[GroupId]
							INNER JOIN	@postGroup			X	ON	B.[BondGroupId]	= X.[Id]
							GROUP BY B.[BondPostId]
							HAVING COUNT(DISTINCT G.[GroupSplitId]) <> @splitNumber
						)	B	ON	X.[Id]	= B.[BondPostId]
						WHERE B.[BondPostId] IS NULL;
				SET @isFiltered = 1;
			END
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @post SELECT P.[PostId] FROM [Owner].[Post] P
			INNER JOIN	[Owner].[Organisation]	O	ON	P.[PostOrganisationId]	= O.[OrganisationId]
			WHERE O.[OrganisationEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @post	X
			LEFT JOIN	(
				SELECT P.[PostId] FROM [Owner].[Post]	P
				INNER JOIN	[Owner].[Organisation]		O	ON	P.[PostOrganisationId]	= O.[OrganisationId]
				WHERE O.[OrganisationEmplacementId] = @emplacementId
			)	P	ON	X.[Id]	= P.[PostId]
			WHERE P.[PostId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @post X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Owner].[Post] P;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @post X;
		ELSE
			IF (@organisations IS NULL)      
				SELECT @number = COUNT(*) FROM [Owner].[Post]	P
				INNER JOIN	[Owner].[Organisation]				O	ON	P.[PostOrganisationId]	= O.[OrganisationId]
				LEFT JOIN	@post								X	ON	P.[PostId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId]	= ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE
				SELECT @number = COUNT(*) FROM [Owner].[Post]	P
				INNER JOIN	[Owner].[Organisation]				O	ON	P.[PostOrganisationId]	= O.[OrganisationId]
				INNER JOIN	@organisationIds					XO	ON	O.[OrganisationId]		= XO.[Id]
				LEFT JOIN	@post								X	ON	P.[PostId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;

END
GO
