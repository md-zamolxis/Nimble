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
			O.[name]	= 'Generic.Entities'))
	DROP FUNCTION [Common].[Generic.Entities];
GO

CREATE FUNCTION [Common].[Generic.Entities](@entities XML)
RETURNS TABLE 
AS
RETURN
(
	SELECT * FROM
	(
		SELECT X.[Entity].query('.') [Entity]
		FROM @entities.nodes('/*') X ([Entity])
	) X
)
GO
