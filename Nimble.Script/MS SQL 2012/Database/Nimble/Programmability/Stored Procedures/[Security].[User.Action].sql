SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Security'	AND
			O.[type]	= 'P'			AND
			O.[name]	= 'User.Action'))
	DROP PROCEDURE [Security].[User.Action];
GO

CREATE PROCEDURE [Security].[User.Action]
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
		@emplacementId	UNIQUEIDENTIFIER,
		@applicationId	UNIQUEIDENTIFIER,
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
		@emplacementId	= @emplacementId	OUTPUT,
		@applicationId	= @applicationId	OUTPUT,
		@organisations	= @organisations	OUTPUT;
	
	IF (@permissionType = 'UserCreate') BEGIN
		INSERT [Security].[User] 
		(
			[UserEmplacementId],
			[UserCode],
			[UserPassword],
			[UserCreatedOn],
			[UserLockedOn],
			[UserFacebookId],
			[UserGmailId]
		)
		OUTPUT INSERTED.[UserId] INTO @output ([Id])
		SELECT
			X.[EmplacementId],
			X.[Code],
			X.[Password],
			X.[CreatedOn],
			X.[LockedOn],
			X.[FacebookId],
			X.[GmailId]
		FROM [Security].[User.Entity](@entity) X;
		SELECT U.* FROM [Security].[Entity.User]	U
		INNER JOIN	@output							X	ON	U.[UserId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'UserRead') BEGIN
		SELECT U.* FROM [Security].[Entity.User]		U
		INNER JOIN	[Security].[User.Entity](@entity)	X	ON	U.[UserId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'UserUpdate') BEGIN
		UPDATE U SET 
			U.[UserCode]		= X.[Code],
			U.[UserLockedOn]	= X.[LockedOn],
			U.[UserPassword]	= X.[Password],
			U.[UserFacebookId]	= X.[FacebookId],
			U.[UserGmailId]		= X.[GmailId]
		OUTPUT INSERTED.[UserId] INTO @output ([Id])
		FROM [Security].[User]							U
		INNER JOIN	[Security].[User.Entity](@entity)	X	ON	U.[UserId]		= X.[Id]	AND
																U.[UserVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT U.* FROM [Security].[Entity.User]	U
		INNER JOIN	@output							X	ON	U.[UserId]	= X.[Id];
	END

	IF (@permissionType = 'UserDelete') BEGIN
		DELETE U FROM [Security].[User]					U
		INNER JOIN	[Security].[User.Entity](@entity)	X	ON	U.[UserId]		= X.[Id]	AND
																U.[UserVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
	END
	
	IF (@permissionType = 'UserSearch') BEGIN
		CREATE TABLE [#user] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Security].[User.Filter]
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
		INSERT [#user] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [UserEmplacementId] ASC, [UserCode] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT U.* FROM [Security].[Entity.User]		U
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT U.* FROM [#user]						X
				INNER JOIN	[Security].[Entity.User]		U	ON	X.[Id]		= U.[UserId]
				';
			ELSE
				SET @command = '
				SELECT U.* FROM [Security].[Entity.User]	U
				LEFT JOIN	[#user]							X	ON	U.[UserId]	= X.[Id]
				WHERE 
					' + ISNULL('U.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
					X.[Id] IS NULL
				';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
