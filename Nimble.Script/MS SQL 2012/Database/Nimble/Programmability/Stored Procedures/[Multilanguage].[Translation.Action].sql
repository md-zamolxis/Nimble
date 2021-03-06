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
			O.[name]	= 'Translation.Action'))
	DROP PROCEDURE [Multilanguage].[Translation.Action];
GO

CREATE PROCEDURE [Multilanguage].[Translation.Action]
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
	
	IF (@permissionType = 'TranslationCreate') BEGIN
		INSERT [Multilanguage].[Translation] 
		(
			[TranslationResourceId],
			[TranslationCultureId],
			[TranslationSense]
		)
		OUTPUT INSERTED.[TranslationId] INTO @output ([Id])
		SELECT
			X.[ResourceId],
			X.[CultureId],
			X.[Sense]
		FROM [Multilanguage].[Translation.Entity](@entity)			X;
		SELECT T.* FROM [Multilanguage].[Entity.Translation]		T
		INNER JOIN	@output											X	ON	T.[TranslationId]		= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'TranslationRead') BEGIN
		SELECT T.* FROM [Multilanguage].[Entity.Translation]		T
		INNER JOIN	[Multilanguage].[Translation.Entity](@entity)	X	ON	T.[TranslationId]		= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'TranslationUpdate') BEGIN
		UPDATE T SET 
			T.[TranslationSense]	= X.[Sense]
		OUTPUT INSERTED.[TranslationId] INTO @output ([Id])
		FROM [Multilanguage].[Translation]							T
		INNER JOIN	[Multilanguage].[Translation.Entity](@entity)	X	ON	T.[TranslationId]		= X.[Id]		AND
																			T.[TranslationVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT T.* FROM [Multilanguage].[Entity.Translation]		T
		INNER JOIN	@output											X	ON	T.[TranslationId]		= X.[Id];
	END

	IF (@permissionType = 'TranslationDelete') BEGIN
		DELETE T FROM [Multilanguage].[Translation]					T
		INNER JOIN	[Multilanguage].[Translation.Entity](@entity)	X	ON	T.[TranslationId]		= X.[Id]		AND
																			T.[TranslationVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
	END
	
	IF (@permissionType = 'TranslationSearch') BEGIN
		CREATE TABLE [#translation] 
		(
			[ResourceId]	UNIQUEIDENTIFIER,
			[CultureId]		UNIQUEIDENTIFIER,
			PRIMARY KEY CLUSTERED 
			(
				[ResourceId],
				[CultureId]
			)
		);
		EXEC sp_executesql 
			N'EXEC [Multilanguage].[Translation.Filter]
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
		INSERT [#translation]
		SELECT 
			LTRIM(X.[Entity].value('(ResourceId/text())[1]',	'UNIQUEIDENTIFIER')) [ResourceId],
			LTRIM(X.[Entity].value('(CultureId/text())[1]',		'UNIQUEIDENTIFIER')) [CultureId]
		FROM @guids.nodes('/*/guid') X ([Entity]);
		SET @order = ISNULL(@order, ' ORDER BY [CultureCode] ASC, [ResourceCategory] ASC, [ResourceCode] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT T.* FROM [Multilanguage].[Entity.Translation]		T
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT T.* FROM [#translation]							X
				INNER JOIN	[Multilanguage].[Entity.Translation]		T	ON	X.[ResourceId]	= T.[ResourceId]	AND
																				X.[CultureId]	= T.[CultureId]
				';
			ELSE
				SET @command = '
				SELECT T.* FROM [Multilanguage].[Entity.Translation]	T
				LEFT JOIN	[#translation]								X	ON	T.[ResourceId]	= X.[ResourceId]	AND
																				T.[CultureId]	= X.[CultureId]
				WHERE 
					' + ISNULL('T.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
					' + ISNULL('T.[ApplicationId] = ''' + CAST(@applicationId AS NVARCHAR(MAX)) + ''' AND', '') + '
					COALESCE(X.[ResourceId], X.[CultureId]) IS NULL
				';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
