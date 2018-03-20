SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Notification'	AND
			O.[type]	= 'V'				AND
			O.[name]	= 'Entity.Publisher'))
	DROP VIEW [Notification].[Entity.Publisher];
GO

CREATE VIEW [Notification].[Entity.Publisher]
AS
SELECT * FROM [Notification].[Publisher]	P
INNER JOIN	[Owner].[Organisation]			O	ON	P.[PublisherOrganisationId]		= O.[OrganisationId]
INNER JOIN	[Security].[Emplacement]		E	ON	O.[OrganisationEmplacementId]	= E.[EmplacementId]
GO
