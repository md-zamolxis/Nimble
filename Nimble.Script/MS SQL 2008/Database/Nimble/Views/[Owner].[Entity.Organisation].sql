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
			O.[name]	= 'Entity.Organisation'))
	DROP VIEW [Owner].[Entity.Organisation];
GO

CREATE VIEW [Owner].[Entity.Organisation]
AS
SELECT * FROM [Owner].[Organisation]		O
INNER JOIN	[Security].[Emplacement]		E	ON	O.[OrganisationEmplacementId]	= E.[EmplacementId]
LEFT JOIN	[Common].[Entity.Filestream]	F	ON	O.[OrganisationId]				= F.[FilestreamEntityId]	AND
													F.[FilestreamIsDefault]			= 1
GO
