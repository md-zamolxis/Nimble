SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'IF'			AND
			O.[name]	= 'Hierarchy.Entity'))
	DROP FUNCTION [Common].[Hierarchy.Entity];
GO

CREATE FUNCTION [Common].[Hierarchy.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		X.[Entity].value('(Code/text())[1]',		'NVARCHAR(MAX)')	[Code],
		X.[Entity].value('(EntityId/text())[1]',	'UNIQUEIDENTIFIER')	[EntityId],
		X.[Entity].value('(ParentId/text())[1]',	'UNIQUEIDENTIFIER')	[ParentId],
		X.[Entity].value('(Left/text())[1]',		'INT')				[Left],
		X.[Entity].value('(Right/text())[1]',		'INT')				[Right],
		X.[Entity].value('(Level/text())[1]',		'INT')				[Level]
	FROM @entity.nodes('/*') X ([Entity])
)
GO
