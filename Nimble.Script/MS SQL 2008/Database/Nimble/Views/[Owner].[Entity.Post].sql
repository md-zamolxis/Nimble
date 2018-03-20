SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner'	AND
			O.[type]	= 'V'		AND
			O.[name]	= 'Entity.Post'))
	DROP VIEW [Owner].[Entity.Post];
GO

CREATE VIEW [Owner].[Entity.Post]
AS
SELECT * FROM [Owner].[Post]				P	
INNER JOIN	[Owner].[Organisation]			O	ON	P.[PostOrganisationId]			= O.[OrganisationId]
INNER JOIN	[Security].[Emplacement]		E	ON	O.[OrganisationEmplacementId]	= E.[EmplacementId]
LEFT JOIN	[Common].[Entity.Filestream]	F	ON	P.[PostId]						= F.[FilestreamEntityId]	AND
													F.[FilestreamIsDefault]			= 1
GO
