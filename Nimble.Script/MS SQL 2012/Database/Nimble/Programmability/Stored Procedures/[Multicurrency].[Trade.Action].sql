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
			O.[name]	= 'Trade.Action'))
	DROP PROCEDURE [Multicurrency].[Trade.Action];
GO

CREATE PROCEDURE [Multicurrency].[Trade.Action]
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

	SELECT * INTO [#input] FROM [Multicurrency].[Trade.Entity](@entity) X;
	
	DECLARE @rates XML = @entity.query('/*/Rates/Rate');
	
	DECLARE @trade TABLE 
	(
		[OrganisationId]	UNIQUEIDENTIFIER,
		[From]				DATETIMEOFFSET,
		[To]				DATETIMEOFFSET
	);

	IF (@permissionType = 'TradeCreate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			-- Insert base interval if not exist
			INSERT [Multicurrency].[Trade] 
			(
				[TradeOrganisationId],
				[TradeCreatedOn],
				[TradeFrom],
				[TradeTo]
			)
			OUTPUT INSERTED.[TradeId] INTO @output ([Id])
			SELECT
				X.[OrganisationId],
				X.[CreatedOn],
				X.[From],
				X.[To]
			FROM [#input]	X
			LEFT JOIN	
			(
				SELECT * FROM [Multicurrency].[Trade] T	
				WHERE COALESCE(T.[TradeFrom], T.[TradeTo]) IS NOT NULL
			)	T	ON	X.[OrganisationId]	= T.[TradeOrganisationId]
			WHERE T.[TradeId] IS NULL;
			INSERT [Multicurrency].[Rate]
			(
				[RateTradeId],
			    [RateCurrencyFrom],
			    [RateCurrencyTo],
			    [RateValue]
			)
			SELECT 
				X.[Id],
				C.[CurrencyFrom],
				C.[CurrencyTo],
				1
			FROM @output	X
			CROSS JOIN 
			(
				SELECT
					CF.[CurrencyId]	[CurrencyFrom],
					CT.[CurrencyId]	[CurrencyTo]
				FROM [#input]							T
				INNER JOIN	[Multicurrency].[Currency]	CF	ON	T.[OrganisationId]	= CF.[CurrencyOrganisationId]
				INNER JOIN	[Multicurrency].[Currency]	CT	ON	T.[OrganisationId]	= CT.[CurrencyOrganisationId]
			)	C;
			-- Split interval
			UPDATE T SET T.[TradeTo] = X.[AppliedOn]
			OUTPUT DELETED.[TradeTo] INTO @trade ([To])
			FROM [Multicurrency].[Trade]	T
		    INNER JOIN	[#input]			X   ON  T.[TradeOrganisationId]  = X.[OrganisationId]    AND
											        (T.[TradeFrom] < X.[AppliedOn] AND X.[AppliedOn] <= T.[TradeTo]);
            -- Insert new interval
			DELETE @output;
			WITH XC AS
			(
				SELECT ISNULL(MAX(CAST(T.[TradeCode] AS INT)), 0) + 1	[Code]
				FROM [#input]						X
				INNER JOIN	[Multicurrency].[Trade]	T	ON	X.[OrganisationId]	= T.[TradeOrganisationId]
				WHERE [Common].[Code.IsNumeric](T.[TradeCode]) = 1
			)
			INSERT [Multicurrency].[Trade] 
			(
				[TradeOrganisationId],
				[TradeCode],
				[TradeCreatedOn],
				[TradeDescription],
				[TradeFrom],
				[TradeTo]
			)
			OUTPUT INSERTED.[TradeId] INTO @output ([Id])
			SELECT
				X.[OrganisationId],
				ISNULL(X.[Code], XC.[Code]),
				X.[CreatedOn],
				X.[Description],
				X.[AppliedOn],
				T.[To]
			FROM [#input] X OUTER APPLY XC OUTER APPLY @trade T;
			INSERT [Multicurrency].[Rate]
			(
				[RateTradeId],
			    [RateCurrencyFrom],
			    [RateCurrencyTo],
			    [RateValue]
			)
			SELECT 
				X.[Id],
				C.[CurrencyFrom],
				C.[CurrencyTo],
				C.[Value]
			FROM @output	X
			CROSS JOIN 
			(
				SELECT
					CF.[CurrencyId]			[CurrencyFrom],
					CT.[CurrencyId]			[CurrencyTo],
					ISNULL(TR.[Value], 1)	[Value]
				FROM [#input]										T
				INNER JOIN	[Multicurrency].[Currency]				CF	ON	T.[OrganisationId]	= CF.[CurrencyOrganisationId]
				INNER JOIN	[Multicurrency].[Currency]				CT	ON	T.[OrganisationId]	= CT.[CurrencyOrganisationId]
				LEFT JOIN	[Multicurrency].[Rate.Entity](@rates)	TR	ON	CF.[CurrencyId]		= TR.[CurrencyFrom]	AND
																		CT.[CurrencyId]		= TR.[CurrencyTo]
			)	C;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT T.* FROM [Multicurrency].[Entity.Trade]	T
		INNER JOIN	@output								X	ON	T.[TradeId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'TradeRead') BEGIN
		SELECT T.* FROM [Multicurrency].[Entity.Trade]	T
		INNER JOIN	[#input]							X	ON	T.[TradeId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'TradeUpdate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			UPDATE T SET 
				T.[TradeCode]			= X.[Code],
				T.[TradeDescription]	= X.[Description]
			OUTPUT INSERTED.[TradeId] INTO @output ([Id])
			FROM [Multicurrency].[Trade]	T
			INNER JOIN	[#input]			X	ON	T.[TradeId]			= X.[Id]	AND
													T.[TradeVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			UPDATE R SET R.[RateValue] = TR.[Value]
			FROM [Multicurrency].[Rate]							R
			INNER JOIN	@output									T	ON	R.[RateTradeId]			= T.[Id]
			INNER JOIN	[Multicurrency].[Rate.Entity](@rates)	TR	ON	R.[RateCurrencyFrom]	= TR.[CurrencyFrom]	AND
																		R.[RateCurrencyTo]		= TR.[CurrencyTo];
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT T.* FROM [Multicurrency].[Entity.Trade]	T
		INNER JOIN	@output								X	ON	T.[TradeId]	= X.[Id];
	END

	IF (@permissionType = 'TradeDelete') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			DELETE R FROM [Multicurrency].[Rate]	R
			INNER JOIN	[#input]					X	ON	R.[RateTradeId]	= X.[Id];
			DELETE T OUTPUT 
				DELETED.[TradeOrganisationId],
				DELETED.[TradeFrom],
				DELETED.[TradeTo]
			INTO @trade
			FROM [Multicurrency].[Trade]	T
			INNER JOIN	[#input]			X	ON	T.[TradeId]			= X.[Id]	AND
													T.[TradeVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			UPDATE T SET T.[TradeFrom] = X.[From]
			FROM [Multicurrency].[Trade]	T
			INNER JOIN	@trade				X	ON	T.[TradeOrganisationId]	= X.[OrganisationId]	AND
													T.[TradeFrom]			= X.[To];
			IF (@@ROWCOUNT = 0)
				UPDATE T SET T.[TradeTo] = X.[To]
				FROM [Multicurrency].[Trade]	T
				INNER JOIN	@trade				X	ON	T.[TradeOrganisationId]	= X.[OrganisationId]	AND
														T.[TradeTo]				= X.[From];
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END
	
	IF (@permissionType = 'TradeSearch') BEGIN
		CREATE TABLE [#trade] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Multicurrency].[Trade.Filter]
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
		INSERT [#trade] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [TradeOrganisationId] ASC, [TradeCode] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT T.* FROM [Multicurrency].[Entity.Trade]			T
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT T.* FROM [#trade]							X
				INNER JOIN	[Multicurrency].[Entity.Trade]			T	ON	X.[Id]				= T.[TradeId]
				';
			ELSE
				IF (@organisations IS NULL)
					SET @command = '
					SELECT T.* FROM [Multicurrency].[Entity.Trade]	T
					LEFT JOIN	[#trade]							X	ON	T.[TradeId]			= X.[Id]
					WHERE 
						' + ISNULL('T.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						X.[Id] IS NULL
					';
				ELSE
					SET @command = '
					SELECT T.* FROM [Multicurrency].[Entity.Trade]	T
					INNER JOIN	[#organisations]					XO	ON	T.[OrganisationId]	= XO.[Id]
					LEFT JOIN	[#trade]							X	ON	T.[TradeId]			= X.[Id]
					WHERE 
						' + ISNULL('T.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						X.[Id] IS NULL
					';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
