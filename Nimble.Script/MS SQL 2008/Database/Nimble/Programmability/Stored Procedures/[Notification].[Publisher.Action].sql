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
			O.[name]	= 'Publisher.Action'))
	DROP PROCEDURE [Notification].[Publisher.Action];
GO

CREATE PROCEDURE [Notification].[Publisher.Action]
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

	IF (@permissionType = 'PublisherCreate') BEGIN
		INSERT [Notification].[Publisher] 
		(
			[PublisherOrganisationId],
			[PublisherNotificationType],
			[PublisherCreatedOn],
			[PublisherLockedOn],
			[PublisherSettings]
		)
		OUTPUT INSERTED.[PublisherId] INTO @output ([Id])
		SELECT
			X.[OrganisationId],
			X.[NotificationType],
			X.[CreatedOn],
			X.[LockedOn],
			X.[Settings]
		FROM [Notification].[Publisher.Entity](@entity) X;
		SELECT P.* FROM [Notification].[Entity.Publisher]		P
		INNER JOIN	@output										X	ON	P.[PublisherId]			= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'PublisherRead') BEGIN
		SELECT P.* FROM [Notification].[Entity.Publisher]		P
		INNER JOIN	[Notification].[Publisher.Entity](@entity)	X	ON	P.[PublisherId]			= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'PublisherUpdate') BEGIN
		UPDATE P SET 
			P.[PublisherNotificationType]	= X.[NotificationType],
			P.[PublisherLockedOn]			= X.[LockedOn],
			P.[PublisherSettings]			= X.[Settings]
		OUTPUT INSERTED.[PublisherId] INTO @output ([Id])
		FROM [Notification].[Publisher]							P
		INNER JOIN	[Notification].[Publisher.Entity](@entity)	X	ON	P.[PublisherId]			= X.[Id]	AND
																		P.[PublisherVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT P.* FROM [Notification].[Entity.Publisher]		P
		INNER JOIN	@output										X	ON	P.[PublisherId]			= X.[Id];
	END

	IF (@permissionType = 'PublisherDelete') BEGIN
		DELETE	P	FROM [Notification].[Publisher]				P
		INNER JOIN	[Notification].[Publisher.Entity](@entity)	X	ON	P.[PublisherId]			= X.[Id]	AND
																		P.[PublisherVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
	END
	
	IF (@permissionType = 'PublisherSearch') BEGIN
		CREATE TABLE [#publisher] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Notification].[Publisher.Filter]
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
		INSERT [#publisher] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [PublisherOrganisationId] ASC ');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT P.* FROM [Notification].[Entity.Publisher]			P
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT P.* FROM [#publisher]							X
					INNER JOIN	[Notification].[Entity.Publisher]			P	ON	X.[Id]				= P.[PublisherId]
					';
				ELSE
					IF (@organisations IS NULL)
						SET @command = '
						SELECT P.* FROM [Notification].[Entity.Publisher]	P	
						LEFT JOIN	[#publisher]							X	ON	P.[PublisherId]		= X.[Id]
						WHERE 
							' + ISNULL('P.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
							X.[Id] IS NULL
						';
					ELSE
						SET @command = '
						SELECT P.* FROM [Notification].[Entity.Publisher]	P	
						INNER JOIN	[#organisations]						XO	ON	P.[OrganisationId]	= XO.[Id]
						LEFT JOIN	[#publisher]							X	ON	P.[PublisherId]		= X.[Id]
						WHERE 
							' + ISNULL('P.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
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
						P.*, 
						ROW_NUMBER() OVER(' + @order + ') [Number]
					FROM [Notification].[Entity.Publisher]					P
				)	P
				WHERE P.[Number] BETWEEN
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							P.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [#publisher]									X
						INNER JOIN	[Notification].[Entity.Publisher]		P	ON	X.[Id]				= P.[PublisherId]
					)	P
					WHERE P.[Number] BETWEEN
					';
				ELSE
					IF (@organisations IS NULL)
						SET @command = '
						SELECT * FROM
						(
							SELECT 
								P.*, 
								ROW_NUMBER() OVER(' + @order + ') [Number]
							FROM [Notification].[Entity.Publisher]			P	
							LEFT JOIN	[#publisher]						X	ON	P.[PublisherId]		= X.[Id]
							WHERE 
								' + ISNULL('P.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
								X.[Id] IS NULL
						)	P
						WHERE P.[Number] BETWEEN
						';
					ELSE
						SET @command = '
						SELECT * FROM
						(
							SELECT 
								P.*, 
								ROW_NUMBER() OVER(' + @order + ') [Number]
							FROM [Notification].[Entity.Publisher]			P	
							INNER JOIN	[#organisations]					XO	ON	P.[OrganisationId]	= XO.[Id]
							LEFT JOIN	[#publisher]						X	ON	P.[PublisherId]		= X.[Id]
							WHERE 
								' + ISNULL('P.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
								X.[Id] IS NULL
						)	P
						WHERE P.[Number] BETWEEN
						';
			SET @command = @command + CAST(@startNumber AS NVARCHAR(MAX)) + ' AND ' + CAST(@endNumber AS NVARCHAR(MAX));
		END
		EXEC sp_executesql @command;
	END

END
GO
