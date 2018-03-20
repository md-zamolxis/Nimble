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
			O.[name]	= 'Bool.Entity'))
	DROP FUNCTION [Common].[Bool.Entity];
GO

CREATE FUNCTION [Common].[Bool.Entity](@entity XML)
RETURNS BIT 
AS
BEGIN
	RETURN (SELECT X.[Entity].value('(text())[1]',	'BIT') FROM @entity.nodes('/*') X ([Entity]));
END
GO
