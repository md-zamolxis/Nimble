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
			O.[name]	= 'Account.Action'))
	DROP PROCEDURE [Security].[Account.Action];
GO

CREATE PROCEDURE [Security].[Account.Action]
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

	SELECT * INTO [#input] FROM [Security].[Account.Entity](@entity) X;
	
	DECLARE
		@exist	BIT	= @entity.exist('/*/Roles'),
		@roles	XML	= @entity.query('/*/Roles/Role');
	
	IF (@permissionType = 'AccountCreate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			INSERT [Security].[Account] 
			(
				[AccountUserId],
				[AccountApplicationId],
				[AccountLockedOn],
				[AccountLastUsedOn],
				[AccountSessions]
			)
			OUTPUT INSERTED.[AccountId] INTO @output ([Id])
			SELECT
				X.[UserId],
				X.[ApplicationId],
				X.[LockedOn],
				X.[LastUsedOn],
				X.[Sessions]
			FROM [#input] X;
			IF (@exist = 1)
				INSERT [Security].[AccountRole]
				SELECT DISTINCT
					X.[Id]	[AccountId],
					E.[Id]	[RoleId]
				FROM @output X, 
				[Common].[Generic.Entities](@roles) I
				CROSS APPLY [Security].[Role.Entity](I.[Entity]) E;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT A.* FROM [Security].[Entity.Account]	A
		INNER JOIN	@output							X	ON	A.[AccountId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'AccountRead') BEGIN
		SELECT A.* FROM [Security].[Entity.Account]	A
		INNER JOIN	[#input]						X	ON	A.[AccountId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'AccountUpdate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			UPDATE A SET 
				A.[AccountLockedOn]		= X.[LockedOn],
				A.[AccountLastUsedOn]	= X.[LastUsedOn],
				A.[AccountSessions]		= X.[Sessions]
			OUTPUT INSERTED.[AccountId] INTO @output ([Id])
			FROM [Security].[Account]	A
			INNER JOIN	[#input]		X	ON	A.[AccountId]		= X.[Id]	AND
												A.[AccountVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			IF (@exist = 1) BEGIN
				DELETE	AR	FROM [Security].[AccountRole]	AR
				INNER JOIN	@output							X	ON	AR.[AccountRoleAccountId]	= X.[Id];
				INSERT [Security].[AccountRole]
				SELECT DISTINCT
					X.[Id]	[AccountId],
					E.[Id]	[RoleId]
				FROM @output X, 
				[Common].[Generic.Entities](@roles) I
				CROSS APPLY [Security].[Role.Entity](I.[Entity]) E;
			END
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT A.* FROM [Security].[Entity.Account]	A
		INNER JOIN	@output							X	ON	A.[AccountId]	= X.[Id];
	END

	IF (@permissionType = 'AccountDelete') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			DELETE	AR	FROM [Security].[AccountRole]	AR
			INNER JOIN	[#input]						X	ON	AR.[AccountRoleAccountId]	= X.[Id];
			DELETE	A	FROM [Security].[Account]	A
			INNER JOIN	[#input]					X	ON	A.[AccountId]		= X.[Id]	AND
															A.[AccountVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END
	
	IF (@permissionType = 'AccountSearch') BEGIN
		CREATE TABLE [#account] 
		(
			[UserId]		UNIQUEIDENTIFIER,
			[ApplicationId]	UNIQUEIDENTIFIER,
			PRIMARY KEY CLUSTERED 
			(
				[UserId],
				[ApplicationId]
			)
		);
		EXEC sp_executesql 
			N'EXEC [Security].[Account.Filter]
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
		SET @order = ISNULL(@order, ' ORDER BY [AccountUserId] ASC, [AccountApplicationId] ASC ');
		INSERT [#account]
		SELECT 
			LTRIM(X.[Entity].value('(UserId/text())[1]',		'UNIQUEIDENTIFIER')) [UserId],
			LTRIM(X.[Entity].value('(ApplicationId/text())[1]',	'UNIQUEIDENTIFIER')) [ApplicationId]
		FROM @guids.nodes('/*/guid') X ([Entity]);
		IF (@isFiltered = 0)
			SET @command = '
			SELECT A.* FROM [Security].[Entity.Account]		A
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT A.* FROM [#account]					X
				INNER JOIN	[Security].[Entity.Account]		A	ON	X.[UserId]			= A.[UserId]	AND
																	X.[ApplicationId]	= A.[ApplicationId]
				';
			ELSE
				SET @command = '
				SELECT A.* FROM [Security].[Entity.Account]	A
				LEFT JOIN	[#account]						X	ON	A.[UserId]			= X.[UserId]	AND
																	A.[ApplicationId]	= X.[ApplicationId]
				WHERE															
					' + ISNULL('A.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
					' + ISNULL('A.[ApplicationId] = ''' + CAST(@applicationId AS NVARCHAR(MAX)) + ''' AND', '') + '
					COALESCE(X.[UserId], X.[ApplicationId]) IS NULL
				';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
