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
			O.[name]	= 'CK_Subscriber_PublisherId_PersonId'))
	ALTER TABLE [Notification].[Subscriber] DROP CONSTRAINT [CK_Subscriber_PublisherId_PersonId];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Notification'	AND
			O.[type]	= 'FN'				AND
			O.[name]	= 'Subscriber.IsValid'))
	DROP FUNCTION [Notification].[Subscriber.IsValid];
GO

CREATE FUNCTION [Notification].[Subscriber.IsValid]
(
	@publisherId	UNIQUEIDENTIFIER,
	@personId		UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (NOT EXISTS (
			SELECT * FROM [Notification].[Publisher]	PB
			INNER JOIN	[Owner].[Organisation]			O	ON	PB.[PublisherOrganisationId]	= O.[OrganisationId]
			INNER JOIN	[Owner].[Person]				P	ON	O.[OrganisationEmplacementId]	= P.[PersonEmplacementId]
			WHERE
				PB.[PublisherId]	= @publisherId	AND
				P.[PersonId]		= @personId
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Notification].[Subscriber] WITH CHECK ADD CONSTRAINT [CK_Subscriber_PublisherId_PersonId] CHECK ((
	[Notification].[Subscriber.IsValid]
	(
		[SubscriberPublisherId],
		[SubscriberPersonId]
	)=(1)
))
GO

ALTER TABLE [Notification].[Subscriber] CHECK CONSTRAINT [CK_Subscriber_PublisherId_PersonId]
GO
