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
			O.[name]	= 'Role.Action'))
	DROP PROCEDURE [Security].[Role.Action];
GO

CREATE PROCEDURE [Security].[Role.Action]
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

	SELECT * INTO [#input] FROM [Security].[Role.Entity](@entity) X;
	
	DECLARE
		@exist			BIT	= @entity.exist('/*/Permissions'),
		@permissions	XML	= @entity.query('/*/Permissions/Permission');
	
	IF (@permissionType = 'RoleCreate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			INSERT [Security].[Role] 
			(
				[RoleEmplacementId],
				[RoleApplicationId],
				[RoleCode],
				[RoleDescription]
			)
			OUTPUT INSERTED.[RoleId] INTO @output ([Id])
			SELECT
				X.[EmplacementId],
				X.[ApplicationId],
				X.[Code],
				X.[Description]
			FROM [#input] X;
			IF (@exist = 1)
				INSERT [Security].[RolePermission]
				SELECT DISTINCT
					X.[Id]	[RoleId],
					E.[Id]	[PermissionId]
				FROM @output X, 
				[Common].[Generic.Entities](@permissions) I
				CROSS APPLY [Security].[Permission.Entity](I.[Entity]) E;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT R.* FROM [Security].[Entity.Role]	R
		INNER JOIN	@output							X	ON	R.[RoleId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'RoleRead') BEGIN
		SELECT R.* FROM [Security].[Entity.Role]	R
		INNER JOIN	[#input]						X	ON	R.[RoleId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'RoleUpdate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			UPDATE R SET 
				R.[RoleCode]		= X.[Code],
				R.[RoleDescription]	= X.[Description]
			OUTPUT INSERTED.[RoleId] INTO @output ([Id])
			FROM [Security].[Role]	R
			INNER JOIN	[#input]	X	ON	R.[RoleId]		= X.[Id]	AND
											R.[RoleVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			IF (@exist = 1) BEGIN
				DELETE	RP	FROM [Security].[RolePermission]	RP
				INNER JOIN	@output								X	ON	RP.[RolePermissionRoleId]	= X.[Id];
				INSERT [Security].[RolePermission]
				SELECT DISTINCT
					X.[Id]	[RoleId],
					E.[Id]	[PermissionId]
				FROM @output X, 
				[Common].[Generic.Entities](@permissions) I
				CROSS APPLY [Security].[Permission.Entity](I.[Entity]) E;
			END
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT R.* FROM [Security].[Entity.Role]	R
		INNER JOIN	@output							X	ON	R.[RoleId]	= X.[Id];
	END

	IF (@permissionType = 'RoleDelete') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			DELETE	RP	FROM [Security].[RolePermission]	RP
			INNER JOIN	[#input]							X	ON	RP.[RolePermissionRoleId]	= X.[Id];
			DELETE	R	FROM [Security].[Role]	R
			INNER JOIN	[#input]				X	ON	R.[RoleId]		= X.[Id]	AND
														R.[RoleVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END
	
	IF (@permissionType = 'RoleSearch') BEGIN
		CREATE TABLE [#role] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Security].[Role.Filter]
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
		INSERT [#role] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [RoleEmplacementId] ASC, [RoleApplicationId] ASC, [RoleCode] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT R.* FROM [Security].[Entity.Role]		R
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT R.* FROM [#role]						X
				INNER JOIN	[Security].[Entity.Role]		R	ON	X.[Id]		= R.[RoleId]
				';
			ELSE
				SET @command = '
				SELECT R.* FROM [Security].[Entity.Role]	R
				LEFT JOIN	[#role]							X	ON	R.[RoleId]	= X.[Id]
				WHERE 
					' + ISNULL('R.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
					' + ISNULL('R.[ApplicationId] = ''' + CAST(@applicationId AS NVARCHAR(MAX)) + ''' AND', '') + '
					X.[Id] IS NULL
				';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
