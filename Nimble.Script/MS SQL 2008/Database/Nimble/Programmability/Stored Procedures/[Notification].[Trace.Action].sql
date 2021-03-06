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
			O.[name]	= 'Trace.Action'))
	DROP PROCEDURE [Notification].[Trace.Action];
GO

CREATE PROCEDURE [Notification].[Trace.Action]
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
	
	CREATE TABLE [#organisations] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	EXEC [Common].[GenericInput.Action] 
		@genericInput	= @genericInput,
		@permissionType = @permissionType	OUTPUT,
		@entity			= @entity			OUTPUT,
		@predicate		= @predicate		OUTPUT,
		@startNumber	= @startNumber		OUTPUT,
		@endNumber		= @endNumber		OUTPUT,
		@order			= @order			OUTPUT,
		@groupTop		= @groupTop			OUTPUT,
		@groupBottom	= @groupBottom		OUTPUT,
		@emplacementId	= @emplacementId	OUTPUT,
		@applicationId	= @applicationId	OUTPUT,
		@personId		= @personId			OUTPUT,
		@organisations	= @organisations	OUTPUT;
	INSERT [#organisations] SELECT * FROM [Common].[Guid.Entities](@organisations);

	IF (@permissionType = 'TraceCreate') BEGIN
		INSERT [Notification].[Trace] 
		(
			[TraceMessageId],
			[TraceSubscriberId],
			[TraceCreatedOn],
			[TraceSettings]
		)
		OUTPUT INSERTED.[TraceId] INTO @output ([Id])
		SELECT
			X.[MessageId],
			X.[SubscriberId],
			X.[CreatedOn],
			X.[Settings]
		FROM [Notification].[Trace.Entity](@entity) X;
		SELECT T.* FROM [Notification].[Entity.Trace]		T
		INNER JOIN	@output									X	ON	T.[TraceId]			= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'TraceRead') BEGIN
		SELECT T.* FROM [Notification].[Entity.Trace]		T
		INNER JOIN	[Notification].[Trace.Entity](@entity)	X	ON	T.[TraceId]			= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'TraceUpdate') BEGIN
		UPDATE T SET 
			T.[TraceReadOn] = X.[ReadOn]
		OUTPUT INSERTED.[TraceId] INTO @output ([Id])
		FROM [Notification].[Trace]							T
		INNER JOIN	[Notification].[Trace.Entity](@entity)	X	ON	T.[TraceId]			= X.[Id]	AND
																	T.[TraceVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT T.* FROM [Notification].[Entity.Trace]		T
		INNER JOIN	@output									X	ON	T.[TraceId]			= X.[Id];
	END
	
	IF (@permissionType = 'TraceSearch') BEGIN
		CREATE TABLE [#trace] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Notification].[Trace.Filter]
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
		INSERT [#trace] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [TraceMessageId] ASC, [TraceSubscriberId] ASC, [TraceCreatedOn] DESC');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT T.* FROM [Notification].[Entity.Trace]			T
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT T.* FROM [#trace]							X
					INNER JOIN	[Notification].[Entity.Trace]			T	ON	X.[Id]				= T.[TraceId]
					';
				ELSE
					IF (@organisations IS NULL)
						SET @command = '
						SELECT T.* FROM [Notification].[Entity.Trace]	T
						LEFT JOIN	[#trace]							X	ON	T.[TraceId]			= X.[Id]
						WHERE 
							' + ISNULL('T.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
							X.[Id] IS NULL
						';
					ELSE
						SET @command = '
						SELECT T. FROM [Notification].[Entity.Trace]	T
						LEFT JOIN	[#organisations]					XO	ON	T.[OrganisationId]	= XO.[Id]
						LEFT JOIN	[#trace]							X	ON	T.[TraceId]			= X.[Id]
						WHERE 
							(XO.[Id] IS NOT NULL OR T.[TracePersonId] = ''' + CAST(@personId AS NVARCHAR(MAX)) + ''') AND
							' + ISNULL('T.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
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
						*, 
						ROW_NUMBER() OVER(' + @order + ') [Number]
					FROM FROM [Notification].[Entity.Trace]				T
				)	T
				WHERE T.[Number] BETWEEN
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [#trace]									X
						INNER JOIN	[Notification].[Entity.Trace]		T	ON	X.[Id]				= T.[TraceId]
					)	T
					WHERE T.[Number] BETWEEN
					';
				ELSE
					IF (@organisations IS NULL)
						SET @command = '
						SELECT * FROM
						(
							SELECT 
								*, 
								ROW_NUMBER() OVER(' + @order + ') [Number]
							FROM [Notification].[Entity.Trace]			T
							LEFT JOIN	[#trace]						X	ON	T.[TraceId]			= X.[Id]
							WHERE 
								' + ISNULL('T.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
								X.[Id] IS NULL
						)	T
						WHERE T.[Number] BETWEEN
						';
					ELSE
						SET @command = '
						SELECT * FROM
						(
							SELECT 
								*, 
								ROW_NUMBER() OVER(' + @order + ') [Number]
							FROM [Notification].[Entity.Trace]			T
							LEFT JOIN	[#organisations]				XO	ON	T.[OrganisationId]	= XO.[Id]
							LEFT JOIN	[#trace]						X	ON	T.[TraceId]			= X.[Id]
							WHERE 
								(XO.[Id] IS NOT NULL OR T.[TracePersonId] = ''' + CAST(@personId AS NVARCHAR(MAX)) + ''') AND
								' + ISNULL('T.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
								X.[Id] IS NULL
						)	T
						WHERE T.[Number] BETWEEN
						';
			SET @command = @command + CAST(@startNumber AS NVARCHAR(MAX)) + ' AND ' + CAST(@endNumber AS NVARCHAR(MAX));
		END
		EXEC sp_executesql @command;
	END

END
GO
