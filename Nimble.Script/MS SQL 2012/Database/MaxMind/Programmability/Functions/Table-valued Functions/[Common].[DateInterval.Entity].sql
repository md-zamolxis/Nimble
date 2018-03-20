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
			O.[name]	= 'DateInterval.Entity'))
	DROP FUNCTION [Common].[DateInterval.Entity];
GO

CREATE FUNCTION [Common].[DateInterval.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN
(
	SELECT 
		[Common].[DateTimeOffset.Entity](X.[Entity].query('(DateFrom)'))	[DateFrom],
		[Common].[DateTimeOffset.Entity](X.[Entity].query('(DateTo)'))		[DateTo]
	FROM @entity.nodes('/*') X ([Entity])
)
GO
