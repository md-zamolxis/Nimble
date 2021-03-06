SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Notification'	AND
			O.[type]	= 'P'				AND
			O.[name]	= 'Subscriber.Action'))
	DROP PROCEDURE [Notification].[Subscriber.Action];
GO

CREATE PROCEDURE [Notification].[Subscriber.Action]
(
	@genericInput	XML,
	@number			INT	OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE 
		@permissionType	NVARCHAR(MAX),
		@entity			XML,
		@predicate		XML,
		@index			INT,
		@size			INT,
		@startNumber	INT,
		@endNumber		INT,
		@order			NVARCHAR(MAX),
		@groupTop		NVARCHAR(MAX),
		@groupBottom	NVARCHAR(MAX),
		@group			NVARCHAR(MAX),
		@emplacementId	UNIQUEIDENTIFIER,
		@applicationId	UNIQUEIDENTIFIER,
		@personId		UNIQUEIDENTIFIER,
		@organisations	XML,
		@isCountable	BIT,
		@guids			XML,
		@isExcluded		BIT,
		@isFiltered		BIT,
		@command		NVARCHAR(MAX);
	
	DECLARE @output TABLE ([Id] UNIQUEIDENTIFIER);
	
	EXEC [Common].[GenericInput.Action] 
		@genericInput	= @genericInput,
		@permissionType = @permissionType	OUTPUT,
		@entity			= @entity			OUTPUT,
		@predicate		= @predicate		OUTPUT,
		@index			= @index			OUTPUT,
		@size			= @size				OUTPUT,
		@startNumber	= @startNumber		OUTPUT,
		@endNumber		= @endNumber		OUTPUT,
		@order			= @order			OUTPUT,
		@groupTop		= @groupTop			OUTPUT,
		@groupBottom	= @groupBottom		OUTPUT,
		@emplacementId	= @emplacementId	OUTPUT,
		@applicationId	= @applicationId	OUTPUT,
		@personId		= @personId			OUTPUT,
		@organisations	= @organisations	OUTPUT;

	IF (@permissionType = 'SubscriberCreate') BEGIN
		INSERT [Notification].[Subscriber] 
		(
			[SubscriberPublisherId],
			[SubscriberPersonId],
			[SubscriberNotificationType],
			[SubscriberCreatedOn],
			[SubscriberLockedOn],
			[SubscriberSettings]
		)
		OUTPUT INSERTED.[SubscriberId] INTO @output ([Id])
		SELECT
			X.[PublisherId],
			X.[PersonId],
			X.[NotificationType],
			X.[CreatedOn],
			X.[LockedOn],
			X.[Settings]
		FROM [Notification].[Subscriber.Entity](@entity) X;
		SELECT S.* FROM [Notification].[Entity.Subscriber]		S
		INNER JOIN	@output										X	ON	S.[SubscriberId]		= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'SubscriberRead') BEGIN
		SELECT S.* FROM [Notification].[Entity.Subscriber]		S
		INNER JOIN	[Notification].[Subscriber.Entity](@entity)	X	ON	S.[SubscriberId]		= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'SubscriberUpdate') BEGIN
		UPDATE S SET 
			S.[SubscriberNotificationType]	= X.[NotificationType],
			S.[SubscriberLockedOn]			= X.[LockedOn],
			S.[SubscriberSettings]			= X.[Settings]
		OUTPUT INSERTED.[SubscriberId] INTO @output ([Id])
		FROM [Notification].[Subscriber]						S
		INNER JOIN	[Notification].[Subscriber.Entity](@entity)	X	ON	S.[SubscriberId]		= X.[Id]	AND
																		S.[SubscriberVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT S.* FROM [Notification].[Entity.Subscriber]		S
		INNER JOIN	@output										X	ON	S.[SubscriberId]		= X.[Id];
	END

	IF (@permissionType = 'SubscriberDelete') BEGIN
		DELETE	S	FROM [Notification].[Subscriber]				S
		INNER JOIN	[Notification].[Subscriber.Entity](@entity)	X	ON	S.[SubscriberId]	= X.[Id];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
	END
	
	IF (@permissionType = 'SubscriberSearch') BEGIN
		CREATE TABLE [#subscriber] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Notification].[Subscriber.Filter]
			@predicate,
			@emplacementId,
			@applicationId,
			@personId,
			@organisations,
			@isCountable,
			@guids		OUTPUT,
			@isExcluded OUTPUT,
			@isFiltered OUTPUT,
			@number		OUTPUT',
			N'@predicate	XML,
			@emplacementId	UNIQUEIDENTIFIER,
			@applicationId	UNIQUEIDENTIFIER,
			@personId		UNIQUEIDENTIFIER,
			@organisations	XML,
			@isCountable	BIT,
			@guids			XML OUTPUT,
			@isExcluded		BIT OUTPUT,
			@isFiltered		BIT OUTPUT,
			@number			INT OUTPUT',
			@predicate		= @predicate,
			@emplacementId	= @emplacementId,
			@applicationId	= @applicationId,
			@personId		= @personId,
			@organisations	= @organisations,
			@isCountable	= @isCountable,
			@guids			= @guids		OUTPUT,
			@isExcluded		= @isExcluded	OUTPUT,
			@isFiltered		= @isFiltered	OUTPUT,
			@number			= @number		OUTPUT;
		INSERT [#subscriber] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [SubscriberPublisherId] ASC, [SubscriberPersonId] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT S.* FROM [Notification].[Entity.Subscriber]			S
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT S.* FROM [#subscriber]							X
				INNER JOIN	[Notification].[Entity.Subscriber]			S	ON	X.[Id]				= S.[SubscriberId]
				';
			ELSE
				IF (@organisations IS NULL)
					SET @command = '
					SELECT S.* FROM [Notification].[Entity.Subscriber]	S	
					LEFT JOIN	[#subscriber]							X	ON	S.[SubscriberId]	= X.[Id]
					WHERE 
						' + ISNULL('S.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						X.[Id] IS NULL
					';
				ELSE
					SET @command = '
					SELECT S.* FROM [Notification].[Entity.Subscriber]	S	
					LEFT JOIN	[#organisations]						XO	ON	S.[OrganisationId]	= XO.[Id]
					LEFT JOIN	[#subscriber]							X	ON	S.[SubscriberId]	= X.[Id]
					WHERE 
						(XO.[Id] IS NOT NULL OR S.[SubscriberPersonId] = ''' + CAST(@personId AS NVARCHAR(MAX)) + ''') AND
						' + ISNULL('S.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						X.[Id] IS NULL
					';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
