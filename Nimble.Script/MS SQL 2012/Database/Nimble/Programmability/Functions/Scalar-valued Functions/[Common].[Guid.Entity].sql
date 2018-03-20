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
			O.[name]	= 'Guid.Entity'))
	DROP FUNCTION [Common].[Guid.Entity];
GO

CREATE FUNCTION [Common].[Guid.Entity](@entity XML)
RETURNS UNIQUEIDENTIFIER
AS
BEGIN
	RETURN (SELECT X.[Entity].value('(text())[1]',	'UNIQUEIDENTIFIER') FROM @entity.nodes('/*') X ([Entity]));
END
GO
