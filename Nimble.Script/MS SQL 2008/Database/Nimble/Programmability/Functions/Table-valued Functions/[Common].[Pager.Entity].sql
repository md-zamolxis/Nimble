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
			O.[name]	= 'Pager.Entity'))
	DROP FUNCTION [Common].[Pager.Entity];
GO

CREATE FUNCTION [Common].[Pager.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN
(
	SELECT 
		P.[Index] * (P.[Size] - P.[StartLag]) + 1	[StartNumber],
		(P.[Index] + 1) * (P.[Size] - P.[StartLag])	[EndNumber]
	FROM
	(
		SELECT 
			X.[Entity].value('(Index/text())[1]',			'INT')		[Index],
			X.[Entity].value('(Size/text())[1]',			'INT')		[Size],
			ISNULL(X.[Entity].value('(StartLag/text())[1]',	'INT'), 0)	[StartLag]
		FROM @entity.nodes('/*') X ([Entity])
	) P
)
GO
