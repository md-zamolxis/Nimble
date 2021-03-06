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
			O.[name]	= 'Message.Action'))
	DROP PROCEDURE [Notification].[Message.Action];
GO

CREATE PROCEDURE [Notification].[Message.Action]
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
		@startNumber	INT,
		@endNumber		INT,
		@order			NVARCHAR(MAX),
		@emplacementId	UNIQUEIDENTIFIER,
		@applicationId	UNIQUEIDENTIFIER,
		@organisations	XML,
		@isCountable	BIT,
		@guids			XML,
		@isExcluded		BIT,
		@isFiltered		BIT,
		@command		NVARCHAR(MAX);
	
	DECLARE @output TABLE ([Id] UNIQUEIDENTIFIER);
	
	CREATE TABLE [#organisations] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	EXEC [Common].[GenericInput.Action] 
		@genericInput	= @genericInput,
		@permissionType = @permissionType	OUTPUT,
		@entity			= @entity			OUTPUT,
		@predicate		= @predicate		OUTPUT,
		@startNumber	= @startNumber		OUTPUT,
		@endNumber		= @endNumber		OUTPUT,
		@order			= @order			OUTPUT,
		@emplacementId	= @emplacementId	OUTPUT,
		@applicationId	= @applicationId	OUTPUT,
		@organisations	= @organisations	OUTPUT;
	INSERT [#organisations] SELECT * FROM [Common].[Guid.Entities](@organisations);

	SELECT * INTO [#input] FROM [Notification].[Message.Entity](@entity) X;
	
	IF (@permissionType = 'MessageCreate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY;
			WITH XC AS
			(
				SELECT ISNULL(MAX(CAST(M.[MessageCode] AS INT)), 0) + 1	[Code]
				FROM [#input]							X
				INNER JOIN	[Notification].[Message]	M	ON	X.[PublisherId]	= M.[MessagePublisherId]
				WHERE [Common].[Code.IsNumeric](M.[MessageCode]) = 1
			)
			INSERT [Notification].[Message]
			(
				[MessagePublisherId],
				[MessageCode],
				[MessageNotificationType],
				[MessageActionType],
				[MessageCreatedOn],
				[MessageTitle],
				[MessageBody],
				[MessageSound],
				[MessageIcon],
				[MessageEntityType],
				[MessageEntityId],
				[MessageSettings]
			)
			OUTPUT INSERTED.[MessageId] INTO @output ([Id])
			SELECT
				X.[PublisherId],
				ISNULL(X.[Code], XC.[Code]),
				X.[NotificationType],
				X.[MessageActionType],
				X.[CreatedOn],
				X.[Title],
				X.[Body],
				X.[Sound],
				X.[Icon],
				X.[MessageEntityType],
				X.[EntityId],
				X.[Settings]
			FROM [#input] X OUTER APPLY XC;
			INSERT [Notification].[Trace]
			(
				[TraceMessageId],
				[TraceSubscriberId],
				[TraceCreatedOn]
			)
			SELECT
				M.[MessageId],
				S.[SubscriberId],
				M.[MessageCreatedOn]
			FROM @output							X
			INNER JOIN	[Notification].[Message]	M	ON	X.[Id]					= M.[MessageId]
			INNER JOIN	[Notification].[Publisher]	P	ON	M.[MessagePublisherId]	= P.[PublisherId]
			INNER JOIN	[Notification].[Subscriber]	S	ON	P.[PublisherId]			= S.[SubscriberPublisherId]
			WHERE
				M.[MessageCreatedOn] <= ISNULL(P.[PublisherLockedOn], M.[MessageCreatedOn])		AND
				M.[MessageCreatedOn] <= ISNULL(S.[SubscriberLockedOn], M.[MessageCreatedOn])	AND
				[Common].[Flags.LineIsEqual](M.[MessageNotificationType], S.[SubscriberNotificationType], 0) = 1;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT M.* FROM [Notification].[Entity.Message]	M
		INNER JOIN	@output								X	ON	M.[MessageId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'MessageRead') BEGIN
		SELECT M.* FROM [Notification].[Entity.Message]	M
		INNER JOIN	[#input]							X	ON	M.[MessageId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END

	IF (@permissionType = 'MessageSearch') BEGIN
		CREATE TABLE [#message] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Notification].[Message.Filter]
			@predicate,
			@emplacementId,
			@applicationId,
			@organisations,
			@isCountable,
			@guids		OUTPUT,
			@isExcluded OUTPUT,
			@isFiltered OUTPUT,
			@number		OUTPUT',
			N'@predicate	XML,
			@emplacementId	UNIQUEIDENTIFIER,
			@applicationId	UNIQUEIDENTIFIER,
			@organisations	XML,
			@isCountable	BIT,
			@guids			XML OUTPUT,
			@isExcluded		BIT OUTPUT,
			@isFiltered		BIT OUTPUT,
			@number			INT OUTPUT',
			@predicate		= @predicate,
			@emplacementId	= @emplacementId,
			@applicationId	= @applicationId,
			@organisations	= @organisations,
			@isCountable	= @isCountable,
			@guids			= @guids		OUTPUT,
			@isExcluded		= @isExcluded	OUTPUT,
			@isFiltered		= @isFiltered	OUTPUT,
			@number			= @number		OUTPUT;
		INSERT [#message] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [MessageSplitId] ASC, [MessageCode] ASC ');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT M.* FROM [Notification].[Entity.Message]			M
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT M.* FROM [#message]							X
					INNER JOIN	[Notification].[Entity.Message]			M	ON	X.[Id]				= M.[MessageId]
					';
				ELSE
					IF (@organisations IS NULL)
						SET @command = '
						SELECT M.* FROM [Notification].[Entity.Message]	M
						LEFT JOIN	[#message]							X	ON	M.[MessageId]		= X.[Id]
						WHERE 
							' + ISNULL('M.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
							X.[Id] IS NULL
						';
					ELSE
						SET @command = '
						SELECT M.* FROM [Notification].[Entity.Message]	M
						INNER JOIN	[#organisations]					XO	ON	M.[OrganisationId]	= XO.[Id]
						LEFT JOIN	[#message]							X	ON	M.[MessageId]		= X.[Id]
						WHERE 
							' + ISNULL('M.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
							X.[Id] IS NULL
						';
			SET @command = @command + @order;
		END
		ELSE BEGIN
			IF (@isFiltered = 0)
				SET @command = '
				SELECT * FROM
				(
					SELECT 
						M.*, 
						ROW_NUMBER() OVER(' + @order + ') [Number]
					FROM [Notification].[Entity.Message]				M
				)	M
				WHERE M.[Number] BETWEEN
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							M.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [#message]									X
						INNER JOIN	[Notification].[Entity.Message]		M	ON	X.[Id]				= M.[MessageId]
					)	M
					WHERE M.[Number] BETWEEN
					';
				ELSE
					IF (@organisations IS NULL)
						SET @command = '
						SELECT * FROM
						(
							SELECT 
								M.*, 
								ROW_NUMBER() OVER(' + @order + ') [Number]
							FROM [Notification].[Entity.Message]		M
							LEFT JOIN	[#message]						X	ON	M.[MessageId]		= X.[Id]
							WHERE 
								' + ISNULL('M.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
								X.[Id] IS NULL
						)	M
						WHERE M.[Number] BETWEEN
						';
					ELSE
						SET @command = '
						SELECT * FROM
						(
							SELECT 
								M.*, 
								ROW_NUMBER() OVER(' + @order + ') [Number]
							FROM [Notification].[Entity.Message]		M
							INNER JOIN	[#organisations]				XO	ON	M.[OrganisationId]	= XO.[Id]
							LEFT JOIN	[#message]						X	ON	M.[MessageId]		= X.[Id]
							WHERE 
								' + ISNULL('M.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
								X.[Id] IS NULL
						)	M
						WHERE M.[Number] BETWEEN
						';
			SET @command = @command + CAST(@startNumber AS NVARCHAR(MAX)) + ' AND ' + CAST(@endNumber AS NVARCHAR(MAX));
		END
		EXEC sp_executesql @command;
	END

END
GO
