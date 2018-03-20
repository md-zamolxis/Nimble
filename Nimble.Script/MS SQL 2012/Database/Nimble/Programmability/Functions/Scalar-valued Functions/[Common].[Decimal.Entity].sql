SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'FN'		AND
			O.[name]	= 'Decimal.Entity'))
	DROP FUNCTION [Common].[Decimal.Entity];
GO

CREATE FUNCTION [Common].[Decimal.Entity](@entity XML)
RETURNS DECIMAL(28, 9)
AS
BEGIN
	RETURN (SELECT X.[Entity].value('(text())[1]',	'DECIMAL(28, 9)') FROM @entity.nodes('/*') X ([Entity]));
END
GO
