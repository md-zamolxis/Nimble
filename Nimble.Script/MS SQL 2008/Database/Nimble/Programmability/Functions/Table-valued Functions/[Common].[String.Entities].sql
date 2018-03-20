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
			O.[name]	= 'String.Entities'))
	DROP FUNCTION [Common].[String.Entities];
GO

CREATE FUNCTION [Common].[String.Entities](@entities XML)
RETURNS TABLE 
AS
RETURN
(
	SELECT X.[string] FROM
	(
		SELECT LTRIM(X.[Entity].value('(text())[1]',	'NVARCHAR(MAX)')) [string]
		FROM @entities.nodes('/*/string') X ([Entity])
	) X
)
GO
