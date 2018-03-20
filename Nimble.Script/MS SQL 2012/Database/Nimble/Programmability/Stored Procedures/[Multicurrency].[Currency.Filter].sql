SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multicurrency'	AND
			O.[type]	= 'P'			AND
			O.[name]	= 'Currency.Filter'))
	DROP PROCEDURE [Multicurrency].[Currency.Filter];
GO

CREATE PROCEDURE [Multicurrency].[Currency.Filter]
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
	
	DECLARE @currency TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Currencies')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Currency');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Multicurrency].[Currency.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @currency SELECT * FROM @entities;
				ELSE
					INSERT @currency SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
					WHERE C.[CurrencyId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @currency X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @currency X WHERE X.[Id] IN (SELECT * FROM @entities);
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
					INSERT @currency SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
					INNER JOIN	@organisation	X	ON	C.[CurrencyOrganisationId]	= X.[Id];
				ELSE
					INSERT @currency SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
					LEFT JOIN	@organisation	X	ON	C.[CurrencyOrganisationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @currency	X
					LEFT JOIN
					(
						SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
						INNER JOIN	@organisation	X	ON	C.[CurrencyOrganisationId]	= X.[Id]
					)	C	ON	X.[Id]	= C.[CurrencyId]
					WHERE C.[CurrencyId] IS NULL;
				ELSE
					DELETE X FROM @currency	X
					LEFT JOIN
					(
						SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
						LEFT JOIN	@organisation	X	ON	C.[CurrencyOrganisationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	C	ON	X.[Id]	= C.[CurrencyId]
					WHERE C.[CurrencyId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@organisations IS NOT NULL) BEGIN
		INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
		IF (@isFiltered = 0)
			INSERT @currency SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
			INNER JOIN	@organisationIds			XO	ON	C.[CurrencyOrganisationId]	= XO.[Id];
		ELSE
			DELETE X FROM @currency					X 
			INNER JOIN	[Multicurrency].[Currency]	C	ON	X.[Id]						= C.[CurrencyId]
			LEFT JOIN	@organisationIds			XO	ON	C.[CurrencyOrganisationId]	= XO.[Id]
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
					INSERT @currency SELECT DISTINCT C.[CurrencyId] FROM [Multicurrency].[Currency] C
					INNER JOIN	@codes	X	ON	C.[CurrencyCode]	LIKE X.[Code];
				ELSE 
					INSERT @currency SELECT DISTINCT C.[CurrencyId] FROM [Multicurrency].[Currency] C
					LEFT JOIN	@codes	X	ON	C.[CurrencyCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @currency	X
					LEFT JOIN
					(
						SELECT DISTINCT C.[CurrencyId] FROM [Multicurrency].[Currency] C
						INNER JOIN	@codes	X	ON	C.[CurrencyCode]	LIKE X.[Code]
					)	C	ON	X.[Id]	= C.[CurrencyId]
					WHERE C.[CurrencyId]	IS NULL;
				ELSE
					DELETE X FROM @currency	X
					LEFT JOIN
					(
						SELECT DISTINCT C.[CurrencyId] FROM [Multicurrency].[Currency] C
						LEFT JOIN	@codes	X	ON	C.[CurrencyCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	C	ON	X.[Id]	= C.[CurrencyId]
					WHERE C.[CurrencyId]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by default status
	DECLARE @isDefault BIT;
	SET @isDefault = [Common].[Bool.Entity](@predicate.query('/*/IsDefault'));
	IF (@isDefault IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @currency SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
			WHERE C.[CurrencyIsDefault] = @isDefault;
		ELSE
			DELETE X FROM @currency	X
			LEFT JOIN
			(
				SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
				WHERE C.[CurrencyIsDefault] = @isDefault
			)	C	ON	X.[Id]	= C.[CurrencyId]
			WHERE C.[CurrencyId]	IS NULL;
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
					INSERT @currency SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
					WHERE C.[CurrencyCreatedOn] BETWEEN ISNULL(@dateFrom, C.[CurrencyCreatedOn]) AND ISNULL(@dateTo, C.[CurrencyCreatedOn]);
				ELSE 
					INSERT @currency SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
					WHERE C.[CurrencyCreatedOn] NOT BETWEEN ISNULL(@dateFrom, C.[CurrencyCreatedOn]) AND ISNULL(@dateTo, C.[CurrencyCreatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @currency	X
					LEFT JOIN
					(
						SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
						WHERE C.[CurrencyCreatedOn] BETWEEN ISNULL(@dateFrom, C.[CurrencyCreatedOn]) AND ISNULL(@dateTo, C.[CurrencyCreatedOn])
					)	C	ON	X.[Id]	= C.[CurrencyId]
					WHERE C.[CurrencyId] IS NULL;
				ELSE
					DELETE X FROM @currency	X
					LEFT JOIN
					(
						SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
						WHERE C.[CurrencyCreatedOn] NOT BETWEEN ISNULL(@dateFrom, C.[CurrencyCreatedOn]) AND ISNULL(@dateTo, C.[CurrencyCreatedOn])
					)	C	ON	X.[Id]	= C.[CurrencyId]
					WHERE C.[CurrencyId] IS NULL;
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
					INSERT @currency SELECT DISTINCT C.[CurrencyId] FROM [Multicurrency].[Currency] C
					INNER JOIN	@descriptions	X	ON	C.[CurrencyDescription]	LIKE X.[Description];
				ELSE 
					INSERT @currency SELECT DISTINCT C.[CurrencyId] FROM [Multicurrency].[Currency] C
					LEFT JOIN	@descriptions	X	ON	C.[CurrencyDescription]	LIKE X.[Description]
					WHERE X.[Description] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @currency	X
					LEFT JOIN
					(
						SELECT DISTINCT C.[CurrencyId] FROM [Multicurrency].[Currency] C
						INNER JOIN	@descriptions	X	ON	C.[CurrencyDescription]	LIKE X.[Description]
					)	C	ON	X.[Id]	= C.[CurrencyId]
					WHERE C.[CurrencyId]	IS NULL;
				ELSE
					DELETE X FROM @currency	X
					LEFT JOIN
					(
						SELECT DISTINCT C.[CurrencyId] FROM [Multicurrency].[Currency] C
						LEFT JOIN	@descriptions	X	ON	C.[CurrencyDescription]	LIKE X.[Description]
						WHERE X.[Description] IS NULL
					)	C	ON	X.[Id]	= C.[CurrencyId]
					WHERE C.[CurrencyId]	IS NULL;
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
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @dateFrom = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @currency SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
					WHERE C.[CurrencyLockedOn] BETWEEN ISNULL(@dateFrom, C.[CurrencyLockedOn]) AND ISNULL(@dateTo, C.[CurrencyLockedOn]);
				ELSE 
					INSERT @currency SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
					WHERE C.[CurrencyLockedOn] NOT BETWEEN ISNULL(@dateFrom, C.[CurrencyLockedOn]) AND ISNULL(@dateTo, C.[CurrencyLockedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @currency	X
					LEFT JOIN
					(
						SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
						WHERE C.[CurrencyLockedOn] BETWEEN ISNULL(@dateFrom, C.[CurrencyLockedOn]) AND ISNULL(@dateTo, C.[CurrencyLockedOn])
					)	C	ON	X.[Id]	= C.[CurrencyId]
					WHERE C.[CurrencyId] IS NULL;
				ELSE
					DELETE X FROM @currency	X
					LEFT JOIN
					(
						SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
						WHERE C.[CurrencyLockedOn] NOT BETWEEN ISNULL(@dateFrom, C.[CurrencyLockedOn]) AND ISNULL(@dateTo, C.[CurrencyLockedOn])
					)	C	ON	X.[Id]	= C.[CurrencyId]
					WHERE C.[CurrencyId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @currency SELECT C.[CurrencyId] FROM [Multicurrency].[Currency] C
			INNER JOIN	[Owner].[Organisation]	O	ON	C.[CurrencyOrganisationId]	= O.[OrganisationId]
			WHERE O.[OrganisationEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @currency	X
			LEFT JOIN
			(
				SELECT C.[CurrencyId] FROM [Multicurrency].[Currency]	C
				INNER JOIN	[Owner].[Organisation]						O	ON	C.[CurrencyOrganisationId]	= O.[OrganisationId]
				WHERE O.[OrganisationEmplacementId] = @emplacementId
			)	C	ON	X.[Id]	= C.[CurrencyId]
			WHERE C.[CurrencyId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @currency X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Multicurrency].[Currency] C;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @currency X;
		ELSE
			IF (@organisations IS NULL)      
				SELECT @number = COUNT(*) FROM [Multicurrency].[Currency] C
				INNER JOIN	[Owner].[Organisation]	O	ON	C.[CurrencyOrganisationId]	= O.[OrganisationId]
				LEFT JOIN	@currency				X	ON	C.[CurrencyId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE
				SELECT @number = COUNT(*) FROM [Multicurrency].[Currency] C
				INNER JOIN	[Owner].[Organisation]	O	ON	C.[CurrencyOrganisationId]	= O.[OrganisationId]
				INNER JOIN	@organisationIds		XO	ON	O.[OrganisationId]			= XO.[Id]
				LEFT JOIN	@currency				X	ON	C.[CurrencyId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;

END
GO
