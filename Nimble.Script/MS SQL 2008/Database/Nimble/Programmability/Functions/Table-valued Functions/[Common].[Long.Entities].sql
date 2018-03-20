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
			O.[name]	= 'Long.Entities'))
	DROP FUNCTION [Common].[Long.Entities];
GO

CREATE FUNCTION [Common].[Long.Entities](@entities XML)
RETURNS TABLE 
AS
RETURN
(
	SELECT X.[long] FROM
	(
		SELECT LTRIM(X.[Entity].value('(text())[1]',	'BIGINT')) [long]
		FROM @entities.nodes('/*/long') X ([Entity])
	) X
)
GO
