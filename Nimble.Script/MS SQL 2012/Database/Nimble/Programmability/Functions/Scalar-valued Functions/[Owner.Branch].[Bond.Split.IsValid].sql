SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Branch'	AND
			O.[type]	= 'C'				AND
			O.[name]	= 'CK_BranchBond_Split_BranchId_GroupId'))
	ALTER TABLE [Owner.Branch].[Bond] DROP CONSTRAINT [CK_BranchBond_Split_BranchId_GroupId];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Branch'	AND
			O.[type]	= 'FN'				AND
			O.[name]	= 'Bond.Split.IsValid'))
	DROP FUNCTION [Owner.Branch].[Bond.Split.IsValid];
GO

CREATE FUNCTION [Owner.Branch].[Bond.Split.IsValid]
(
	@branchId	UNIQUEIDENTIFIER,
	@groupId	UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (EXISTS (
			SELECT * FROM [Owner.Branch].[Bond]	B
			INNER JOIN	[Owner.Branch].[Group]	GB	ON	B.[BondGroupId]		= GB.[GroupId]
			INNER JOIN	[Owner.Branch].[Group]	GS	ON	GB.[GroupSplitId]	= GS.[GroupSplitId]
			INNER JOIN	[Owner.Branch].[Split]	S	ON	GS.[GroupSplitId]	= S.[SplitId]
			WHERE 
				B.[BondBranchId]		= @branchId	AND
				GS.[GroupId]			= @groupId	AND
				S.[SplitIsExclusive]	= 1
			HAVING COUNT(*) > 1
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Owner.Branch].[Bond] WITH CHECK ADD CONSTRAINT [CK_BranchBond_Split_BranchId_GroupId] CHECK ((
	[Owner.Branch].[Bond.Split.IsValid]
	(
		[BondBranchId],
		[BondGroupId]
	)=(1)
))
GO

ALTER TABLE [Owner.Branch].[Bond] CHECK CONSTRAINT [CK_BranchBond_Split_BranchId_GroupId]
GO
