SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'P'			AND
			O.[name]	= 'Preset.Action'))
	DROP PROCEDURE [Common].[Preset.Action];
GO

CREATE PROCEDURE [Common].[Preset.Action]
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

	SELECT * INTO [#input] FROM [Common].[Preset.Entity](@entity) X;
	
	IF (@permissionType = 'PresetCreate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			IF (EXISTS(SELECT * FROM [#input] X WHERE X.[IsDefault] = 1))
				UPDATE P SET P.[PresetIsDefault] = 0
				FROM [Common].[Preset]	P
				INNER JOIN	[#input]	X	ON	P.[PresetAccountId]		= X.[AccountId]	AND
												P.[PresetEntityType]	= X.[PresetEntityType]	AND
												P.[PresetIsDefault]		= 1;
			INSERT [Common].[Preset] 
			(
				[PresetAccountId],
				[PresetEntityType],
				[PresetCode],
				[PresetCategory],
				[PresetDescription],
				[PresetPredicate],
				[PresetIsDefault],
				[PresetIsInstantly]
			)
			OUTPUT INSERTED.[PresetId] INTO @output ([Id])
			SELECT
				X.[AccountId],
				X.[PresetEntityType],
				X.[Code],
				X.[Category],
				X.[Description],
				X.[Predicate],
				X.[IsDefault],
				X.[IsInstantly]
			FROM [#input] X;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT P.* FROM [Common].[Entity.Preset]		P
		INNER JOIN	@output								X	ON	P.[PresetId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'PresetRead') BEGIN
		SELECT P.* FROM [Common].[Entity.Preset]		P
		INNER JOIN	[#input]							X	ON	P.[PresetId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'PresetUpdate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			IF (EXISTS(SELECT * FROM [#input] X WHERE X.[IsDefault] = 1))
				UPDATE P SET P.[PresetIsDefault] = 0
				FROM [Common].[Preset]	P
				INNER JOIN	[#input]	X	ON	P.[PresetAccountId]		= X.[AccountId]	AND
												P.[PresetEntityType]	= X.[PresetEntityType]	AND
												P.[PresetIsDefault]		= 1;
			UPDATE P SET 
				P.[PresetAccountId]		= X.[AccountId],
				P.[PresetEntityType]	= X.[PresetEntityType],
				P.[PresetCode]			= X.[Code],
				P.[PresetCategory]		= X.[Category],
				P.[PresetDescription]	= X.[Description],
				P.[PresetPredicate]		= X.[Predicate],
				P.[PresetIsDefault]		= X.[IsDefault],
				P.[PresetIsInstantly]	= X.[IsInstantly]
			OUTPUT INSERTED.[PresetId] INTO @output ([Id])
			FROM [Common].[Preset]		P
			INNER JOIN	[#input]			X	ON	P.[PresetId]	= X.[Id];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT P.* FROM [Common].[Entity.Preset]		P
		INNER JOIN	@output								X	ON	P.[PresetId]	= X.[Id];
	END

	IF (@permissionType = 'PresetDelete') BEGIN
		DELETE P FROM [Common].[Preset]					P
		INNER JOIN	[#input]							X	ON	P.[PresetId]	= X.[Id];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
	END
	
	IF (@permissionType = 'PresetSearch') BEGIN
		CREATE TABLE [#preset] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Common].[Preset.Filter]
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
		INSERT [#preset] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [PresetAccountId] ASC, [PresetCode] ASC ');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT P.* FROM [Common].[Entity.Preset]		P
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT P.* FROM [#preset]					X
					INNER JOIN	[Common].[Entity.Preset]		P	ON	X.[Id]		= P.[PresetId]
					';
				ELSE
					SET @command = '
					SELECT P.* FROM [Common].[Entity.Preset]	P
					LEFT JOIN	[#preset]						X	ON	P.[PresetId]	= X.[Id]
					WHERE 
						' + ISNULL('P.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
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
					FROM [Common].[Entity.Preset]				P
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
						FROM [#preset]							X
						INNER JOIN	[Common].[Entity.Preset]	P	ON	X.[Id]		= P.[PresetId]
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
						FROM [Common].[Entity.Preset]			P
						LEFT JOIN	[#preset]					X	ON	P.[PresetId]	= X.[Id]
						WHERE 
							' + ISNULL('P.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
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
