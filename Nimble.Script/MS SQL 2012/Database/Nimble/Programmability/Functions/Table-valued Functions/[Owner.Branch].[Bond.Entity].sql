SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Branch'	AND
			O.[type]	= 'IF'				AND
			O.[name]	= 'Bond.Entity'))
	DROP FUNCTION [Owner.Branch].[Bond.Entity];
GO

CREATE FUNCTION [Owner.Branch].[Bond.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		X.[BranchId],
		COALESCE(XBS.[GroupId], XGD.[GroupId])	[GroupId]
	FROM 
	(
		SELECT TOP 1
			B.[Id]	[BranchId],
			G.[Id]	[GroupId],
			G.[SplitId]
		FROM 
		(
			SELECT
				X.[Entity].query('Branch')		[Branch],
				X.[Entity].query('BranchGroup')	[BranchGroup]
			FROM @entity.nodes('/*') X ([Entity])
		)															X
		OUTER APPLY [Owner].[Branch.Entity](X.[Branch])				B
		OUTER APPLY [Owner.Branch].[Group.Entity](X.[BranchGroup])	G
	)									X
	LEFT JOIN	
	(
		SELECT * FROM [Owner.Branch].[Bond]	B
		INNER JOIN	[Owner.Branch].[Group]	G	ON	B.[BondGroupId]		= G.[GroupId]
		INNER JOIN	[Owner.Branch].[Split]	S	ON	G.[GroupSplitId]	= S.[SplitId]
		WHERE S.[SplitIsExclusive] = 1
	)									XBS	ON	X.[BranchId]	= XBS.[BondBranchId]	AND
												(X.[GroupId]	= XBS.[GroupId] OR
												X.[SplitId]		= XBS.[GroupSplitId])
	LEFT JOIN	
	(
		SELECT * FROM [Owner.Branch].[Group]	G
		WHERE G.[GroupIsDefault] = 1
	)									XGD	ON	X.[SplitId]		= XGD.[GroupSplitId]
)
GO
