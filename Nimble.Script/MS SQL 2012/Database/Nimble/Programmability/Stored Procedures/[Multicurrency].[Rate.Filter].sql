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
			O.[name]	= 'Rate.Filter'))
	DROP PROCEDURE [Multicurrency].[Rate.Filter];
GO

CREATE PROCEDURE [Multicurrency].[Rate.Filter]
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
	
	DECLARE @rate TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
	DECLARE 
		@criteria			XML,
		@criteriaExist		BIT,
		@criteriaIsNull		BIT,
		@criteriaValue		XML,
		@criteriaValueExist	BIT,
		@amountFrom			DECIMAL(28, 9),
		@amountTo			DECIMAL(28, 9);
	
	SET @isFiltered = 0;

--	Filter by entities
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Rates')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Rate');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Multicurrency].[Rate.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @rate SELECT * FROM @entities;
				ELSE
					INSERT @rate SELECT R.[RateId] FROM [Multicurrency].[Rate] R
					WHERE R.[RateId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @rate X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @rate X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

--	Filter by trade predicate
	DECLARE 
		@tradePredicate		XML,
		@tradeIsCountable	BIT,
		@tradeGuids			XML,
		@tradeIsFiltered	BIT,
		@tradeNumber		INT;
	SELECT 
		@tradePredicate		= X.[Criteria],
		@tradeIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/TradePredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @trade TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Multicurrency].[Trade.Filter]
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
			@predicate		= @tradePredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @tradeIsCountable,
			@guids			= @tradeGuids		OUTPUT,
			@isExcluded		= @isExcluded		OUTPUT,
			@isFiltered		= @tradeIsFiltered	OUTPUT,
			@number			= @tradeNumber		OUTPUT;
		INSERT @trade SELECT * FROM [Common].[Guid.Entities](@tradeGuids);
		IF (@tradeIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @rate SELECT R.[RateId] FROM [Multicurrency].[Rate] R
					INNER JOIN	@trade	X	ON	R.[RateTradeId]	= X.[Id];
				ELSE
					INSERT @rate SELECT R.[RateId] FROM [Multicurrency].[Rate] R
					LEFT JOIN	@trade	X	ON	R.[RateTradeId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @rate	X
					LEFT JOIN
					(
						SELECT R.[RateId] FROM [Multicurrency].[Rate] R
						INNER JOIN	@trade	X	ON	R.[RateTradeId]	= X.[Id]
					)	R	ON	X.[Id]	= R.[RateId]
					WHERE R.[RateId] IS NULL;
				ELSE
					DELETE X FROM @rate	X
					LEFT JOIN
					(
						SELECT R.[RateId] FROM [Multicurrency].[Rate] R
						LEFT JOIN	@trade	X	ON	R.[RateTradeId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	R	ON	X.[Id]	= R.[RateId]
					WHERE R.[RateId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by currency from/to predicate
	DECLARE 
		@currencyFromPredicate		XML,
		@currencyFromIsCountable	BIT,
		@currencyFromGuids			XML,
		@currencyFromIsFiltered		BIT,
		@currencyFromNumber			INT;
	SELECT 
		@currencyFromPredicate		= X.[Criteria],
		@currencyFromIsCountable	= 0,
		@criteriaExist				= X.[CriteriaExist],
		@isExcluded					= X.[CriteriaIsExcluded],
		@criteriaIsNull				= X.[CriteriaIsNull],
		@criteriaValue				= X.[CriteriaValue],
		@criteriaValueExist			= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/CurrencyFromPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @currencyFrom TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Multicurrency].[Currency.Filter]
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
			@predicate		= @currencyFromPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @currencyFromIsCountable,
			@guids			= @currencyFromGuids		OUTPUT,
			@isExcluded		= @isExcluded				OUTPUT,
			@isFiltered		= @currencyFromIsFiltered	OUTPUT,
			@number			= @currencyFromNumber		OUTPUT;
		INSERT @currencyFrom SELECT * FROM [Common].[Guid.Entities](@currencyFromGuids);
		IF (@currencyFromIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @rate SELECT R.[RateId] FROM [Multicurrency].[Rate] R
					INNER JOIN	@currencyFrom	X	ON	R.[RateCurrencyFrom]	= X.[Id];
				ELSE
					INSERT @rate SELECT R.[RateId] FROM [Multicurrency].[Rate] R
					INNER JOIN	@currencyFrom	X	ON	R.[RateCurrencyFrom]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @rate	X
					LEFT JOIN
					(
						SELECT R.[RateId] FROM [Multicurrency].[Rate] R
						INNER JOIN	@currencyFrom	X	ON	R.[RateCurrencyFrom]	= X.[Id]
					)	R	ON	X.[Id]	= R.[RateId]
					WHERE R.[RateId] IS NULL;
				ELSE
					DELETE X FROM @rate	X
					LEFT JOIN
					(
						SELECT R.[RateId] FROM [Multicurrency].[Rate] R
						INNER JOIN	@currencyFrom	X	ON	R.[RateCurrencyFrom]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	R	ON	X.[Id]	= R.[RateId]
					WHERE R.[RateId] IS NULL;
			SET @isFiltered = 1;
		END
	END
		
	DECLARE 
		@currencyToPredicate	XML,
		@currencyToIsCountable	BIT,
		@currencyToGuids		XML,
		@currencyToIsFiltered	BIT,
		@currencyToNumber		INT;
	SELECT 
		@currencyToPredicate	= X.[Criteria],
		@currencyToIsCountable	= 0,
		@criteriaExist			= X.[CriteriaExist],
		@isExcluded				= X.[CriteriaIsExcluded],
		@criteriaIsNull			= X.[CriteriaIsNull],
		@criteriaValue			= X.[CriteriaValue],
		@criteriaValueExist		= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/CurrencyToPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @currencyTo TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Multicurrency].[Currency.Filter]
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
			@predicate		= @currencyToPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @currencyToIsCountable,
			@guids			= @currencyToGuids		OUTPUT,
			@isExcluded		= @isExcluded			OUTPUT,
			@isFiltered		= @currencyToIsFiltered	OUTPUT,
			@number			= @currencyToNumber		OUTPUT;
		INSERT @currencyTo SELECT * FROM [Common].[Guid.Entities](@currencyToGuids);
		IF (@currencyToIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @rate SELECT R.[RateId] FROM [Multicurrency].[Rate] R
					INNER JOIN	@currencyTo	X	ON	R.[RateCurrencyTo]	= X.[Id];
				ELSE
					INSERT @rate SELECT R.[RateId] FROM [Multicurrency].[Rate] R
					INNER JOIN	@currencyTo	X	ON	R.[RateCurrencyTo]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @rate	X
					LEFT JOIN
					(
						SELECT R.[RateId] FROM [Multicurrency].[Rate] R
						INNER JOIN	@currencyTo	X	ON	R.[RateCurrencyTo]	= X.[Id]
					)	R	ON	X.[Id]	= R.[RateId]
					WHERE R.[RateId] IS NULL;
				ELSE
					DELETE X FROM @rate	X
					LEFT JOIN
					(
						SELECT R.[RateId] FROM [Multicurrency].[Rate] R
						INNER JOIN	@currencyTo	X	ON	R.[RateCurrencyTo]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	R	ON	X.[Id]	= R.[RateId]
					WHERE R.[RateId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@organisations IS NOT NULL) BEGIN
		INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
		IF (@isFiltered = 0)
			INSERT @rate SELECT R.[RateId] FROM [Multicurrency].[Rate] R
			INNER JOIN	[Multicurrency].[Trade]	T	ON	R.[RateTradeId]			= T.[TradeId]
			INNER JOIN	@organisationIds		XO	ON	T.[TradeOrganisationId]	= XO.[Id];
		ELSE
			DELETE X FROM @rate					X 
			INNER JOIN	[Multicurrency].[Rate]	R	ON	X.[Id]					= R.[RateId]
			INNER JOIN	[Multicurrency].[Trade]	T	ON	R.[RateTradeId]			= T.[TradeId]
			LEFT JOIN	@organisationIds		XO	ON	T.[TradeOrganisationId]	= XO.[Id]
			WHERE XO.[Id] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by value
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Value')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @amountFrom = NULL, @amountTo = NULL;
		SELECT 
			@amountFrom	= X.[AmountFrom], 
			@amountTo	= X.[AmountTo] 
		FROM [Common].[AmountInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@amountFrom, @amountTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @rate SELECT R.[RateId] FROM [Multicurrency].[Rate] R
					WHERE R.[RateValue] BETWEEN ISNULL(@amountFrom, R.[RateValue]) AND ISNULL(@amountTo, R.[RateValue]);
				ELSE 
					INSERT @rate SELECT R.[RateId] FROM [Multicurrency].[Rate] R
					WHERE R.[RateValue] NOT BETWEEN ISNULL(@amountFrom, R.[RateValue]) AND ISNULL(@amountTo, R.[RateValue]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @rate	X
					LEFT JOIN
					(
						SELECT R.[RateId] FROM [Multicurrency].[Rate] R
						WHERE R.[RateValue] BETWEEN ISNULL(@amountFrom, R.[RateValue]) AND ISNULL(@amountTo, R.[RateValue])
					)	R	ON	X.[Id]	= R.[RateId]
					WHERE R.[RateId] IS NULL;
				ELSE
					DELETE X FROM @rate	X
					LEFT JOIN
					(
						SELECT R.[RateId] FROM [Multicurrency].[Rate] R
						WHERE R.[RateValue] NOT BETWEEN ISNULL(@amountFrom, R.[RateValue]) AND ISNULL(@amountTo, R.[RateValue])
					)	R	ON	X.[Id]	= R.[RateId]
					WHERE R.[RateId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @rate SELECT R.[RateId] FROM [Multicurrency].[Rate] R
			INNER JOIN	[Multicurrency].[Trade]		T	ON	R.[RateTradeId]			= T.[TradeId]
			INNER JOIN	[Owner].[Organisation]	O	ON	T.[TradeOrganisationId] = O.[OrganisationId]
			WHERE O.[OrganisationEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @rate	X
			LEFT JOIN
			(
				SELECT R.[RateId] FROM [Multicurrency].[Rate]	R
				INNER JOIN	[Multicurrency].[Trade]				T	ON	R.[RateTradeId]	= T.[TradeId]
				INNER JOIN	[Owner].[Organisation]			O	ON	T.[TradeOrganisationId] = O.[OrganisationId]
				WHERE O.[OrganisationEmplacementId] = @emplacementId
			)	R	ON	X.[Id]	= R.[RateId]
			WHERE R.[RateId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @rate X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Multicurrency].[Rate] R;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @rate X;
		ELSE
			IF (@organisations IS NULL)      
				SELECT @number = COUNT(*) FROM [Multicurrency].[Rate]	R
				INNER JOIN	[Multicurrency].[Trade]	T	ON	R.[RateTradeId]			= T.[TradeId]
				INNER JOIN	[Owner].[Organisation]	O	ON	T.[TradeOrganisationId]	= O.[OrganisationId]
				LEFT JOIN	@rate					X	ON	T.[TradeId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE
				SELECT @number = COUNT(*) FROM [Multicurrency].[Rate]	R
				INNER JOIN	[Multicurrency].[Trade]	T	ON	R.[RateTradeId]			= T.[TradeId]
				INNER JOIN	[Owner].[Organisation]	O	ON	T.[TradeOrganisationId]	= O.[OrganisationId]
				INNER JOIN	@organisationIds		XO	ON	O.[OrganisationId]		= XO.[Id]
				LEFT JOIN	@rate					X	ON	T.[TradeId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;

END
GO
