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
			O.[name]	= 'Flags.Entity'))
	DROP FUNCTION [Common].[Flags.Entity];
GO

CREATE FUNCTION [Common].[Flags.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN
(
	SELECT 
		X.[Entity].value('(Number/text())[1]',	'INT')					[Number],
		X.[Entity].value('(Line/text())[1]',	'NVARCHAR(MAX)')		[Line],
		ISNULL([Common].[Bool.Entity](X.[Entity].query('IsExact')), 0)	[IsExact]
	FROM @entity.nodes('/*') X ([Entity])
)
GO
