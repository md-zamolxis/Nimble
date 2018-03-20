SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Notification'	AND
			O.[type]	= 'IF'				AND
			O.[name]	= 'Subscriber.Entity'))
	DROP FUNCTION [Notification].[Subscriber.Entity];
GO

CREATE FUNCTION [Notification].[Subscriber.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[SubscriberId], XPP.[SubscriberId])	[Id],
		X.[PublisherId],
		X.[PersonId],
		X.[NotificationType],
		X.[CreatedOn],
		X.[LockedOn],
		X.[Settings],
		X.[Version]
	FROM 
	(
		SELECT TOP 1
			X.[Id],
			PB.[Id] [PublisherId],
			P.[Id]	[PersonId],
			X.[NotificationType],
			X.[CreatedOn],
			X.[LockedOn],
			X.[Settings],
			X.[Version]
		FROM 
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',								'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Publisher')								   						[Publisher],
				X.[Entity].query('Person')								   							[Person],
				X.[Entity].value('(NotificationType/Line/text())[1]',			'NVARCHAR(MAX)')	[NotificationType],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('CreatedOn'))						[CreatedOn],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('LockedOn'))						[LockedOn],
				X.[Entity].query('Settings/*')														[Settings],
				X.[Entity].value('(Version/text())[1]',							'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)																X
		OUTER APPLY [Notification].[Publisher.Entity](X.[Publisher])	PB
		OUTER APPLY [Owner].[Person.Entity](X.[Person])					P
	)										X
	LEFT JOIN	[Notification].[Subscriber]	XI	ON	X.[Id]			= XI.[SubscriberId]
	LEFT JOIN	[Notification].[Subscriber]	XPP	ON	X.[PublisherId]	= XPP.[SubscriberPublisherId]	AND
													X.[PersonId]	= XPP.[SubscriberPersonId]
)
GO
