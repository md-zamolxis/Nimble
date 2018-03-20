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
			O.[name]	= 'Bond.Entity'))
	DROP FUNCTION [Common].[Bond.Entity];
GO

CREATE FUNCTION [Common].[Bond.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		X.[EntityId],
		COALESCE(XBS.[GroupId], XGD.[GroupId])	[GroupId]
	FROM 
	(
		SELECT TOP 1
			[EntityId],
			G.[Id]	[GroupId],
			G.[SplitId]
		FROM 
		(
			SELECT
				[Common].[Guid.Entity](X.[Entity].query('Entity'))	[EntityId],
				X.[Entity].query('Group')							[Group]
			FROM @entity.nodes('/*') X ([Entity])
		)												X
		OUTER APPLY [Common].[Group.Entity](X.[Group])	G
	)									X
	LEFT JOIN	
	(
		SELECT * FROM [Common].[Bond]	B
		INNER JOIN	[Common].[Group]	G	ON	B.[BondGroupId]		= G.[GroupId]
		INNER JOIN	[Common].[Split]	S	ON	G.[GroupSplitId]	= S.[SplitId]
		WHERE S.[SplitIsExclusive] = 1
	)									XBS	ON	X.[EntityId]	= XBS.[BondEntityId]	AND
												(X.[GroupId]	= XBS.[GroupId] OR
												X.[SplitId]		= XBS.[GroupSplitId])
	LEFT JOIN	
	(
		SELECT * FROM [Common].[Group]	G
		WHERE G.[GroupIsDefault] = 1
	)									XGD	ON	X.[SplitId]		= XGD.[GroupSplitId]
)
GO
