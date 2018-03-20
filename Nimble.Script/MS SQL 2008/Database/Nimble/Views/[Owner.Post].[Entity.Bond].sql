SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Post'	AND
			O.[type]	= 'V'			AND
			O.[name]	= 'Entity.Bond'))
	DROP VIEW [Owner.Post].[Entity.Bond];
GO

CREATE VIEW [Owner.Post].[Entity.Bond]
AS
SELECT * FROM [Owner.Post].[Group]		G
INNER JOIN	[Owner.Post].[Split]		S	ON	G.[GroupSplitId]				= S.[SplitId]
INNER JOIN	[Owner].[Organisation]		O	ON	S.[SplitOrganisationId]			= O.[OrganisationId]
INNER JOIN	[Security].[Emplacement]	E	ON	O.[OrganisationEmplacementId]	= E.[EmplacementId]
INNER JOIN	[Owner].[Post]				P	ON	S.[SplitOrganisationId]			= P.[PostOrganisationId]
GO
