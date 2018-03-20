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
			O.[name]	= 'Organisation.Filter'))
	DROP PROCEDURE [Owner].[Organisation.Filter];
GO

CREATE PROCEDURE [Owner].[Organisation.Filter]
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

	DECLARE @organisation TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
	DECLARE 
		@criteria			XML,
		@criteriaExist		BIT,
		@criteriaIsNull		BIT,
		@criteriaValue		XML,
		@criteriaValueExist	BIT,
		@amountFrom			DECIMAL(28, 9),
		@amountTo			DECIMAL(28, 9),
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Organisations')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Organisation');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Owner].[Organisation.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @organisation SELECT * FROM @entities;
				ELSE
					INSERT @organisation SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
					WHERE O.[OrganisationId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @organisation X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @organisation X WHERE X.[Id] IN (SELECT * FROM @entities);
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
					INSERT @organisation SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
					INNER JOIN	@emplacement	X	ON	O.[OrganisationEmplacementId]	= X.[Id];
				ELSE
					INSERT @organisation SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
					LEFT JOIN	@emplacement	X	ON	O.[OrganisationEmplacementId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
						INNER JOIN	@emplacement	X	ON	O.[OrganisationEmplacementId]	= X.[Id]
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
				ELSE
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
						LEFT JOIN	@emplacement	X	ON	O.[OrganisationEmplacementId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@organisations IS NOT NULL) BEGIN
		INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
		IF (@isFiltered = 0)
			INSERT @organisation SELECT * FROM @organisationIds;
		ELSE
			DELETE X FROM @organisation X WHERE X.[Id] NOT IN (SELECT * FROM @organisationIds);
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
					INSERT @organisation SELECT DISTINCT O.[OrganisationId] FROM [Owner].[Organisation] O
					INNER JOIN	@codes	X	ON	O.[OrganisationCode]	LIKE X.[Code];
				ELSE 
					INSERT @organisation SELECT DISTINCT O.[OrganisationId] FROM [Owner].[Organisation] O
					LEFT JOIN	@codes	X	ON	O.[OrganisationCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT DISTINCT O.[OrganisationId] FROM [Owner].[Organisation] O
						INNER JOIN	@codes	X	ON	O.[OrganisationCode]	LIKE X.[Code]
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
				ELSE
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT DISTINCT O.[OrganisationId] FROM [Owner].[Organisation] O
						LEFT JOIN	@codes	X	ON	O.[OrganisationCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by IDNOs
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/IDNOs')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @IDNOs TABLE ([IDNO] NVARCHAR(MAX));
		INSERT @IDNOs SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @organisation SELECT DISTINCT O.[OrganisationId] FROM [Owner].[Organisation] O
					INNER JOIN	@IDNOs	X	ON	O.[OrganisationIDNO]	LIKE X.[IDNO];
				ELSE 
					INSERT @organisation SELECT DISTINCT O.[OrganisationId] FROM [Owner].[Organisation] O
					LEFT JOIN	@IDNOs	X	ON	O.[OrganisationIDNO]	LIKE X.[IDNO]
					WHERE X.[IDNO] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT DISTINCT O.[OrganisationId] FROM [Owner].[Organisation] O
						INNER JOIN	@IDNOs	X	ON	O.[OrganisationIDNO]	LIKE X.[IDNO]
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
				ELSE
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT DISTINCT O.[OrganisationId] FROM [Owner].[Organisation] O
						LEFT JOIN	@IDNOs	X	ON	O.[OrganisationIDNO]	LIKE X.[IDNO]
						WHERE X.[IDNO] IS NULL
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
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
					INSERT @organisation SELECT DISTINCT O.[OrganisationId] FROM [Owner].[Organisation] O
					INNER JOIN	@names	X	ON	O.[OrganisationName]	LIKE X.[Name];
				ELSE 
					INSERT @organisation SELECT DISTINCT O.[OrganisationId] FROM [Owner].[Organisation] O
					LEFT JOIN	@names	X	ON	O.[OrganisationName]	LIKE X.[Name]
					WHERE X.[Name] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT DISTINCT O.[OrganisationId] FROM [Owner].[Organisation] O
						INNER JOIN	@names	X	ON	O.[OrganisationName]	LIKE X.[Name]
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
				ELSE
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT DISTINCT O.[OrganisationId] FROM [Owner].[Organisation] O
						LEFT JOIN	@names	X	ON	O.[OrganisationName]	LIKE X.[Name]
						WHERE X.[Name] IS NULL
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
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
					INSERT @organisation SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
					WHERE O.[OrganisationCreatedOn] BETWEEN ISNULL(@dateFrom, O.[OrganisationCreatedOn]) AND ISNULL(@dateTo, O.[OrganisationCreatedOn]);
				ELSE 
					INSERT @organisation SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
					WHERE O.[OrganisationCreatedOn] NOT BETWEEN ISNULL(@dateFrom, O.[OrganisationCreatedOn]) AND ISNULL(@dateTo, O.[OrganisationCreatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
						WHERE O.[OrganisationCreatedOn] BETWEEN ISNULL(@dateFrom, O.[OrganisationCreatedOn]) AND ISNULL(@dateTo, O.[OrganisationCreatedOn])
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
				ELSE
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
						WHERE O.[OrganisationCreatedOn] NOT BETWEEN ISNULL(@dateFrom, O.[OrganisationCreatedOn]) AND ISNULL(@dateTo, O.[OrganisationCreatedOn])
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by registered datetime offset
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/RegisteredOn')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @dateFrom = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @organisation SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
					WHERE O.[OrganisationRegisteredOn] BETWEEN ISNULL(@dateFrom, O.[OrganisationRegisteredOn]) AND ISNULL(@dateTo, O.[OrganisationRegisteredOn]);
				ELSE 
					INSERT @organisation SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
					WHERE O.[OrganisationRegisteredOn] NOT BETWEEN ISNULL(@dateFrom, O.[OrganisationRegisteredOn]) AND ISNULL(@dateTo, O.[OrganisationRegisteredOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
						WHERE O.[OrganisationRegisteredOn] BETWEEN ISNULL(@dateFrom, O.[OrganisationRegisteredOn]) AND ISNULL(@dateTo, O.[OrganisationRegisteredOn])
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
				ELSE
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
						WHERE O.[OrganisationRegisteredOn] NOT BETWEEN ISNULL(@dateFrom, O.[OrganisationRegisteredOn]) AND ISNULL(@dateTo, O.[OrganisationRegisteredOn])
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by organisation action type
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/OrganisationActionType')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @flagsNumber = NULL, @flagsIsExact = NULL;
		SELECT 
			@flagsNumber	= X.[Number], 
			@flagsIsExact	= X.[IsExact] 
		FROM [Common].[Flags.Entity](@criteriaValue) X;
		IF (@flagsNumber > 0 OR @flagsIsExact = 1)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @organisation SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
					WHERE [Common].[Flags.NumberIsEqual](O.[OrganisationActionType], @flagsNumber, @flagsIsExact) = 1;
				ELSE 
					INSERT @organisation SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
					WHERE [Common].[Flags.NumberIsEqual](O.[OrganisationActionType], @flagsNumber, @flagsIsExact) = 0;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
						WHERE [Common].[Flags.NumberIsEqual](O.[OrganisationActionType], @flagsNumber, @flagsIsExact) = 1
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
				ELSE
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
						WHERE [Common].[Flags.NumberIsEqual](O.[OrganisationActionType], @flagsNumber, @flagsIsExact) = 0
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by locked datetime offset
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/LockedOn')) X;
	IF (@criteriaExist = 1) BEGIN
		SELECT @dateFrom = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @organisation SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
					WHERE 
						O.[OrganisationLockedOn] IS NULL OR
						O.[OrganisationLockedOn] BETWEEN ISNULL(@dateFrom, O.[OrganisationLockedOn]) AND ISNULL(@dateTo, O.[OrganisationLockedOn]);
				ELSE 
					INSERT @organisation SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
					WHERE 
						O.[OrganisationLockedOn] IS NULL OR
						O.[OrganisationLockedOn] NOT BETWEEN ISNULL(@dateFrom, O.[OrganisationLockedOn]) AND ISNULL(@dateTo, O.[OrganisationLockedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
						WHERE 
							O.[OrganisationLockedOn] IS NULL OR
							O.[OrganisationLockedOn] BETWEEN ISNULL(@dateFrom, O.[OrganisationLockedOn]) AND ISNULL(@dateTo, O.[OrganisationLockedOn])
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
				ELSE
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
						WHERE 
							O.[OrganisationLockedOn] IS NULL OR
							O.[OrganisationLockedOn] NOT BETWEEN ISNULL(@dateFrom, O.[OrganisationLockedOn]) AND ISNULL(@dateTo, O.[OrganisationLockedOn])
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
		ELSE
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @organisation SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
					WHERE O.[OrganisationLockedOn] IS NULL;
				ELSE 
					INSERT @organisation SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
					WHERE O.[OrganisationLockedOn] IS NOT NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
						WHERE O.[OrganisationLockedOn] IS NULL
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
				ELSE
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
						WHERE O.[OrganisationLockedOn] IS NOT NULL
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by locked reasons
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/LockedReasons')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @lockedReasons TABLE ([LockedReason] NVARCHAR(MAX));
		INSERT @lockedReasons SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @organisation SELECT DISTINCT O.[OrganisationId] FROM [Owner].[Organisation] O
					INNER JOIN	@lockedReasons	X	ON	O.[OrganisationLockedReason]	LIKE X.[LockedReason];
				ELSE 
					INSERT @organisation SELECT DISTINCT O.[OrganisationId] FROM [Owner].[Organisation] O
					LEFT JOIN	@lockedReasons	X	ON	O.[OrganisationLockedReason]	LIKE X.[LockedReason]
					WHERE X.[LockedReason] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT DISTINCT O.[OrganisationId] FROM [Owner].[Organisation] O
						INNER JOIN	@lockedReasons	X	ON	O.[OrganisationLockedReason]	LIKE X.[LockedReason]
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
				ELSE
					DELETE X FROM @organisation	X
					LEFT JOIN
					(
						SELECT DISTINCT O.[OrganisationId] FROM [Owner].[Organisation] O
						LEFT JOIN	@lockedReasons	X	ON	O.[OrganisationLockedReason]	LIKE X.[LockedReason]
						WHERE X.[LockedReason] IS NULL
					)	O	ON	X.[Id]	= O.[OrganisationId]
					WHERE O.[OrganisationId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @organisation SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
			WHERE O.[OrganisationEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @organisation	X
			LEFT JOIN
			(
				SELECT O.[OrganisationId] FROM [Owner].[Organisation] O
				WHERE O.[OrganisationEmplacementId] = @emplacementId
			)	O	ON	X.[Id]	= O.[OrganisationId]
			WHERE O.[OrganisationId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @organisation X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Owner].[Organisation] O;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @organisation X;
		ELSE
			IF (@organisations IS NULL)
				SELECT @number = COUNT(*) FROM [Owner].[Organisation] O
				LEFT JOIN	@organisation		X	ON	O.[OrganisationId] = X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE
				SELECT @number = COUNT(*) FROM [Owner].[Organisation] O
				INNER JOIN	@organisationIds	XO	ON	O.[OrganisationId] = XO.[Id]
				LEFT JOIN	@organisation		X	ON	O.[OrganisationId] = X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;

END
GO
