SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multicurrency'	AND
			O.[type]	= 'C'				AND
			O.[name]	= 'CK_Rate_TradeId_CurrencyFrom_CurrencyTo'))
	ALTER TABLE [Multicurrency].[Rate] DROP CONSTRAINT [CK_Rate_TradeId_CurrencyFrom_CurrencyTo];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multicurrency'	AND
			O.[type]	= 'FN'				AND
			O.[name]	= 'Rate.IsValid'))
	DROP FUNCTION [Multicurrency].[Rate.IsValid];
GO

CREATE FUNCTION [Multicurrency].[Rate.IsValid]
(
	@tradeId		UNIQUEIDENTIFIER,
	@currencyFrom	UNIQUEIDENTIFIER,
	@currencyTo		UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (NOT EXISTS (
			SELECT * FROM [Multicurrency].[Trade]	T
			INNER JOIN	[Multicurrency].[Currency]	CF	ON	T.[TradeOrganisationId]	= CF.[CurrencyOrganisationId]
			INNER JOIN	[Multicurrency].[Currency]	CT	ON	T.[TradeOrganisationId]	= CT.[CurrencyOrganisationId]
			WHERE 
				T.[TradeId]		= @tradeId		AND
				CF.[CurrencyId]	= @currencyFrom	AND
				CT.[CurrencyId]	= @currencyTo
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Multicurrency].[Rate] WITH CHECK ADD CONSTRAINT [CK_Rate_TradeId_CurrencyFrom_CurrencyTo] CHECK ((
	[Multicurrency].[Rate.IsValid]
	(
		[RateTradeId],
		[RateCurrencyFrom],
		[RateCurrencyTo]
	)=(1)
))
GO

ALTER TABLE [Multicurrency].[Rate] CHECK CONSTRAINT [CK_Rate_TradeId_CurrencyFrom_CurrencyTo]
GO
