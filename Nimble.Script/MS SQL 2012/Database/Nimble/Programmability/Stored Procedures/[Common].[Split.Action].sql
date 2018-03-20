SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'P'		AND
			O.[name]	= 'Split.Action'))
	DROP PROCEDURE [Common].[Split.Action];
GO

CREATE PROCEDURE [Common].[Split.Action]
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

	SELECT * INTO [#input] FROM [Common].[Split.Entity](@entity) X;
	
	IF (@permissionType = 'SplitCreate') BEGIN
		INSERT [Common].[Split]
		(
			[SplitEmplacementId],
			[SplitEntityType],
			[SplitEntityCode],
			[SplitName],
			[SplitNames],
			[SplitIsSystem],
			[SplitIsExclusive],
			[SplitSettings]
		)
		OUTPUT INSERTED.[SplitId] INTO @output ([Id])
		SELECT
			X.[EmplacementId],
			X.[SplitEntityType],
			X.[SplitEntityCode],
			X.[Name],
			X.[Names],
			X.[IsSystem],
			X.[IsExclusive],
			X.[Settings]
		FROM [#input] X;
		SELECT S.* FROM [Common].[Entity.Split]	S
		INNER JOIN	@output						X	ON	S.[SplitId]			= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'SplitRead') BEGIN
		SELECT S.* FROM [Common].[Entity.Split]	S
		INNER JOIN	[#input]					X	ON	S.[SplitId]			= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'SplitUpdate') BEGIN
		UPDATE S SET 
			S.[SplitName]		= X.[Name],
			S.[SplitNames]		= X.[Names],
			S.[SplitIsSystem]	= X.[IsSystem],
			S.[SplitSettings]	= X.[Settings]
		OUTPUT INSERTED.[SplitId] INTO @output ([Id])
		FROM [Common].[Split]					S
		INNER JOIN	[#input]					X	ON	S.[SplitId]			= X.[Id]	AND
														S.[SplitVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT S.* FROM [Common].[Entity.Split]	S
		INNER JOIN	@output						X	ON	S.[SplitId]			= X.[Id];
	END

	IF (@permissionType = 'SplitDelete') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			DELETE B FROM [Common].[Bond]		B
			INNER JOIN	[Common].[Group]		G	ON	B.[BondGroupId]		= G.[GroupId]
			INNER JOIN	[#input]				X	ON	G.[GroupSplitId]	= X.[Id];
			DELETE	G	FROM [Common].[Group]	G
			INNER JOIN	[#input]				X	ON	G.[GroupSplitId]	= X.[Id];
			DELETE S FROM [Common].[Split]		S
			INNER JOIN	[#input]				X	ON	S.[SplitId]			= X.[Id]	AND
														S.[SplitVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END
	IF (@permissionType = 'SplitSearch') BEGIN
		CREATE TABLE [#split] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Common].[Split.Filter]
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
		INSERT [#split] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [SplitEmplacementId] ASC, [SplitCode] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT S.* FROM [Common].[Entity.Split]		S
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT S.* FROM [#split]				X
				INNER JOIN	[Common].[Entity.Split]		S	ON	X.[Id]		= S.[SplitId]
				';
			ELSE
				SET @command = '
				SELECT S.* FROM [Common].[Entity.Split]	S
				LEFT JOIN	[#split]					X	ON	S.[SplitId]	= X.[Id]
				WHERE 
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
