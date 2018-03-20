SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multicurrency'	AND
			O.[type]	= 'P'				AND
			O.[name]	= 'Trade.Filter'))
	DROP PROCEDURE [Multicurrency].[Trade.Filter];
GO

CREATE PROCEDURE [Multicurrency].[Trade.Filter]
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
	
	DECLARE @trade TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Trades')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Trade');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Multicurrency].[Trade.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			DELETE X FROM @entities X WHERE X.[Id] IS NULL;
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @trade SELECT * FROM @entities;
				ELSE
					INSERT @trade SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
					WHERE T.[TradeId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @trade X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @trade X WHERE X.[Id] IN (SELECT * FROM @entities);
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
					INSERT @trade SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
					INNER JOIN	@organisation	X	ON	T.[TradeOrganisationId]	= X.[Id];
				ELSE
					INSERT @trade SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
					LEFT JOIN	@organisation	X	ON	T.[TradeOrganisationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @trade	X
					LEFT JOIN
					(
						SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
						INNER JOIN	@organisation	X	ON	T.[TradeOrganisationId]	= X.[Id]
					)	T	ON	X.[Id]	= T.[TradeId]
					WHERE T.[TradeId] IS NULL;
				ELSE
					DELETE X FROM @trade	X
					LEFT JOIN
					(
						SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
						LEFT JOIN	@organisation	X	ON	T.[TradeOrganisationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	T	ON	X.[Id]	= T.[TradeId]
					WHERE T.[TradeId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@organisations IS NOT NULL) BEGIN
		INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
		IF (@isFiltered = 0)
			INSERT @trade SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
			INNER JOIN	@organisationIds		XO	ON	T.[TradeOrganisationId]	= XO.[Id];
		ELSE
			DELETE X FROM @trade				X 
			INNER JOIN	[Multicurrency].[Trade]	T	ON	X.[Id]					= T.[TradeId]
			LEFT JOIN	@organisationIds		XO	ON	T.[TradeOrganisationId]	= XO.[Id]
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
					INSERT @trade SELECT DISTINCT T.[TradeId] FROM [Multicurrency].[Trade] T
					INNER JOIN	@codes	X	ON	T.[TradeCode]	LIKE X.[Code];
				ELSE 
					INSERT @trade SELECT DISTINCT T.[TradeId] FROM [Multicurrency].[Trade] T
					LEFT JOIN	@codes	X	ON	T.[TradeCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @trade	X
					LEFT JOIN
					(
						SELECT DISTINCT T.[TradeId] FROM [Multicurrency].[Trade] T
						INNER JOIN	@codes	X	ON	T.[TradeCode]	LIKE X.[Code]
					)	T	ON	X.[Id]	= T.[TradeId]
					WHERE T.[TradeId]	IS NULL;
				ELSE
					DELETE X FROM @trade	X
					LEFT JOIN
					(
						SELECT DISTINCT T.[TradeId] FROM [Multicurrency].[Trade] T
						LEFT JOIN	@codes	X	ON	T.[TradeCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	T	ON	X.[Id]	= T.[TradeId]
					WHERE T.[TradeId]	IS NULL;
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
					INSERT @trade SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
					WHERE T.[TradeCreatedOn] BETWEEN ISNULL(@dateFrom, T.[TradeCreatedOn]) AND ISNULL(@dateTo, T.[TradeCreatedOn]);
				ELSE 
					INSERT @trade SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
					WHERE T.[TradeCreatedOn] NOT BETWEEN ISNULL(@dateFrom, T.[TradeCreatedOn]) AND ISNULL(@dateTo, T.[TradeCreatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @trade	X
					LEFT JOIN
					(
						SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
						WHERE T.[TradeCreatedOn] BETWEEN ISNULL(@dateFrom, T.[TradeCreatedOn]) AND ISNULL(@dateTo, T.[TradeCreatedOn])
					)	T	ON	X.[Id]	= T.[TradeId]
					WHERE T.[TradeId] IS NULL;
				ELSE
					DELETE X FROM @trade	X
					LEFT JOIN
					(
						SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
						WHERE T.[TradeCreatedOn] NOT BETWEEN ISNULL(@dateFrom, T.[TradeCreatedOn]) AND ISNULL(@dateTo, T.[TradeCreatedOn])
					)	T	ON	X.[Id]	= T.[TradeId]
					WHERE T.[TradeId] IS NULL;
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
					INSERT @trade SELECT DISTINCT T.[TradeId] FROM [Multicurrency].[Trade] T
					INNER JOIN	@descriptions	X	ON	T.[TradeDescription]	LIKE X.[Description];
				ELSE 
					INSERT @trade SELECT DISTINCT T.[TradeId] FROM [Multicurrency].[Trade] T
					LEFT JOIN	@descriptions	X	ON	T.[TradeDescription]	LIKE X.[Description]
					WHERE X.[Description] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @trade	X
					LEFT JOIN
					(
						SELECT DISTINCT T.[TradeId] FROM [Multicurrency].[Trade] T
						INNER JOIN	@descriptions	X	ON	T.[TradeDescription]	LIKE X.[Description]
					)	T	ON	X.[Id]	= T.[TradeId]
					WHERE T.[TradeId]	IS NULL;
				ELSE
					DELETE X FROM @trade	X
					LEFT JOIN
					(
						SELECT DISTINCT T.[TradeId] FROM [Multicurrency].[Trade] T
						LEFT JOIN	@descriptions	X	ON	T.[TradeDescription]	LIKE X.[Description]
						WHERE X.[Description] IS NULL
					)	T	ON	X.[Id]	= T.[TradeId]
					WHERE T.[TradeId]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by from datetime offset
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/From')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @dateFrom = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @trade SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
					WHERE T.[TradeFrom] BETWEEN ISNULL(@dateFrom, T.[TradeFrom]) AND ISNULL(@dateTo, T.[TradeFrom]);
				ELSE 
					INSERT @trade SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
					WHERE T.[TradeFrom] NOT BETWEEN ISNULL(@dateFrom, T.[TradeFrom]) AND ISNULL(@dateTo, T.[TradeFrom]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @trade	X
					LEFT JOIN
					(
						SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
						WHERE T.[TradeFrom] BETWEEN ISNULL(@dateFrom, T.[TradeFrom]) AND ISNULL(@dateTo, T.[TradeFrom])
					)	T	ON	X.[Id]	= T.[TradeId]
					WHERE T.[TradeId] IS NULL;
				ELSE
					DELETE X FROM @trade	X
					LEFT JOIN
					(
						SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
						WHERE T.[TradeFrom] NOT BETWEEN ISNULL(@dateFrom, T.[TradeFrom]) AND ISNULL(@dateTo, T.[TradeFrom])
					)	T	ON	X.[Id]	= T.[TradeId]
					WHERE T.[TradeId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by to datetime offset
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/To')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @dateTo = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateTo, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @trade SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
					WHERE T.[TradeTo] BETWEEN ISNULL(@dateFrom, T.[TradeTo]) AND ISNULL(@dateTo, T.[TradeTo]);
				ELSE 
					INSERT @trade SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
					WHERE T.[TradeTo] NOT BETWEEN ISNULL(@dateFrom, T.[TradeTo]) AND ISNULL(@dateTo, T.[TradeTo]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @trade	X
					LEFT JOIN
					(
						SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
						WHERE T.[TradeTo] BETWEEN ISNULL(@dateFrom, T.[TradeTo]) AND ISNULL(@dateTo, T.[TradeTo])
					)	T	ON	X.[Id]	= T.[TradeId]
					WHERE T.[TradeId] IS NULL;
				ELSE
					DELETE X FROM @trade	X
					LEFT JOIN
					(
						SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
						WHERE T.[TradeTo] NOT BETWEEN ISNULL(@dateFrom, T.[TradeTo]) AND ISNULL(@dateTo, T.[TradeTo])
					)	T	ON	X.[Id]	= T.[TradeId]
					WHERE T.[TradeId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by applied datetime offset
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/AppliedOn')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @appliedOn DATETIMEOFFSET;
		SELECT @appliedOn = [Common].[DateTimeOffset.Entity](@criteriaValue);
		IF (@appliedOn IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @trade SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
					WHERE (T.[TradeFrom] < @appliedOn AND @appliedOn <= T.[TradeTo]);
				ELSE 
					INSERT @trade SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
					WHERE NOT (T.[TradeFrom] < @appliedOn AND @appliedOn <= T.[TradeTo]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @trade	X
					LEFT JOIN
					(
						SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
						WHERE (T.[TradeFrom] < @appliedOn AND @appliedOn <= T.[TradeTo])
					)	T	ON	X.[Id]	= T.[TradeId]
					WHERE T.[TradeId] IS NULL;
				ELSE
					DELETE X FROM @trade	X
					LEFT JOIN
					(
						SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
						WHERE NOT (T.[TradeFrom] < @appliedOn AND @appliedOn <= T.[TradeTo])
					)	T	ON	X.[Id]	= T.[TradeId]
					WHERE T.[TradeId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @trade SELECT T.[TradeId] FROM [Multicurrency].[Trade] T
			INNER JOIN	[Owner].[Organisation]	O	ON	T.[TradeOrganisationId]	= O.[OrganisationId]
			WHERE O.[OrganisationEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @trade	X
			LEFT JOIN
			(
				SELECT T.[TradeId] FROM [Multicurrency].[Trade]	T
				INNER JOIN	[Owner].[Organisation]				O	ON	T.[TradeOrganisationId]	= O.[OrganisationId]
				WHERE O.[OrganisationEmplacementId] = @emplacementId
			)	T	ON	X.[Id]	= T.[TradeId]
			WHERE T.[TradeId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @trade X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Multicurrency].[Trade] T;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @trade X;
		ELSE
			IF (@organisations IS NULL)      
				SELECT @number = COUNT(*) FROM [Multicurrency].[Trade] T
				INNER JOIN	[Owner].[Organisation]	O	ON	T.[TradeOrganisationId]	= O.[OrganisationId]
				LEFT JOIN	@trade					X	ON	T.[TradeId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE
				SELECT @number = COUNT(*) FROM [Multicurrency].[Trade] T
				INNER JOIN	[Owner].[Organisation]	O	ON	T.[TradeOrganisationId]	= O.[OrganisationId]
				INNER JOIN	@organisationIds		XO	ON	O.[OrganisationId]		= XO.[Id]
				LEFT JOIN	@trade					X	ON	T.[TradeId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;

END
GO
