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
			O.[name]	= 'Culture.Action'))
	DROP PROCEDURE [Multilanguage].[Culture.Action];
GO

CREATE PROCEDURE [Multilanguage].[Culture.Action]
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
	
	IF (@permissionType = 'CultureCreate') BEGIN
		INSERT [Multilanguage].[Culture] 
		(
			[CultureEmplacementId],
			[CultureCode],
			[CultureName]
		)
		OUTPUT INSERTED.[CultureId] INTO @output ([Id])
		SELECT
			X.[EmplacementId],
			X.[Code],
			X.[Name]
		FROM [Multilanguage].[Culture.Entity](@entity) X;
		SELECT C.* FROM [Multilanguage].[Entity.Culture]		C
		INNER JOIN	@output										X	ON	C.[CultureId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'CultureRead') BEGIN
		SELECT C.* FROM [Multilanguage].[Entity.Culture]		C
		INNER JOIN	[Multilanguage].[Culture.Entity](@entity)	X	ON	C.[CultureId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'CultureUpdate') BEGIN
		UPDATE C SET 
			C.[CultureCode]	= X.[Code],
			C.[CultureName]	= X.[Name]
		OUTPUT INSERTED.[CultureId] INTO @output ([Id])
		FROM [Multilanguage].[Culture]							C
		INNER JOIN	[Multilanguage].[Culture.Entity](@entity)	X	ON	C.[CultureId]		= X.[Id]		AND
																		C.[CultureVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT C.* FROM [Multilanguage].[Entity.Culture]		C
		INNER JOIN	@output										X	ON	C.[CultureId]		= X.[Id];
	END

	IF (@permissionType = 'CultureDelete') BEGIN
		DELETE C FROM [Multilanguage].[Culture]					C
		INNER JOIN	[Multilanguage].[Culture.Entity](@entity)	X	ON	C.[CultureId]		= X.[Id]		AND
																		C.[CultureVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
	END
	
	IF (@permissionType = 'CultureSearch') BEGIN
		CREATE TABLE [#culture] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Multilanguage].[Culture.Filter]
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
		INSERT [#culture] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [CultureEmplacementId] ASC, [CultureCode] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT C.* FROM [Multilanguage].[Entity.Culture]		C
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT C.* FROM [#culture]							X
				INNER JOIN	[Multilanguage].[Entity.Culture]		C	ON	X.[Id]			= C.[CultureId]
				';
			ELSE
				SET @command = '
				SELECT C.* FROM [Multilanguage].[Entity.Culture]	C
				LEFT JOIN	[#culture]								X	ON	C.[CultureId]	= X.[Id]
				WHERE 
					' + ISNULL('C.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
					X.[Id] IS NULL
				';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
