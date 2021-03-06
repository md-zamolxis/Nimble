SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner'	AND
			O.[type]	= 'P'		AND
			O.[name]	= 'Layout.Action'))
	DROP PROCEDURE [Owner].[Layout.Action];
GO

CREATE PROCEDURE [Owner].[Layout.Action]
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

	SELECT * INTO [#input] FROM [Owner].[Layout.Entity](@entity) X;

	IF (@permissionType = 'LayoutCreate') BEGIN
		WITH XC AS
		(
			SELECT ISNULL(MAX(CAST(L.[LayoutCode] AS INT)), 0) + 1	[Code]
			FROM [#input]					X
			INNER JOIN	[Owner].[Layout]	L	ON	X.[OrganisationId]		= L.[LayoutOrganisationId]	AND
													X.[LayoutEntityType]	= L.[LayoutEntityType]
			WHERE [Common].[Code.IsNumeric](L.[LayoutCode]) = 1
		)
		INSERT [Owner].[Layout] 
		(
			[LayoutOrganisationId],
			[LayoutEntityType],
			[LayoutCode],
			[LayoutName],
			[LayoutDescription],
			[LayoutSettings]
		)
		OUTPUT INSERTED.[LayoutId] INTO @output ([Id])
		SELECT
			X.[OrganisationId],
			X.[LayoutEntityType],
			ISNULL(X.[Code], XC.[Code]),
			X.[Name],
			X.[Description],
			X.[Settings]
		FROM [#input] X OUTER APPLY XC;
		SELECT L.* FROM [Owner].[Entity.Layout]	L
		INNER JOIN	@output						X	ON	L.[LayoutId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'LayoutRead') BEGIN
		SELECT L.* FROM [Owner].[Entity.Layout]	L
		INNER JOIN	[#input]					X	ON	L.[LayoutId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'LayoutUpdate') BEGIN
		UPDATE L SET 
			L.[LayoutCode]			= X.[Code],
			L.[LayoutName]			= X.[Name],
			L.[LayoutDescription]	= X.[Description],
			L.[LayoutSettings]		= X.[Settings]
		OUTPUT INSERTED.[LayoutId] INTO @output ([Id])
		FROM [Owner].[Layout]	L
		INNER JOIN	[#input]	X	ON	L.[LayoutId]		= X.[Id]	AND
										L.[LayoutVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT L.* FROM [Owner].[Entity.Layout]	L
		INNER JOIN	@output						X	ON	L.[LayoutId]	= X.[Id];
	END

	IF (@permissionType = 'LayoutDelete') BEGIN
		DELETE	L	FROM [Owner].[Layout]	L
		INNER JOIN	[#input]				X	ON	L.[LayoutId]		= X.[Id]	AND
													L.[LayoutVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
	END
	
	IF (@permissionType = 'LayoutSearch') BEGIN
		CREATE TABLE [#layout] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner].[Layout.Filter]
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
		INSERT [#layout] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [LayoutOrganisationId] ASC, [LayoutCode] ASC ');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT L.* FROM [Owner].[Entity.Layout]			L
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT L.* FROM [#layout]					X
					INNER JOIN	[Owner].[Entity.Layout]			L	ON	X.[Id]				= L.[LayoutId]
					';
				ELSE
					IF (@organisations IS NULL)
						SET @command = '
						SELECT L.* FROM [Owner].[Entity.Layout]	L	
						LEFT JOIN	[#layout]					X	ON	L.[LayoutId]		= X.[Id]
						WHERE 
							' + ISNULL('L.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
							X.[Id] IS NULL
						';
					ELSE
						SET @command = '
						SELECT L.* FROM [Owner].[Entity.Layout]	L	
						INNER JOIN	[#organisations]			XO	ON	L.[OrganisationId]	= XO.[Id]
						LEFT JOIN	[#layout]					X	ON	L.[LayoutId]		= X.[Id]
						WHERE 
							' + ISNULL('L.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
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
						L.*, 
						ROW_NUMBER() OVER(' + @order + ') [Number]
					FROM [Owner].[Entity.Layout]				L
				)	L
				WHERE L.[Number] BETWEEN
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							L.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [#layout]							X
						INNER JOIN	[Owner].[Entity.Layout]		L	ON	X.[Id]				= L.[LayoutId]
					)	L
					WHERE L.[Number] BETWEEN
					';
				ELSE
					IF (@organisations IS NULL)
						SET @command = '
						SELECT * FROM
						(
							SELECT 
								L.*, 
								ROW_NUMBER() OVER(' + @order + ') [Number]
							FROM [Owner].[Entity.Layout]		L	
							LEFT JOIN	[#layout]				X	ON	L.[LayoutId]		= X.[Id]
							WHERE 
								' + ISNULL('L.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
								X.[Id] IS NULL
						)	L
						WHERE L.[Number] BETWEEN
						';
					ELSE
						SET @command = '
						SELECT * FROM
						(
							SELECT 
								L.*, 
								ROW_NUMBER() OVER(' + @order + ') [Number]
							FROM [Owner].[Entity.Layout]		L	
							INNER JOIN	[#organisations]		XO	ON	L.[OrganisationId]	= XO.[Id]
							LEFT JOIN	[#layout]				X	ON	L.[LayoutId]		= X.[Id]
							WHERE 
								' + ISNULL('L.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
								X.[Id] IS NULL
						)	L
						WHERE L.[Number] BETWEEN
						';
			SET @command = @command + CAST(@startNumber AS NVARCHAR(MAX)) + ' AND ' + CAST(@endNumber AS NVARCHAR(MAX));
		END
		EXEC sp_executesql @command;
	END

END
GO
