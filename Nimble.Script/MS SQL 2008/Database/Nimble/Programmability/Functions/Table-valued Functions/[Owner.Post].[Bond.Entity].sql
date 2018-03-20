SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Post'	AND
			O.[type]	= 'IF'				AND
			O.[name]	= 'Bond.Entity'))
	DROP FUNCTION [Owner.Post].[Bond.Entity];
GO

CREATE FUNCTION [Owner.Post].[Bond.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		X.[PostId],
		COALESCE(XBS.[GroupId], XGD.[GroupId])	[GroupId]
	FROM 
	(
		SELECT TOP 1
			P.[Id]	[PostId],
			G.[Id]	[GroupId],
			G.[SplitId]
		FROM 
		(
			SELECT
				X.[Entity].query('Post')		[Post],
				X.[Entity].query('PostGroup')	[PostGroup]
			FROM @entity.nodes('/*') X ([Entity])
		)														X
		OUTER APPLY [Owner].[Post.Entity](X.[Post])				P
		OUTER APPLY [Owner.Post].[Group.Entity](X.[PostGroup])	G
	)									X
	LEFT JOIN	
	(
		SELECT * FROM [Owner.Post].[Group]	G
		INNER JOIN	[Owner.Post].[Bond]		B	ON	G.[GroupId]			= B.[BondGroupId]
		INNER JOIN	[Owner.Post].[Split]	S	ON	G.[GroupSplitId]	= S.[SplitId]
		WHERE S.[SplitIsExclusive] = 1
	)									XBS	ON	X.[PostId]		= XBS.[BondPostId]	AND
												(X.[GroupId]	= XBS.[GroupId]		OR
												X.[SplitId]		= XBS.[GroupSplitId])
	LEFT JOIN	
	(
		SELECT * FROM [Owner.Post].[Group]	G
		WHERE G.[GroupIsDefault] = 1
	)									XGD	ON	X.[SplitId]		= XGD.[GroupSplitId]
)
GO
