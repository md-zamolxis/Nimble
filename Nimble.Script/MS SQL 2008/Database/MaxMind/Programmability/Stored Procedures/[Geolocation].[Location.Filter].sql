SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	L
		INNER JOIN	[sys].[objects]		O	ON	L.[schema_id]	= O.[schema_id]
		WHERE 
			L.[name]	= 'Geolocation'	AND
			O.[type]	= 'P'			AND
			O.[name]	= 'Location.Filter'))
	DROP PROCEDURE [Geolocation].[Location.Filter];
GO

CREATE PROCEDURE [Geolocation].[Location.Filter]
(
	@predicate		XML,
	@isCountable	BIT			= NULL,
	@strings		XML	OUTPUT,
	@isExcluded		BIT	OUTPUT,
	@isFiltered		BIT	OUTPUT,
	@number			INT	OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @location TABLE ([Code] INT PRIMARY KEY CLUSTERED);
	
	SET @isFiltered = 0;

--	Filter by countries
	DECLARE @countries TABLE ([Country] NVARCHAR(MAX));
	INSERT @countries SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/Countries/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/Countries/IsExcluded')), 0);
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @location SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
				INNER JOIN	@countries	X	ON	L.[LocationCountry]	LIKE X.[Country];
			ELSE 
				INSERT @location SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
				LEFT JOIN	@countries	X	ON	L.[LocationCountry]	LIKE X.[Country]
				WHERE X.[Country] IS NULL;
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @location	X
				LEFT JOIN
				(
					SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
					INNER JOIN	@countries	X	ON	L.[LocationCountry]	LIKE X.[Country]
				)	L	ON	X.[Code]	= L.[LocationCode]
				WHERE L.[LocationCode]	IS NULL;
			ELSE
				DELETE X FROM @location	X
				LEFT JOIN
				(
					SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
					LEFT JOIN	@countries	X	ON	L.[LocationCountry]	LIKE X.[Country]
					WHERE X.[Country] IS NULL
				)	L	ON	X.[Code]	= L.[LocationCode]
				WHERE L.[LocationCode]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by regions
	DECLARE @regions TABLE ([Region] NVARCHAR(MAX));
	INSERT @regions SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/Regions/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/Regions/IsExcluded')), 0);
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @location SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
				INNER JOIN	@regions	X	ON	L.[LocationRegion]	LIKE X.[Region];
			ELSE 
				INSERT @location SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
				LEFT JOIN	@regions	X	ON	L.[LocationRegion]	LIKE X.[Region]
				WHERE X.[Region] IS NULL;
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @location	X
				LEFT JOIN
				(
					SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
					INNER JOIN	@regions	X	ON	L.[LocationRegion]	LIKE X.[Region]
				)	L	ON	X.[Code]	= L.[LocationCode]
				WHERE L.[LocationCode]	IS NULL;
			ELSE
				DELETE X FROM @location	X
				LEFT JOIN
				(
					SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
					LEFT JOIN	@regions	X	ON	L.[LocationRegion]	LIKE X.[Region]
					WHERE X.[Region] IS NULL
				)	L	ON	X.[Code]	= L.[LocationCode]
				WHERE L.[LocationCode]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by cities
	DECLARE @cities TABLE ([City] NVARCHAR(MAX));
	INSERT @cities SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/Cities/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/Cities/IsExcluded')), 0);
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @location SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
				INNER JOIN	@cities	X	ON	L.[LocationCity]	LIKE X.[City];
			ELSE 
				INSERT @location SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
				LEFT JOIN	@cities	X	ON	L.[LocationCity]	LIKE X.[City]
				WHERE X.[City] IS NULL;
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @location	X
				LEFT JOIN
				(
					SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
					INNER JOIN	@cities	X	ON	L.[LocationCity]	LIKE X.[City]
				)	L	ON	X.[Code]	= L.[LocationCode]
				WHERE L.[LocationCode]	IS NULL;
			ELSE
				DELETE X FROM @location	X
				LEFT JOIN
				(
					SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
					LEFT JOIN	@cities	X	ON	L.[LocationCity]	LIKE X.[City]
					WHERE X.[City] IS NULL
				)	L	ON	X.[Code]	= L.[LocationCode]
				WHERE L.[LocationCode]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by postal codes
	DECLARE @postalCodes TABLE ([PostalCode] NVARCHAR(MAX));
	INSERT @postalCodes SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/PostalCodes/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/PostalCodes/IsExcluded')), 0);
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @location SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
				INNER JOIN	@postalCodes	X	ON	L.[LocationPostalCode]	LIKE X.[PostalCode];
			ELSE 
				INSERT @location SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
				LEFT JOIN	@postalCodes	X	ON	L.[LocationPostalCode]	LIKE X.[PostalCode]
				WHERE X.[PostalCode] IS NULL;
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @location	X
				LEFT JOIN
				(
					SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
					INNER JOIN	@postalCodes	X	ON	L.[LocationPostalCode]	LIKE X.[PostalCode]
				)	L	ON	X.[Code]	= L.[LocationCode]
				WHERE L.[LocationCode]	IS NULL;
			ELSE
				DELETE X FROM @location	X
				LEFT JOIN
				(
					SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
					LEFT JOIN	@postalCodes	X	ON	L.[LocationPostalCode]	LIKE X.[PostalCode]
					WHERE X.[PostalCode] IS NULL
				)	L	ON	X.[Code]	= L.[LocationCode]
				WHERE L.[LocationCode]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by metro codes
	DECLARE @metroCodes TABLE ([MetroCode] NVARCHAR(MAX));
	INSERT @metroCodes SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/MetroCodes/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/MetroCodes/IsExcluded')), 0);
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @location SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
				INNER JOIN	@metroCodes	X	ON	L.[LocationMetroCode]	LIKE X.[MetroCode];
			ELSE 
				INSERT @location SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
				LEFT JOIN	@metroCodes	X	ON	L.[LocationMetroCode]	LIKE X.[MetroCode]
				WHERE X.[MetroCode] IS NULL;
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @location	X
				LEFT JOIN
				(
					SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
					INNER JOIN	@metroCodes	X	ON	L.[LocationMetroCode]	LIKE X.[MetroCode]
				)	L	ON	X.[Code]	= L.[LocationCode]
				WHERE L.[LocationCode]	IS NULL;
			ELSE
				DELETE X FROM @location	X
				LEFT JOIN
				(
					SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
					LEFT JOIN	@metroCodes	X	ON	L.[LocationMetroCode]	LIKE X.[MetroCode]
					WHERE X.[MetroCode] IS NULL
				)	L	ON	X.[Code]	= L.[LocationCode]
				WHERE L.[LocationCode]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by area codes
	DECLARE @areaCodes TABLE ([AreaCode] NVARCHAR(MAX));
	INSERT @areaCodes SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/AreaCodes/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/AreaCodes/IsExcluded')), 0);
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @location SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
				INNER JOIN	@areaCodes	X	ON	L.[LocationAreaCode]	LIKE X.[AreaCode];
			ELSE 
				INSERT @location SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
				LEFT JOIN	@areaCodes	X	ON	L.[LocationAreaCode]	LIKE X.[AreaCode]
				WHERE X.[AreaCode] IS NULL;
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @location	X
				LEFT JOIN
				(
					SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
					INNER JOIN	@areaCodes	X	ON	L.[LocationAreaCode]	LIKE X.[AreaCode]
				)	L	ON	X.[Code]	= L.[LocationCode]
				WHERE L.[LocationCode]	IS NULL;
			ELSE
				DELETE X FROM @location	X
				LEFT JOIN
				(
					SELECT DISTINCT L.[LocationCode] FROM [Geolocation].[Location] L
					LEFT JOIN	@areaCodes	X	ON	L.[LocationAreaCode]	LIKE X.[AreaCode]
					WHERE X.[AreaCode] IS NULL
				)	L	ON	X.[Code]	= L.[LocationCode]
				WHERE L.[LocationCode]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by entities
	DECLARE @entities TABLE ([Code] NVARCHAR(MAX));
	INSERT @entities SELECT DISTINCT E.[Code]
	FROM [Common].[Generic.Entities](@predicate.query('/*/Locations/Value/Location')) X
	CROSS APPLY [Geolocation].[Location.Entity](X.[Entity]) E;
	IF (@@ROWCOUNT > 0) BEGIN
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/Locations/IsExcluded')), 0);
		DELETE X FROM @entities X WHERE X.[Code] IS NULL;
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @location SELECT * FROM @entities;
			ELSE
				INSERT @location SELECT L.[LocationCode] FROM [Geolocation].[Location] L
				WHERE L.[LocationCode] NOT IN (SELECT * FROM @entities);
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @location X WHERE X.[Code] NOT IN (SELECT * FROM @entities);
			ELSE
				DELETE X FROM @location X WHERE X.[Code] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

--	Filter by block predicate
	DECLARE 
		@blockPredicate		XML,
		@blockIsCountable	BIT,
		@blockLongs			XML,
		@blockIsFiltered	BIT,
		@blockNumber		INT;
	SELECT 
		@blockPredicate		= @predicate.query('/*/BlockPredicate'),
		@blockIsCountable	= 0,
		@blockIsFiltered	= @predicate.exist('/*/BlockPredicate/*');
	IF (@blockIsFiltered = 1) BEGIN
		DECLARE @block TABLE
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
			@predicate		= @blockPredicate,
			@isCountable	= @blockIsCountable,
			@longs			= @blockLongs		OUTPUT,
			@isExcluded		= @isExcluded		OUTPUT,
			@isFiltered		= @blockIsFiltered	OUTPUT,
			@number			= @blockNumber		OUTPUT;
		INSERT @block
		SELECT 
			LTRIM(X.[Entity].value('(IpNumberFrom/text())[1]',	'BIGINT')) [IpNumberFrom],
			LTRIM(X.[Entity].value('(IpNumberTo/text())[1]',	'BIGINT')) [IpNumberTo]
		FROM @blockLongs.nodes('/*/long') X ([Entity]);
		IF (@blockIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @location SELECT DISTINCT B.[BlockLocationCode] FROM [Geolocation].[Block] B
					INNER JOIN	@block	X	ON	B.[BlockIpNumberFrom]	= X.[IpNumberFrom]	AND
												B.[BlockIpNumberTo]		= X.[IpNumberTo];
				ELSE
					INSERT @location SELECT DISTINCT B.[BlockLocationCode] FROM [Geolocation].[Block] B
					LEFT JOIN	@block	X	ON	B.[BlockIpNumberFrom]	= X.[IpNumberFrom]	AND
												B.[BlockIpNumberTo]		= X.[IpNumberTo]
					WHERE COALESCE(X.[IpNumberFrom], X.[IpNumberTo]) IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @location	X
					LEFT JOIN
					(
						SELECT DISTINCT B.[BlockLocationCode] FROM [Geolocation].[Block] B
						INNER JOIN	@block	X	ON	B.[BlockIpNumberFrom]	= X.[IpNumberFrom]	AND
													B.[BlockIpNumberTo]		= X.[IpNumberTo]
					)	B	ON	X.[Code]	= B.[BlockLocationCode]
					WHERE B.[BlockLocationCode] IS NULL;
				ELSE
					DELETE X FROM @location	X
					LEFT JOIN
					(
						SELECT DISTINCT B.[BlockLocationCode] FROM [Geolocation].[Block] B
						LEFT JOIN	@block	X	ON	B.[BlockIpNumberFrom]	= X.[IpNumberFrom]	AND
													B.[BlockIpNumberTo]		= X.[IpNumberTo]
						WHERE COALESCE(X.[IpNumberFrom], X.[IpNumberTo]) IS NULL
					)	B	ON	X.[Code]	= B.[BlockLocationCode]
					WHERE B.[BlockLocationCode] IS NULL;
			SET @isFiltered = 1;
		END
	END

	SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/IsExcluded')), 0);

	SET @strings = (SELECT X.[Code] [string] FROM @location X FOR XML PATH(''), ROOT('Strings'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Geolocation].[Location] L;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @location X;
		ELSE
			SELECT @number = COUNT(*) FROM [Geolocation].[Location] L
			LEFT JOIN	@location	X	ON	L.[LocationCode] = X.[Code]
			WHERE X.[Code] IS NULL;

END
GO
