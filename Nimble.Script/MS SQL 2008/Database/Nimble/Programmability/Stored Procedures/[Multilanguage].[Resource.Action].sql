SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multilanguage'	AND
			O.[type]	= 'P'				AND
			O.[name]	= 'Resource.Action'))
	DROP PROCEDURE [Multilanguage].[Resource.Action];
GO

CREATE PROCEDURE [Multilanguage].[Resource.Action]
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

	SELECT * INTO [#input] FROM [Multilanguage].[Resource.Entity](@entity);
	
	IF (@permissionType = 'ResourceCreate') BEGIN
	    WITH XI AS
	    (
		    SELECT ISNULL(MAX(CAST(R.[ResourceIndex] AS INT)), 0) + 1	[Index]
			FROM [#input]							X
			INNER JOIN	[Multilanguage].[Resource]	R	ON	X.[EmplacementId]	= R.[ResourceEmplacementId]	AND
															X.[ApplicationId]	= R.[ResourceApplicationId]
		    WHERE [Common].[Code.IsNumeric](R.[ResourceIndex]) = 1
	    )
		INSERT [Multilanguage].[Resource] 
		(
			[ResourceEmplacementId],
			[ResourceApplicationId],
			[ResourceCode],
			[ResourceCategory],
			[ResourceIndex],
			[ResourceCreatedOn],
			[ResourceLastUsedOn]
		)
		OUTPUT INSERTED.[ResourceId] INTO @output ([Id])
		SELECT
			X.[EmplacementId],
			X.[ApplicationId],
			X.[Code],
			X.[Category],
			ISNULL(X.[Index], XI.[Index]),
			X.[CreatedOn],
			X.[LastUsedOn]
		FROM [#input] X OUTER APPLY XI;
		SELECT R.* FROM [Multilanguage].[Entity.Resource]	R
		INNER JOIN	@output									X	ON	R.[ResourceId]		= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'ResourceRead') BEGIN
		SELECT R.* FROM [Multilanguage].[Entity.Resource]	R
		INNER JOIN	[#input]								X	ON	R.[ResourceId]		= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'ResourceUpdate') BEGIN
		UPDATE R SET 
			R.[ResourceCode]		= X.[Code],
			R.[ResourceCategory]	= X.[Category],
			R.[ResourceIndex]		= X.[Index],
			R.[ResourceLastUsedOn]	= X.[LastUsedOn]
		OUTPUT INSERTED.[ResourceId] INTO @output ([Id])
		FROM [Multilanguage].[Resource]						R
		INNER JOIN	[#input]								X	ON	R.[ResourceId]		= X.[Id]	AND
																	R.[ResourceVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT R.* FROM [Multilanguage].[Entity.Resource]	R
		INNER JOIN	@output									X	ON	R.[ResourceId]		= X.[Id];
	END

	IF (@permissionType = 'ResourceDelete') BEGIN
		DELETE	R	FROM [Multilanguage].[Resource]			R
		INNER JOIN	[#input]								X	ON	R.[ResourceId]		= X.[Id]	AND
																	R.[ResourceVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
	END
	
	IF (@permissionType = 'ResourceSearch') BEGIN
		CREATE TABLE [#resource] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Multilanguage].[Resource.Filter]
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
		INSERT [#resource] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [ResourceEmplacementId] ASC, [ResourceApplicationId] ASC, [ResourceCode] ASC, [ResourceCategory] ');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT R.* FROM [Multilanguage].[Entity.Resource]		R
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT R.* FROM [#resource]							X
					INNER JOIN	[Multilanguage].[Entity.Resource]		R	ON	X.[Id]			= R.[ResourceId]
					';
				ELSE
					SET @command = '
					SELECT R.* FROM [Multilanguage].[Entity.Resource]	R
					LEFT JOIN	[#resource]								X	ON	R.[ResourceId]	= X.[Id]
					WHERE 
						' + ISNULL('R.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						' + ISNULL('R.[ApplicationId] = ''' + CAST(@applicationId AS NVARCHAR(MAX)) + ''' AND', '') + '
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
						R.*, 
						ROW_NUMBER() OVER(' + @order + ') [Number]
					FROM [Multilanguage].[Entity.Resource]				R
				)	R
				WHERE R.[Number] BETWEEN
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							R.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [#resource]								X
						INNER JOIN	[Multilanguage].[Entity.Resource]	R	ON	X.[Id]			= R.[ResourceId]
					)	R
					WHERE R.[Number] BETWEEN
					';
				ELSE
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							R.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [Multilanguage].[Entity.Resource]			R
						LEFT JOIN	[#resource]							X	ON	R.[ResourceId]	= X.[Id]
						WHERE 
							' + ISNULL('R.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
							' + ISNULL('R.[ApplicationId] = ''' + CAST(@applicationId AS NVARCHAR(MAX)) + ''' AND', '') + '
							X.[Id] IS NULL
					)	R
					WHERE R.[Number] BETWEEN
					';
			SET @command = @command + CAST(@startNumber AS NVARCHAR(MAX)) + ' AND ' + CAST(@endNumber AS NVARCHAR(MAX));
		END
		EXEC sp_executesql @command;
	END
		
	IF (@permissionType = 'ResourceSave') BEGIN
		UPDATE R SET 
			R.[ResourceCode]		= X.[Code],
			R.[ResourceCategory]	= X.[Category],
			R.[ResourceIndex]		= X.[Index],
			R.[ResourceLastUsedOn]	= X.[LastUsedOn]
		OUTPUT INSERTED.[ResourceId] INTO @output ([Id])
		FROM [Multilanguage].[Resource]						R
		INNER JOIN	[#input]								X	ON	R.[ResourceId]		= X.[Id];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT R.* FROM [Multilanguage].[Entity.Resource]	R
		INNER JOIN	@output									X	ON	R.[ResourceId]		= X.[Id];
	END

END
GO
