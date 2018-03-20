SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'IF'		AND
			O.[name]	= 'AmountInterval.Entity'))
	DROP FUNCTION [Common].[AmountInterval.Entity];
GO

CREATE FUNCTION [Common].[AmountInterval.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN
(
	SELECT 
		[Common].[Decimal.Entity](X.[Entity].query('AmountFrom'))			[AmountFrom],
		[Common].[Decimal.Entity](X.[Entity].query('AmountTo'))				[AmountTo],
		[Common].[DateTimeOffset.Entity](X.[Entity].query('AmountDate'))	[AmountDate]
	FROM @entity.nodes('/*') X ([Entity])
)
GO
