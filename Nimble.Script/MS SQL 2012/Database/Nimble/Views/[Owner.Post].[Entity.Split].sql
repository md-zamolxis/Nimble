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
			O.[name]	= 'Entity.Split'))
	DROP VIEW [Owner.Post].[Entity.Split];
GO

CREATE VIEW [Owner.Post].[Entity.Split]
AS
SELECT * FROM [Owner.Post].[Split]		S
INNER JOIN	[Owner].[Organisation]		O	ON	S.[SplitOrganisationId]			= O.[OrganisationId]
INNER JOIN	[Security].[Emplacement]	E	ON	O.[OrganisationEmplacementId]	= E.[EmplacementId]
GO
