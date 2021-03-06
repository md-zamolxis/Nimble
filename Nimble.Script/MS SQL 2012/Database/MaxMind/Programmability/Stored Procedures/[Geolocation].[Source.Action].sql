SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Geolocation'	AND
			O.[type]	= 'P'			AND
			O.[name]	= 'Source.Action'))
	DROP PROCEDURE [Geolocation].[Source.Action];
GO

CREATE PROCEDURE [Geolocation].[Source.Action]
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
		@order			= @order			OUTPUT;
	
	SELECT * INTO [#input] FROM [Geolocation].[Source.Entity](@entity) X;

	DECLARE
		@sourceId				UNIQUEIDENTIFIER,
		@sourceInputType		NVARCHAR(MAX),
		@portionId				UNIQUEIDENTIFIER,
		@count					INT;
	
	IF (@permissionType = 'SourceCreate') BEGIN
		INSERT [Geolocation].[Source] 
		(
			[SourceCode],
			[SourceInputType],
			[SourceDescription],
			[SourceCreatedOn],
			[SourceApprovedOn],
			[SourceInput],
			[SourceInputLength],
			[SourceEntriesLoaded],
			[SourceErrors],
			[SourceErrorsLoaded]
		)
		OUTPUT INSERTED.[SourceId] INTO @output ([Id])
		SELECT
			X.[Code],
			X.[SourceInputType],
			X.[Description],
			X.[CreatedOn],
			X.[ApprovedOn],
			X.[Input],
			X.[InputLength],
			X.[EntriesLoaded],
			X.[Errors],
			X.[ErrorsLoaded]
		FROM [#input] X;
		SELECT S.* FROM [Geolocation].[Entity.Source]	S
		INNER JOIN	@output								X	ON	S.[SourceId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'SourceRead') BEGIN
		SELECT S.* FROM [Geolocation].[Entity.Source]	S
		INNER JOIN	[#input]							X	ON	S.[SourceId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'SourceUpdate') BEGIN
		UPDATE S SET 
			S.[SourceCode]				= X.[Code],
			S.[SourceDescription]		= X.[Description],
			S.[SourceApprovedOn]		= X.[ApprovedOn]
		OUTPUT INSERTED.[SourceId] INTO @output ([Id])
		FROM [Geolocation].[Source]	S
		INNER JOIN	[#input]		X	ON	S.[SourceId]		= X.[Id]	AND
											S.[SourceVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT S.* FROM [Geolocation].[Entity.Source]	S 
		INNER JOIN	@output								X	ON	S.[SourceId]	= X.[Id];
	END
	
	IF (@permissionType = 'SourceDelete') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			DELETE	P	FROM [Geolocation].[Portion]	P
			INNER JOIN	[#input]						X	ON	P.[PortionSourceId]	= X.[Id];
			DELETE	S	FROM [Geolocation].[Source]	S
			INNER JOIN	[#input]					X	ON	S.[SourceId]		= X.[Id]	AND
															S.[SourceVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END
	
	IF (@permissionType = 'SourceSearch') BEGIN
		CREATE TABLE [#source] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Geolocation].[Source.Filter]
			@predicate,
			@isCountable,
			@guids		OUTPUT,
			@isExcluded OUTPUT,
			@isFiltered OUTPUT,
			@number		OUTPUT',
			N'@predicate	XML,
			@isCountable	BIT,
			@guids			XML OUTPUT,
			@isExcluded		BIT OUTPUT,
			@isFiltered		BIT OUTPUT,
			@number			INT OUTPUT',
			@predicate		= @predicate,
			@isCountable	= @isCountable,
			@guids			= @guids		OUTPUT,
			@isExcluded		= @isExcluded	OUTPUT,
			@isFiltered		= @isFiltered	OUTPUT,
			@number			= @number		OUTPUT;
		INSERT [#source] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [SourceCreatedOn] DESC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT S.* FROM [Geolocation].[Entity.Source]		S
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT S.* FROM [#source]						X
				INNER JOIN	[Geolocation].[Entity.Source]		S	ON	X.[Id]			= S.[SourceId]
				';
			ELSE
				SET @command = '
				SELECT S.* FROM [Geolocation].[Entity.Source]	S
				LEFT JOIN	[#source]							X	ON	S.[SourceId]	= X.[Id]
				WHERE X.[Id] IS NULL
				';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END
	
	IF (@permissionType = 'SourceLoad') BEGIN
		SELECT S.* FROM [Geolocation].[Source]				S
		INNER JOIN	[#input]								X	ON	S.[SourceId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'SourceApprove') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			SELECT 
				@sourceId			= S.[SourceId],
				@sourceInputType	= S.[SourceInputType],
				@number				= 0
			FROM [Geolocation].[Source]						S
			INNER JOIN	[#input]							X	ON	S.[SourceId]	= X.[Id];
			IF (@sourceInputType = 'MaxMindLocations')
				CREATE TABLE [#location] 
				(
					[Code]			BIGINT,
					[Country]		NVARCHAR(MAX),
					[Region]		NVARCHAR(MAX),
					[City]			NVARCHAR(MAX),
					[PostalCode]	NVARCHAR(MAX),
					[Latitude]		MONEY,
					[Longitude]		MONEY,
					[MetroCode]		NVARCHAR(MAX),
					[AreaCode]		NVARCHAR(MAX)
				);
			IF (@sourceInputType = 'MaxMindBlocks')
				CREATE TABLE [#block] 
				(
					[IpNumberFrom]	BIGINT,
					[IpNumberTo]	BIGINT,
					[LocationCode]	BIGINT,
					[IpDataFrom]	NVARCHAR(MAX),
					[IpDataTo]		NVARCHAR(MAX)
				);
			DECLARE [Sources] CURSOR FOR 
			SELECT P.[PortionId] FROM [Geolocation].[Portion] P
			WHERE P.[PortionSourceId] = @sourceId
			ORDER BY P.[PortionCode];
			OPEN [Sources];
			FETCH NEXT FROM [Sources] INTO @portionId;
			WHILE @@FETCH_STATUS = 0 BEGIN
				IF (@sourceInputType = 'MaxMindLocations')
					INSERT [#location]
					SELECT L.* FROM 
					(
						SELECT P.[PortionEntries].query('Locations/Location') [Entries] 
						FROM [Geolocation].[Portion] P
						WHERE P.[PortionId] = @portionId
					) X
					CROSS APPLY [Geolocation].[Location.Entity](X.[Entries]) L;
				IF (@sourceInputType = 'MaxMindBlocks')
					INSERT [#block]
					SELECT B.* FROM 
					(
						SELECT P.[PortionEntries].query('Blocks/Block') [Entries] 
						FROM [Geolocation].[Portion] P
						WHERE P.[PortionId] = @portionId
					) X
					CROSS APPLY [Geolocation].[Block.Entity](X.[Entries]) B;
				SELECT 
					@count	= @@ROWCOUNT,
					@number	= @number + @count;
				UPDATE P SET P.[PortionEntriesImported] = @count 
				FROM [Geolocation].[Portion] P
				WHERE P.[PortionId] = @portionId;
				FETCH NEXT FROM [Sources] INTO @portionId;
			END 
			CLOSE [Sources];
			DEALLOCATE [Sources];
			IF (@sourceInputType = 'MaxMindLocations') BEGIN
				INSERT [Geolocation].[Location]
				SELECT S.* FROM [#location]				S
				LEFT JOIN	[Geolocation].[Location]	L	ON	S.[Code]	= L.[LocationCode]
				WHERE L.[LocationCode] IS NULL;
				UPDATE L SET 
					L.[LocationCountry]		= S.[Country],
					L.[LocationRegion]		= S.[Region],
					L.[LocationCity]		= S.[City],
					L.[LocationPostalCode]	= S.[PostalCode],
					L.[LocationLatitude]	= S.[Latitude],
					L.[LocationLongitude]	= S.[Longitude],
					L.[LocationMetroCode]	= S.[MetroCode],
					L.[LocationAreaCode]	= S.[AreaCode]
				FROM [Geolocation].[Location]	L
				INNER JOIN	[#location]			S	ON L.[LocationCode]	= S.[Code];
				DROP TABLE [#location];
			END
			IF (@sourceInputType = 'MaxMindBlocks') BEGIN
				DELETE B FROM [Geolocation].[Block]		B
				INNER JOIN	[#block]					S	ON	S.[IpNumberFrom]	BETWEEN B.[BlockIpNumberFrom] AND B.[BlockIpNumberTo];
				DELETE B FROM [Geolocation].[Block]		B
				INNER JOIN	[#block]					S	ON	S.[IpNumberTo]		BETWEEN B.[BlockIpNumberFrom] AND B.[BlockIpNumberTo];
				INSERT [Geolocation].[Block] 
				SELECT S.* FROM [#block]				S
				INNER JOIN	[Geolocation].[Location]	L	ON	S.[LocationCode]	= L.[LocationCode];
				DROP TABLE [#block];
			END
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END

END
GO
