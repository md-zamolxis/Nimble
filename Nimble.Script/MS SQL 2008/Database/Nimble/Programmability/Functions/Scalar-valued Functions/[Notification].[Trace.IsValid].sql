SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Notification'	AND
			O.[type]	= 'C'				AND
			O.[name]	= 'CK_Trace_MessageId_SubscriberId'))
	ALTER TABLE [Notification].[Trace] DROP CONSTRAINT [CK_Trace_MessageId_SubscriberId];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Notification'	AND
			O.[type]	= 'FN'				AND
			O.[name]	= 'Trace.IsValid'))
	DROP FUNCTION [Notification].[Trace.IsValid];
GO

CREATE FUNCTION [Notification].[Trace.IsValid]
(
	@messageId		UNIQUEIDENTIFIER,
	@subscriberId	UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (NOT EXISTS (
			SELECT * FROM [Notification].[Message]	M
			INNER JOIN	[Notification].[Subscriber]	S	ON	M.[MessagePublisherId]	= S.[SubscriberPublisherId]
			WHERE 
				M.[MessageId]		= @messageId	AND
				S.[SubscriberId]	= @subscriberId
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Notification].[Trace] WITH CHECK ADD CONSTRAINT [CK_Trace_MessageId_SubscriberId] CHECK ((
	[Notification].[Trace.IsValid]
	(
		[TraceMessageId],
		[TraceSubscriberId]
	)=(1)
))
GO

ALTER TABLE [Notification].[Trace] CHECK CONSTRAINT [CK_Trace_MessageId_SubscriberId]
GO
