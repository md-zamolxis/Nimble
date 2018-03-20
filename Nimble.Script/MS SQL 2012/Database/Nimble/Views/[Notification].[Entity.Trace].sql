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
			O.[name]	= 'Entity.Trace'))
	DROP VIEW [Notification].[Entity.Trace];
GO

CREATE VIEW [Notification].[Entity.Trace]
AS
SELECT * FROM [Notification].[Trace]	T
INNER JOIN	[Notification].[Message]	M	ON	T.[TraceMessageId]				= M.[MessageId]
INNER JOIN	[Notification].[Publisher]	PB	ON	M.[MessagePublisherId]			= PB.[PublisherId]
INNER JOIN	[Owner].[Organisation]		O	ON	PB.[PublisherOrganisationId]	= O.[OrganisationId]
INNER JOIN	[Security].[Emplacement]	E	ON	O.[OrganisationEmplacementId]	= E.[EmplacementId]
INNER JOIN	[Notification].[Subscriber]	S	ON	T.[TraceSubscriberId]			= S.[SubscriberId]
INNER JOIN	[Owner].[Person]			P	ON	S.[SubscriberPersonId]			= P.[PersonId]
LEFT JOIN	[Security].[User]			U	ON	P.[PersonUserId]				= U.[UserId]
GO
