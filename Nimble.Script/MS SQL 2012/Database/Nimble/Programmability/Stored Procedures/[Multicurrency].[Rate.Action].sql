SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multicurrency'	AND
			O.[type]	= 'P'				AND
			O.[name]	= 'Rate.Action'))
	DROP PROCEDURE [Multicurrency].[Rate.Action];
GO

CREATE PROCEDURE [Multicurrency].[Rate.Action]
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
	
	CREATE TABLE [#organisations] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
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
	INSERT [#organisations] SELECT * FROM [Common].[Guid.Entities](@organisations);
	
	IF (@permissionType = 'RateCreate') BEGIN
		INSERT [Multicurrency].[Rate]
		(
			[RateTradeId],
		    [RateCurrencyFrom],
		    [RateCurrencyTo],
		    [RateValue]
		)
		OUTPUT INSERTED.[RateId] INTO @output ([Id])
		SELECT
			X.[TradeId],
		    X.[CurrencyFrom],
		    X.[CurrencyTo],
		    X.[Value]
		FROM [Multicurrency].[Rate.Entity](@entity) X;
		SELECT R.* FROM [Multicurrency].[Entity.Rate]		R
		INNER JOIN	@output									X	ON	R.[RateId]		= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'RateRead') BEGIN
		SELECT R.* FROM [Multicurrency].[Entity.Rate]		R
		INNER JOIN	[Multicurrency].[Rate.Entity](@entity)	X	ON	R.[RateId]		= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'RateUpdate') BEGIN
		UPDATE R SET R.[RateValue] = X.[Value]
		OUTPUT INSERTED.[RateId] INTO @output ([Id])
		FROM [Multicurrency].[Rate]							R
		INNER JOIN	[Multicurrency].[Rate.Entity](@entity)	X	ON	R.[RateId]		= X.[Id]	AND
																	R.[RateVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT R.* FROM [Multicurrency].[Entity.Rate]		R
		INNER JOIN	@output									X	ON	R.[RateId]		= X.[Id];
	END
	
	IF (@permissionType = 'RateSearch') BEGIN
		CREATE TABLE [#rate] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Multicurrency].[Rate.Filter]
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
		INSERT [#rate] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [RateTradeId] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT R.* FROM [Multicurrency].[Entity.Rate]			R
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT R.* FROM [#rate]								X
				INNER JOIN	[Multicurrency].[Entity.Rate]			R	ON	X.[Id]				= R.[RateId]
				';
			ELSE
				IF (@organisations IS NULL)
					SET @command = '
					SELECT R.* FROM [Multicurrency].[Entity.Rate]	R
					LEFT JOIN	[#rate]								X	ON	R.[RateId]			= X.[Id]
					WHERE 
						' + ISNULL('R.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						X.[Id] IS NULL
					';
				ELSE
					SET @command = '
					SELECT R.* FROM [Multicurrency].[Entity.Rate]	R
					INNER JOIN	[#organisations]					XO	ON	R.[OrganisationId]	= XO.[Id]
					LEFT JOIN	[#rate]								X	ON	R.[RateId]			= X.[Id]
					WHERE 
						' + ISNULL('R.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						X.[Id] IS NULL
					';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
