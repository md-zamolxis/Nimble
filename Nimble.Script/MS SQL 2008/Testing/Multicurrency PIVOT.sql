DECLARE 
	@pivot	NVARCHAR(MAX) = '',
	@data	NVARCHAR(MAX) = 
	'
		SELECT 
			R.[RateTradeId],
			R.[FromCurrencyCode],
			R.[ToCurrencyCode],
			R.[RateValue]
		FROM [Multicurrency].[Entity.Rate]	R
		INNER JOIN	[Multicurrency].[Trade]	T	ON	R.[RateTradeId]	= T.[TradeId]
		WHERE T.[TradeCode] = ''3''
	',
	@order	NVARCHAR(MAX) = 
	'
		ORDER BY 
			[EmplacementCode], 
			[OrganisationCode], 
			[TradeFrom],
			[FromCurrencyCode]
	';

SELECT @pivot = @pivot + '[' + C.[CurrencyCode] + '], '
FROM [Multicurrency].[Currency] C ORDER BY C.[CurrencyCode];

IF (@pivot = '') BEGIN
	PRINT 'No currencies defined.';
	RETURN;
END

SET @pivot = SUBSTRING(@pivot, 1, LEN(@pivot) - 1);

SELECT 
	@pivot = 
	'
		SELECT 
			T.[EmplacementCode],
			T.[OrganisationCode],
			T.[TradeCode],
			T.[TradeFrom],
			T.[TradeTo],
			P.[FromCurrencyCode],
			' + @pivot + '
		FROM [Multicurrency].[Entity.Trade]	T
		INNER JOIN
		(
				SELECT * FROM
				(
					' + @data + '
				)	D
				PIVOT
				(
					SUM([RateValue])
					FOR [ToCurrencyCode]
					IN 
					(
						' + @pivot + '
					)
				)	P
		)								P	ON	T.[TradeId]	= P.[RateTradeId]
	' + @order,
	@data = 
	'
		SELECT * 
		FROM [Multicurrency].[Entity.Trade]	T
		INNER JOIN 
		(
			' + @data + '
		)								D	ON	T.[TradeId]	= D.[RateTradeId]
	' + @order;

--PRINT @pivot;
--PRINT @data;

--EXEC sp_executesql @data;
EXEC sp_executesql @pivot;
