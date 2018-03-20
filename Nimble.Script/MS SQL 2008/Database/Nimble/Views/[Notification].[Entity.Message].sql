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
			O.[name]	= 'Entity.Message'))
	DROP VIEW [Notification].[Entity.Message];
GO

CREATE VIEW [Notification].[Entity.Message]
AS
SELECT * FROM [Notification].[Message]	M
INNER JOIN	[Notification].[Publisher]	P	ON	M.[MessagePublisherId]			= P.[PublisherId]
INNER JOIN	[Owner].[Organisation]		O	ON	P.[PublisherOrganisationId]		= O.[OrganisationId]
INNER JOIN	[Security].[Emplacement]	E	ON	O.[OrganisationEmplacementId]	= E.[EmplacementId]
GO
