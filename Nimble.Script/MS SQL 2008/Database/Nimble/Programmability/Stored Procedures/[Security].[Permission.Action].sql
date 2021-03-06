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
			O.[name]	= 'Permission.Action'))
	DROP PROCEDURE [Security].[Permission.Action];
GO

CREATE PROCEDURE [Security].[Permission.Action]
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

	SELECT * INTO [#input] FROM [Security].[Permission.Entity](@entity) X;
	
	IF (@permissionType = 'PermissionCreate') BEGIN
		INSERT [Security].[Permission] 
		(
			[PermissionApplicationId],
			[PermissionCode],
			[PermissionCategory],
			[PermissionDescription]
		)
		OUTPUT INSERTED.[PermissionId] INTO @output ([Id])
		SELECT
			X.[ApplicationId],
			X.[Code],
			X.[Category],
			X.[Description]
		FROM [#input] X;
		SELECT P.* FROM [Security].[Entity.Permission]	P
		INNER JOIN	@output								X	ON	P.[PermissionId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'PermissionRead') BEGIN
		SELECT P.* FROM [Security].[Entity.Permission]	P
		INNER JOIN	[#input]							X	ON	P.[PermissionId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'PermissionUpdate') BEGIN
		UPDATE P SET 
			P.[PermissionCode]			= X.[Code],
			P.[PermissionCategory]		= X.[Category],
			P.[PermissionDescription]	= X.[Description]
		OUTPUT INSERTED.[PermissionId] INTO @output ([Id])
		FROM [Security].[Permission]	P
		INNER JOIN	[#input]			X	ON	P.[PermissionId]		= X.[Id]	AND
												P.[PermissionVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT P.* FROM [Security].[Entity.Permission]	P
		INNER JOIN	@output								X	ON	P.[PermissionId]	= X.[Id];
	END

	IF (@permissionType = 'PermissionDelete') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			DELETE	RP	FROM [Security].[RolePermission]	RP
			INNER JOIN	[#input]							X	ON	RP.[RolePermissionPermissionId]	= X.[Id];
			DELETE P FROM [Security].[Permission]	P
			INNER JOIN	[#input]					X	ON	P.[PermissionId]		= X.[Id]	AND
															P.[PermissionVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END
	
	IF (@permissionType = 'PermissionSearch') BEGIN
		CREATE TABLE [#permission] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Security].[Permission.Filter]
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
		INSERT [#permission] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [PermissionApplicationId] ASC, [PermissionCode] ASC ');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT P.* FROM [Security].[Entity.Permission]		P
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT P.* FROM [#permission]					X
					INNER JOIN	[Security].[Entity.Permission]		P	ON	X.[Id]				= P.[PermissionId]
					';
				ELSE
					SET @command = '
					SELECT P.* FROM [Security].[Entity.Permission]	P
					LEFT JOIN	[#permission]						X	ON	P.[PermissionId]	= X.[Id]
					WHERE 
						' + ISNULL('P.[ApplicationId] = ''' + CAST(@applicationId AS NVARCHAR(MAX)) + ''' AND', '') + '
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
					FROM [Security].[Entity.Permission]				P
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
						FROM [#permission]							X
						INNER JOIN	[Security].[Entity.Permission]	P	ON	X.[Id]				= P.[PermissionId]
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
						FROM [Security].[Entity.Permission]			P
						LEFT JOIN	[#permission]					X	ON	P.[PermissionId]	= X.[Id]
						WHERE 
							' + ISNULL('P.[ApplicationId] = ''' + CAST(@applicationId AS NVARCHAR(MAX)) + ''' AND', '') + '
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
