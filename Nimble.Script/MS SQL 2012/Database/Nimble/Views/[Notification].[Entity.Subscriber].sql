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
			O.[name]	= 'Entity.Subscriber'))
	DROP VIEW [Notification].[Entity.Subscriber];
GO

CREATE VIEW [Notification].[Entity.Subscriber]
AS
SELECT * FROM [Notification].[Subscriber]	S
INNER JOIN	[Notification].[Publisher]		PB	ON	S.[SubscriberPublisherId]		= PB.[PublisherId]
INNER JOIN	[Owner].[Organisation]			O	ON	PB.[PublisherOrganisationId]	= O.[OrganisationId]
INNER JOIN	[Security].[Emplacement]		E	ON	O.[OrganisationEmplacementId]	= E.[EmplacementId]
INNER JOIN	[Owner].[Person]				P	ON	S.[SubscriberPersonId]			= P.[PersonId]
LEFT JOIN	[Security].[User]				U	ON	P.[PersonUserId]				= U.[UserId]
GO
