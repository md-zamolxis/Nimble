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
			O.[name]	= 'CK_BranchBond_Organisation_BranchId_GroupId'))
	ALTER TABLE [Owner.Branch].[Bond] DROP CONSTRAINT [CK_BranchBond_Organisation_BranchId_GroupId];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Branch'	AND
			O.[type]	= 'FN'				AND
			O.[name]	= 'Bond.Organisation.IsValid'))
	DROP FUNCTION [Owner.Branch].[Bond.Organisation.IsValid];
GO

CREATE FUNCTION [Owner.Branch].[Bond.Organisation.IsValid]
(
	@branchId	UNIQUEIDENTIFIER,
	@groupId	UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (NOT EXISTS (
			SELECT * FROM [Owner.Branch].[Group]	G
			INNER JOIN	[Owner.Branch].[Split]		S	ON	G.[GroupSplitId]		= S.[SplitId]
			INNER JOIN	[Owner].[Branch]			B	ON	S.[SplitOrganisationId]	= B.[BranchOrganisationId]
			WHERE 
				G.[GroupId]		= @groupId	AND
				B.[BranchId]	= @branchId
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Owner.Branch].[Bond] WITH CHECK ADD CONSTRAINT [CK_BranchBond_Organisation_BranchId_GroupId] CHECK ((
	[Owner.Branch].[Bond.Organisation.IsValid]
	(
		[BondBranchId],
		[BondGroupId]
	)=(1)
))
GO

ALTER TABLE [Owner.Branch].[Bond] CHECK CONSTRAINT [CK_BranchBond_Organisation_BranchId_GroupId]
GO
