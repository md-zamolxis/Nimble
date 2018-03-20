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
			O.[name]	= 'Trace.Entity'))
	DROP FUNCTION [Notification].[Trace.Entity];
GO

CREATE FUNCTION [Notification].[Trace.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[TraceId], XMS.[TraceId])	[Id],
		X.[MessageId],
		X.[SubscriberId],
		X.[CreatedOn],
		X.[ReadOn],
		X.[Settings],
		X.[Version]
	FROM 
	(
		SELECT TOP 1
			X.[Id],
			M.[Id]	[MessageId],
			S.[Id]	[SubscriberId],
			X.[CreatedOn],
			X.[ReadOn],
			X.[Settings],
			X.[Version]
		FROM 
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',								'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Message')								   							[Message],
				X.[Entity].query('Subscriber')								   						[Subscriber],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('CreatedOn'))						[CreatedOn],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('ReadOn'))						[ReadOn],
				X.[Entity].query('Settings/*')														[Settings],
				X.[Entity].value('(Version/text())[1]',							'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)																X
		OUTER APPLY [Notification].[Message.Entity](X.[Message])		M
		OUTER APPLY [Notification].[Subscriber.Entity](X.[Subscriber])	S
	)									X
	LEFT JOIN	[Notification].[Trace]	XI	ON	X.[Id]				= XI.[TraceId]
	LEFT JOIN	[Notification].[Trace]	XMS	ON	X.[MessageId]		= XMS.[TraceMessageId]	AND
												X.[SubscriberId]	= XMS.[TraceSubscriberId]
)
GO
