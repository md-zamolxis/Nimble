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
			O.[name]	= 'Enum.Entities'))
	DROP FUNCTION [Common].[Enum.Entities];
GO

CREATE FUNCTION [Common].[Enum.Entities](@entities XML)
RETURNS TABLE 
AS
RETURN
(
	SELECT X.[enum] FROM
	(
		SELECT LTRIM(X.[Entity].value('(text())[1]',	'NVARCHAR(MAX)')) [enum]
		FROM @entities.nodes('/*/*') X ([Entity])
	) X
)
GO
