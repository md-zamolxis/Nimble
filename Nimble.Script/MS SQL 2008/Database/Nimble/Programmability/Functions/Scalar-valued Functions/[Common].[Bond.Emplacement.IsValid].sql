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
			O.[name]	= 'CK_Bond_Emplacement_EntityId_GroupId'))
	ALTER TABLE [Common].[Bond] DROP CONSTRAINT [CK_Bond_Emplacement_EntityId_GroupId];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'FN'		AND
			O.[name]	= 'Bond.Emplacement.IsValid'))
	DROP FUNCTION [Common].[Bond.Emplacement.IsValid];
GO

CREATE FUNCTION [Common].[Bond.Emplacement.IsValid]
(
	@entityId	UNIQUEIDENTIFIER,
	@groupId	UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (NOT EXISTS (
			SELECT * FROM [Common].[Group]	G
			INNER JOIN	[Common].[Split]	S	ON	G.[GroupSplitId]		= S.[SplitId]
			LEFT JOIN (
				SELECT O.[OrganisationEmplacementId]	[EmplacementId]
				FROM [Owner].[Branch]				B
				INNER JOIN	[Owner].[Organisation]	O	ON	B.[BranchOrganisationId]	= O.[OrganisationId]
				WHERE B.[BranchId] = @entityId
			)								XB	ON	S.[SplitEntityType]		= 'Branch'	AND
													S.[SplitEmplacementId]	= XB.[EmplacementId]
			WHERE 
				G.[GroupId]			= @groupId	AND
				XB.[EmplacementId]	IS NOT NULL
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Common].[Bond] WITH CHECK ADD CONSTRAINT [CK_Bond_Emplacement_EntityId_GroupId] CHECK ((
	[Common].[Bond.Emplacement.IsValid]
	(
		[BondEntityId],
		[BondGroupId]
	)=(1)
))
GO

ALTER TABLE [Common].[Bond] CHECK CONSTRAINT [CK_Bond_Emplacement_EntityId_GroupId]
GO
