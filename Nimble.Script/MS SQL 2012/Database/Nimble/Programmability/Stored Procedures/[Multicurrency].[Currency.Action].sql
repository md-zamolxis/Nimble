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
			O.[name]	= 'Currency.Action'))
	DROP PROCEDURE [Multicurrency].[Currency.Action];
GO

CREATE PROCEDURE [Multicurrency].[Currency.Action]
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

	SELECT * INTO [#input] FROM [Multicurrency].[Currency.Entity](@entity) X;
	
	DECLARE @rates XML = @entity.query('/*/Rates/Rate');
	
	IF (@permissionType = 'CurrencyCreate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			IF (EXISTS(SELECT * FROM [#input] X WHERE X.[IsDefault] = 1))
				UPDATE C SET C.[CurrencyIsDefault] = 0
				FROM [Multicurrency].[Currency]	C
				INNER JOIN	[#input]		X	ON	C.[CurrencyOrganisationId]	= X.[OrganisationId]	AND
													C.[CurrencyIsDefault]		= 1;
			INSERT [Multicurrency].[Currency] 
			(
				[CurrencyOrganisationId],
				[CurrencyCode],
				[CurrencyCreatedOn],
				[CurrencyDescription],
				[CurrencyIsDefault],
				[CurrencyLockedOn]
			)
			OUTPUT INSERTED.[CurrencyId] INTO @output ([Id])
			SELECT
				X.[OrganisationId],
				X.[Code],
				X.[CreatedOn],
				X.[Description],
				X.[IsDefault],
				X.[LockedOn]
			FROM [#input] X;
			INSERT [Multicurrency].[Rate]
			(
				[RateTradeId],
			    [RateCurrencyFrom],
			    [RateCurrencyTo],
			    [RateValue]
			)
			SELECT
				T.[TradeId],
				CF.[CurrencyId],
				CT.[CurrencyId],
				ISNULL(CR.[Value], 1)
			FROM [Multicurrency].[Trade]						T
			INNER JOIN	[Multicurrency].[Currency]				CF	ON	T.[TradeOrganisationId]	= CF.[CurrencyOrganisationId]
			INNER JOIN	[Multicurrency].[Currency]				CT	ON	T.[TradeOrganisationId]	= CT.[CurrencyOrganisationId]
			INNER JOIN	@output									X	ON	CF.[CurrencyId]			= X.[Id]				OR
																		CT.[CurrencyId]			= X.[Id]
			LEFT JOIN	[Multicurrency].[Rate.Entity](@rates)	CR	ON	CF.[CurrencyId]			= CR.[CurrencyFrom]		AND
																		CT.[CurrencyId]			= CR.[CurrencyTo]
			LEFT JOIN	[Multicurrency].[Rate]					R	ON	T.[TradeId]				= R.[RateTradeId]		AND
																		CF.[CurrencyId]			= R.[RateCurrencyFrom]	AND
																		CT.[CurrencyId]			= R.[RateCurrencyTo]
			WHERE R.[RateId] IS NULL;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT C.* FROM [Multicurrency].[Entity.Currency]		C
		INNER JOIN	@output										X	ON	C.[CurrencyId]			= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'CurrencyRead') BEGIN
		SELECT C.* FROM [Multicurrency].[Entity.Currency]		C
		INNER JOIN	[#input]									X	ON	C.[CurrencyId]			= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'CurrencyUpdate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			IF (EXISTS(SELECT * FROM [#input] X WHERE X.[IsDefault] = 1))
				UPDATE C SET C.[CurrencyIsDefault] = 0
				FROM [Multicurrency].[Currency]	C
				INNER JOIN	[#input]			X	ON	C.[CurrencyOrganisationId]	= X.[OrganisationId]	AND
														C.[CurrencyIsDefault]		= 1;
			UPDATE C SET 
				C.[CurrencyCode]		= X.[Code],
				C.[CurrencyDescription]	= X.[Description],
				C.[CurrencyIsDefault]	= X.[IsDefault],
				C.[CurrencyLockedOn]	= X.[LockedOn]
			OUTPUT INSERTED.[CurrencyId] INTO @output ([Id])
			FROM [Multicurrency].[Currency]						C
			INNER JOIN	[#input]								X	ON	C.[CurrencyId]			= X.[Id]	AND
																		C.[CurrencyVersion]		= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT C.* FROM [Multicurrency].[Entity.Currency]		C
		INNER JOIN	@output										X	ON	C.[CurrencyId]			= X.[Id];
	END

	IF (@permissionType = 'CurrencyDelete') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			DELETE R FROM [Multicurrency].[Rate] 				R
			INNER JOIN	[#input]								X	ON	R.[RateCurrencyFrom]	= X.[Id]	OR
																		R.[RateCurrencyTo]		= X.[Id];
			DELETE C FROM [Multicurrency].[Currency]			C
			INNER JOIN	[#input]								X	ON	C.[CurrencyId]			= X.[Id]	AND
																		C.[CurrencyVersion]		= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END
	
	IF (@permissionType = 'CurrencySearch') BEGIN
		CREATE TABLE [#currency] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Multicurrency].[Currency.Filter]
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
		INSERT [#currency] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [CurrencyOrganisationId] ASC, [CurrencyCode] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT C.* FROM [Multicurrency].[Entity.Currency]			C
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT C.* FROM [#currency]								X
				INNER JOIN	[Multicurrency].[Entity.Currency]			C	ON	X.[Id]				= C.[CurrencyId]
				';
			ELSE
				IF (@organisations IS NULL)
					SET @command = '
					SELECT C.* FROM [Multicurrency].[Entity.Currency]	C
					LEFT JOIN	[#currency]								X	ON	C.[CurrencyId]		= X.[Id]
					WHERE 
						' + ISNULL('C.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						X.[Id] IS NULL
					';
				ELSE
					SET @command = '
					SELECT C.* FROM [Multicurrency].[Entity.Currency]	C
					INNER JOIN	[#organisations]						XO	ON	C.[OrganisationId]	= XO.[Id]
					LEFT JOIN	[#currency]								X	ON	C.[CurrencyId]		= X.[Id]
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
