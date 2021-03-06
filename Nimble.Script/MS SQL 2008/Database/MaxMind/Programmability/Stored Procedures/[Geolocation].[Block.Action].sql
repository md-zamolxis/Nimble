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
			O.[name]	= 'Block.Action'))
	DROP PROCEDURE [Geolocation].[Block.Action];
GO

CREATE PROCEDURE [Geolocation].[Block.Action]
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
		@isCountable	BIT,
		@longs			XML,
		@isExcluded		BIT,
		@isFiltered		BIT,
		@command		NVARCHAR(MAX);
	
	EXEC [Common].[GenericInput.Action] 
		@genericInput	= @genericInput,
		@permissionType = @permissionType	OUTPUT,
		@entity			= @entity			OUTPUT,
		@predicate		= @predicate		OUTPUT,
		@startNumber	= @startNumber		OUTPUT,
		@endNumber		= @endNumber		OUTPUT,
		@order			= @order			OUTPUT;
	
	DECLARE 
		@ipNumberFrom	BIGINT,
		@ipNumberTo		BIGINT;

	IF (@permissionType = 'BlockRead') BEGIN
		SELECT 
			@ipNumberFrom	= X.[IpNumberFrom],
			@ipNumberTo		= X.[IpNumberTo]
		FROM [Geolocation].[Block.Entity](@entity) X;
		SELECT B.* FROM [Geolocation].[Entity.Block] B
		WHERE
			B.[BlockIpNumberFrom]	= @ipNumberFrom	AND
			B.[BlockIpNumberTo]		= @ipNumberTo;
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'BlockSearch') BEGIN
		CREATE TABLE [#block] 
		(
			[IpNumberFrom]	BIGINT,
			[IpNumberTo]	BIGINT
			PRIMARY KEY CLUSTERED 
			(
				[IpNumberFrom]	ASC,
				[IpNumberTo]	ASC
			)
		);
		EXEC sp_executesql 
			N'EXEC [Geolocation].[Block.Filter]
			@predicate,
			@isCountable,
			@longs		OUTPUT,
			@isExcluded OUTPUT,
			@isFiltered OUTPUT,
			@number		OUTPUT',
			N'@predicate	XML,
			@isCountable	BIT,
			@longs			XML OUTPUT,
			@isExcluded		BIT OUTPUT,
			@isFiltered		BIT OUTPUT,
			@number			INT OUTPUT',
			@predicate		= @predicate,
			@isCountable	= @isCountable,
			@longs			= @longs		OUTPUT,
			@isExcluded		= @isExcluded	OUTPUT,
			@isFiltered		= @isFiltered	OUTPUT,
			@number			= @number		OUTPUT;
		INSERT [#block]
		SELECT 
			LTRIM(X.[Entity].value('(IpNumberFrom/text())[1]',	'BIGINT')) [IpNumberFrom],
			LTRIM(X.[Entity].value('(IpNumberTo/text())[1]',	'BIGINT')) [IpNumberTo]
		FROM @longs.nodes('/*/long') X ([Entity]);
		SET @order = ISNULL(@order, ' ORDER BY [BlockIpNumberFrom] ASC ');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT B.* FROM [Geolocation].[Entity.Block]		B
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT B.* FROM [#block]						X
					INNER JOIN	[Geolocation].[Entity.Block]		B	ON	X.[IpNumberFrom]		= B.[BlockIpNumberFrom]	AND
																			X.[IpNumberTo]			= B.[BlockIpNumberTo]
					';
				ELSE
					SET @command = '
					SELECT B.* FROM [Geolocation].[Entity.Block]	B
					LEFT JOIN	[#block]							X	ON	B.[BlockIpNumberFrom]	= X.[IpNumberFrom]	AND
																			B.[BlockIpNumberTo]		= X.[IpNumberTo]
					WHERE COALESCE(X.[IpNumberFrom], X.[IpNumberTo]) IS NULL
					';
			SET @command = @command + @order;
		END
		ELSE BEGIN
			IF (@isFiltered = 0)
				SET @command = '
				SELECT * FROM
				(
					SELECT 
						B.*, 
						ROW_NUMBER() OVER(' + @order + ') [Number]
					FROM [Geolocation].[Entity.Block]				B
				)	B
				WHERE B.[Number] BETWEEN
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							B.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [#block]								X
						INNER JOIN	[Geolocation].[Entity.Block]	B	ON	X.[IpNumberFrom]		= B.[BlockIpNumberFrom]	AND
																			X.[IpNumberTo]			= B.[BlockIpNumberTo]
					)	B
					WHERE B.[Number] BETWEEN
					';
				ELSE
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							B.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [Geolocation].[Entity.Block]			B
						LEFT JOIN	[#block]						X	ON	B.[BlockIpNumberFrom]	= X.[IpNumberFrom]	AND
																			B.[BlockIpNumberTo]		= X.[IpNumberTo]
						WHERE COALESCE(X.[IpNumberFrom], X.[IpNumberTo]) IS NULL
					)	B
					WHERE B.[Number] BETWEEN
					';
			SET @command = @command + CAST(@startNumber AS NVARCHAR(MAX)) + ' AND ' + CAST(@endNumber AS NVARCHAR(MAX));
		END
		EXEC sp_executesql @command;
	END

END
GO
