SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multicurrency'	AND
			O.[type]	= 'IF'				AND
			O.[name]	= 'Rate.Entity'))
	DROP FUNCTION [Multicurrency].[Rate.Entity];
GO

CREATE FUNCTION [Multicurrency].[Rate.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[RateId], XTCFCT.[RateId])	[Id],
		X.[TradeId],
		X.[CurrencyFrom],
		X.[CurrencyTo],
		X.[Value],
		X.[Version]
	FROM
	(
		SELECT TOP 1
			X.[Id],
			T.[Id]	[TradeId],
			CF.[Id]	[CurrencyFrom],
			CT.[Id]	[CurrencyTo],
			X.[Value],
			X.[Version]	
		FROM
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',					'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Trade')												[Trade],
				X.[Entity].query('CurrencyFrom')										[CurrencyFrom],
				X.[Entity].query('CurrencyTo')											[CurrencyTo],
				[Common].[Decimal.Entity](X.[Entity].query('Value'))					[Value],
				X.[Entity].value('(Version/text())[1]',				'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)															X
		OUTER APPLY [Multicurrency].[Trade.Entity](X.[Trade])			T
		OUTER APPLY [Multicurrency].[Currency.Entity](X.[CurrencyFrom])	CF
		OUTER APPLY [Multicurrency].[Currency.Entity](X.[CurrencyTo])	CT
	)									X
	LEFT JOIN	[Multicurrency].[Rate]	XI		ON	X.[Id]				= XI.[RateId]
	LEFT JOIN	[Multicurrency].[Rate]	XTCFCT	ON	X.[TradeId]			= XTCFCT.[RateTradeId]		AND
													X.[CurrencyFrom]	= XTCFCT.[RateCurrencyFrom]	AND
													X.[CurrencyTo]		= XTCFCT.[RateCurrencyTo]
)
GO
