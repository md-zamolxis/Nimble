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
			O.[name]	= 'Publisher.Entity'))
	DROP FUNCTION [Notification].[Publisher.Entity];
GO

CREATE FUNCTION [Notification].[Publisher.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[PublisherId], XO.[PublisherId])	[Id],
		X.[OrganisationId],
		X.[NotificationType],
		X.[CreatedOn],
		X.[LockedOn],
		X.[Settings],
		X.[Version]
	FROM 
	(
		SELECT TOP 1
			X.[Id],
			O.[Id]	[OrganisationId],
			X.[NotificationType],
			X.[CreatedOn],
			X.[LockedOn],
			X.[Settings],
			X.[Version]
		FROM 
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',								'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Organisation')								   					[Organisation],
				X.[Entity].value('(NotificationType/Line/text())[1]',			'NVARCHAR(MAX)')	[NotificationType],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('CreatedOn'))						[CreatedOn],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('LockedOn'))						[LockedOn],
				X.[Entity].query('Settings/*')														[Settings],
				X.[Entity].value('(Version/text())[1]',							'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)															X
		OUTER APPLY [Owner].[Organisation.Entity](X.[Organisation])	O
	)										X
	LEFT JOIN	[Notification].[Publisher]	XI	ON	X.[Id]				= XI.[PublisherId]
	LEFT JOIN	[Notification].[Publisher]	XO	ON	X.[OrganisationId]	= XO.[PublisherOrganisationId]
)
GO
