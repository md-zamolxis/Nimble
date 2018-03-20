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
			O.[name]	= 'CK_PostBond_Organisation_PostId_GroupId'))
	ALTER TABLE [Owner.Post].[Bond] DROP CONSTRAINT [CK_PostBond_Organisation_PostId_GroupId];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Post'	AND
			O.[type]	= 'FN'			AND
			O.[name]	= 'Bond.Organisation.IsValid'))
	DROP FUNCTION [Owner.Post].[Bond.Organisation.IsValid];
GO

CREATE FUNCTION [Owner.Post].[Bond.Organisation.IsValid]
(
	@postId		UNIQUEIDENTIFIER,
	@groupId	UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (NOT EXISTS (
			SELECT * FROM [Owner.Post].[Group]	G
			INNER JOIN	[Owner.Post].[Split]	S	ON	G.[GroupSplitId]		= S.[SplitId]
			INNER JOIN	[Owner].[Post]			P	ON	S.[SplitOrganisationId]	= P.[PostOrganisationId]
			WHERE 
				G.[GroupId]	= @groupId	AND
				P.[PostId]	= @postId
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Owner.Post].[Bond] WITH CHECK ADD CONSTRAINT [CK_PostBond_Organisation_PostId_GroupId] CHECK ((
	[Owner.Post].[Bond.Organisation.IsValid]
	(
		[BondPostId],
		[BondGroupId]
	)=(1)
))
GO

ALTER TABLE [Owner.Post].[Bond] CHECK CONSTRAINT [CK_PostBond_Organisation_PostId_GroupId]
GO
