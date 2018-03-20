SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Post'	AND
			O.[type]	= 'C'			AND
			O.[name]	= 'CK_PostBond_Split_PostId_GroupId'))
	ALTER TABLE [Owner.Post].[Bond] DROP CONSTRAINT [CK_PostBond_Split_PostId_GroupId];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Post'	AND
			O.[type]	= 'FN'			AND
			O.[name]	= 'Bond.Split.IsValid'))
	DROP FUNCTION [Owner.Post].[Bond.Split.IsValid];
GO

CREATE FUNCTION [Owner.Post].[Bond.Split.IsValid]
(
	@postId		UNIQUEIDENTIFIER,
	@groupId	UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (EXISTS (
			SELECT * FROM [Owner.Post].[Bond]	B
			INNER JOIN	[Owner.Post].[Group]	GB	ON	B.[BondGroupId]		= GB.[GroupId]
			INNER JOIN	[Owner.Post].[Group]	GS	ON	GB.[GroupSplitId]	= GS.[GroupSplitId]
			INNER JOIN	[Owner.Post].[Split]	S	ON	GS.[GroupSplitId]	= S.[SplitId]
			WHERE 
				B.[BondPostId]			= @postId	AND
				GS.[GroupId]			= @groupId	AND
				S.[SplitIsExclusive]	= 1
			HAVING COUNT(*) > 1
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Owner.Post].[Bond] WITH CHECK ADD CONSTRAINT [CK_PostBond_Split_PostId_GroupId] CHECK ((
	[Owner.Post].[Bond.Split.IsValid]
	(
		[BondPostId],
		[BondGroupId]
	)=(1)
))
GO

ALTER TABLE [Owner.Post].[Bond] CHECK CONSTRAINT [CK_PostBond_Split_PostId_GroupId]
GO
