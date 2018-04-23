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
			O.[name]	= 'Message.Entity'))
	DROP FUNCTION [Notification].[Message.Entity];
GO

CREATE FUNCTION [Notification].[Message.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[MessageId], XPC.[MessageId])	[Id],
		X.[PublisherId],
		X.[Code],
		X.[NotificationType],
		X.[MessageActionType],
		X.[CreatedOn],
		X.[Title],
		X.[Body],
		X.[Sound],
		X.[Icon],
		X.[MessageEntityType],
		X.[EntityId],
		X.[Settings],
		X.[Version]
	FROM 
	(
		SELECT TOP 1
			X.[Id],
			P.[Id]	[PublisherId],
			X.[Code],
			X.[NotificationType],
			X.[MessageActionType],
			X.[CreatedOn],
			X.[Title],
			X.[Body],
			X.[Sound],
			X.[Icon],
			X.[MessageEntityType],
			X.[EntityId],
			X.[Settings],
			X.[Version]
		FROM 
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',								'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Publisher')								   						[Publisher],
				X.[Entity].value('(Code/text())[1]',							'NVARCHAR(MAX)')	[Code],
				X.[Entity].value('(NotificationType/Line/text())[1]',			'NVARCHAR(MAX)')	[NotificationType],
				X.[Entity].value('(MessageActionType/text())[1]',				'NVARCHAR(MAX)')	[MessageActionType],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('CreatedOn'))						[CreatedOn],
				X.[Entity].value('(Title/text())[1]',							'NVARCHAR(MAX)')	[Title],
				X.[Entity].value('(Body/text())[1]',							'NVARCHAR(MAX)')	[Body],
				X.[Entity].value('(Sound/text())[1]',							'NVARCHAR(MAX)')	[Sound],
				X.[Entity].value('(Icon/text())[1]',							'NVARCHAR(MAX)')	[Icon],
				X.[Entity].value('(MessageEntityType/text())[1]',				'NVARCHAR(MAX)')	[MessageEntityType],
				X.[Entity].value('(EntityId/text())[1]',						'UNIQUEIDENTIFIER')	[EntityId],
				X.[Entity].query('Settings/*')														[Settings],
				X.[Entity].value('(Version/text())[1]',							'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)																X
		OUTER APPLY [Notification].[Publisher.Entity](X.[Publisher])	P
	)										X
	LEFT JOIN	[Notification].[Message]	XI	ON	X.[Id]			= XI.[MessageId]
	LEFT JOIN	[Notification].[Message]	XPC	ON	X.[PublisherId]	= XPC.[MessagePublisherId]	AND
													X.[Code]		= XPC.[MessageCode]
)
GO
