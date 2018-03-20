SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'C'		AND
			O.[name]	= 'CK_Bond_Split_EntityId_GroupId'))
	ALTER TABLE [Common].[Bond] DROP CONSTRAINT [CK_Bond_Split_EntityId_GroupId];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'FN'		AND
			O.[name]	= 'Bond.Split.IsValid'))
	DROP FUNCTION [Common].[Bond.Split.IsValid];
GO

CREATE FUNCTION [Common].[Bond.Split.IsValid]
(
	@entityId	UNIQUEIDENTIFIER,
	@groupId	UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (EXISTS (
			SELECT * FROM [Common].[Bond]	B
			INNER JOIN	[Common].[Group]	GB	ON	B.[BondGroupId]		= GB.[GroupId]
			INNER JOIN	[Common].[Group]	GS	ON	GB.[GroupSplitId]	= GS.[GroupSplitId]
			INNER JOIN	[Common].[Split]	S	ON	GS.[GroupSplitId]	= S.[SplitId]
			WHERE 
				B.[BondEntityId]		= @entityId	AND
				GS.[GroupId]			= @groupId	AND
				S.[SplitIsExclusive]	= 1
			HAVING COUNT(*) > 1
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Common].[Bond] WITH CHECK ADD CONSTRAINT [CK_Bond_Split_EntityId_GroupId] CHECK ((
	[Common].[Bond.Split.IsValid]
	(
		[BondEntityId],
		[BondGroupId]
	)=(1)
))
GO

ALTER TABLE [Common].[Bond] CHECK CONSTRAINT [CK_Bond_Split_EntityId_GroupId]
GO
