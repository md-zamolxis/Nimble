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
			O.[name]	= 'Block.Filter'))
	DROP PROCEDURE [Geolocation].[Block.Filter];
GO

CREATE PROCEDURE [Geolocation].[Block.Filter]
(
	@predicate		XML,
	@isCountable	BIT			= NULL,
	@longs			XML	OUTPUT,
	@isExcluded		BIT	OUTPUT,
	@isFiltered		BIT	OUTPUT,
	@number			INT	OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;

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
	
	SET @isFiltered = 0;

--	Filter by IP numbers
	DECLARE @ipNumbers TABLE ([IpNumber] BIGINT);
	INSERT @ipNumbers SELECT DISTINCT * FROM [Common].[Long.Entities](@predicate.query('/*/IpNumbers/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/IpNumbers/IsExcluded')), 0);
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @block SELECT 
					B.[BlockIpNumberFrom],
					B.[BlockIpNumberTo]
				FROM [Geolocation].[Block]	B
				INNER JOIN	@ipNumbers		X	ON	X.[IpNumber]	BETWEEN B.[BlockIpNumberFrom] AND B.[BlockIpNumberTo];
			ELSE
				INSERT @block SELECT 
					B.[BlockIpNumberFrom],
					B.[BlockIpNumberTo]
				FROM [Geolocation].[Block]	B
				LEFT JOIN	@ipNumbers		X	ON	X.[IpNumber]	BETWEEN B.[BlockIpNumberFrom] AND B.[BlockIpNumberTo]
				WHERE X.[IpNumber] IS NULL;
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @block	X 
				LEFT JOIN
				(
					SELECT 
						B.[BlockIpNumberFrom],
						B.[BlockIpNumberTo]
					FROM [Geolocation].[Block]	B
					INNER JOIN	@ipNumbers		X	ON	X.[IpNumber]	BETWEEN B.[BlockIpNumberFrom] AND B.[BlockIpNumberTo]
				)	B	ON	X.[IpNumberFrom]	= B.[BlockIpNumberFrom]	AND
							X.[IpNumberTo]		= B.[BlockIpNumberTo]
				WHERE COALESCE(B.[BlockIpNumberFrom], B.[BlockIpNumberTo]) IS NULL;
			ELSE
				DELETE X FROM @block	X 
				LEFT JOIN
				(
					SELECT 
						B.[BlockIpNumberFrom],
						B.[BlockIpNumberTo]
					FROM [Geolocation].[Block]	B
					LEFT JOIN	@ipNumbers		X	ON	X.[IpNumber]	BETWEEN B.[BlockIpNumberFrom] AND B.[BlockIpNumberTo]
					WHERE X.[IpNumber] IS NULL
				)	B	ON	X.[IpNumberFrom]	= B.[BlockIpNumberFrom]	AND
							X.[IpNumberTo]		= B.[BlockIpNumberTo]
				WHERE COALESCE(B.[BlockIpNumberFrom], B.[BlockIpNumberTo]) IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by IP data from
	DECLARE @ipDataFrom TABLE ([IpDataFrom] NVARCHAR(MAX));
	INSERT @ipDataFrom SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/IpDataFrom/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/IpDataFrom/IsExcluded')), 0);
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @block SELECT 
					B.[BlockIpNumberFrom],
					B.[BlockIpNumberTo]
				FROM [Geolocation].[Block]	B
				INNER JOIN	@ipDataFrom		X	ON	B.[BlockIpDataFrom]	LIKE X.[IpDataFrom];
			ELSE
				INSERT @block SELECT 
					B.[BlockIpNumberFrom],
					B.[BlockIpNumberTo]
				FROM [Geolocation].[Block]	B
				LEFT JOIN	@ipDataFrom		X	ON	B.[BlockIpDataFrom]	LIKE X.[IpDataFrom]
				WHERE X.[IpDataFrom] IS NULL;
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @block	X 
				LEFT JOIN
				(
					SELECT 
						B.[BlockIpNumberFrom],
						B.[BlockIpNumberTo]
					FROM [Geolocation].[Block]	B
					INNER JOIN	@ipDataFrom		X	ON	B.[BlockIpDataFrom]	LIKE X.[IpDataFrom]
				)	B	ON	X.[IpNumberFrom]	= B.[BlockIpNumberFrom]	AND
							X.[IpNumberTo]		= B.[BlockIpNumberTo]
				WHERE COALESCE(B.[BlockIpNumberFrom], B.[BlockIpNumberTo]) IS NULL;
			ELSE
				DELETE X FROM @block	X 
				LEFT JOIN
				(
					SELECT 
						B.[BlockIpNumberFrom],
						B.[BlockIpNumberTo]
					FROM [Geolocation].[Block]	B
					LEFT JOIN	@ipDataFrom		X	ON	B.[BlockIpDataFrom]	LIKE X.[IpDataFrom]
					WHERE X.[IpDataFrom] IS NULL
				)	B	ON	X.[IpNumberFrom]	= B.[BlockIpNumberFrom]	AND
							X.[IpNumberTo]		= B.[BlockIpNumberTo]
				WHERE COALESCE(B.[BlockIpNumberFrom], B.[BlockIpNumberTo]) IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by IP data to
	DECLARE @ipDataTo TABLE ([IpDataTo] NVARCHAR(MAX));
	INSERT @ipDataTo SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/IpDataTo/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/IpDataTo/IsExcluded')), 0);
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @block SELECT 
					B.[BlockIpNumberFrom],
					B.[BlockIpNumberTo]
				FROM [Geolocation].[Block]	B
				INNER JOIN	@ipDataTo		X	ON	B.[BlockIpDataTo]	LIKE X.[IpDataTo];
			ELSE
				INSERT @block SELECT 
					B.[BlockIpNumberFrom],
					B.[BlockIpNumberTo]
				FROM [Geolocation].[Block]	B
				LEFT JOIN	@ipDataTo		X	ON	B.[BlockIpDataTo]	LIKE X.[IpDataTo]
				WHERE X.[IpDataTo] IS NULL;
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @block	X 
				LEFT JOIN
				(
					SELECT 
						B.[BlockIpNumberFrom],
						B.[BlockIpNumberTo]
					FROM [Geolocation].[Block]	B
					INNER JOIN	@ipDataTo		X	ON	B.[BlockIpDataTo]	LIKE X.[IpDataTo]
				)	B	ON	X.[IpNumberFrom]	= B.[BlockIpNumberFrom]	AND
							X.[IpNumberTo]		= B.[BlockIpNumberTo]
				WHERE COALESCE(B.[BlockIpNumberFrom], B.[BlockIpNumberTo]) IS NULL;
			ELSE
				DELETE X FROM @block	X 
				LEFT JOIN
				(
					SELECT 
						B.[BlockIpNumberFrom],
						B.[BlockIpNumberTo]
					FROM [Geolocation].[Block]	B
					LEFT JOIN	@ipDataTo		X	ON	B.[BlockIpDataTo]	LIKE X.[IpDataTo]
					WHERE X.[IpDataTo] IS NULL
				)	B	ON	X.[IpNumberFrom]	= B.[BlockIpNumberFrom]	AND
							X.[IpNumberTo]		= B.[BlockIpNumberTo]
				WHERE COALESCE(B.[BlockIpNumberFrom], B.[BlockIpNumberTo]) IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by entities
	DECLARE @entities TABLE 
	(
		[IpNumberFrom]	BIGINT,
		[IpNumberTo]	BIGINT
	);
	INSERT @entities SELECT DISTINCT 
		E.[IpNumberFrom],
		E.[IpNumberTo]
	FROM [Common].[Generic.Entities](@predicate.query('/*/Blocks/Value/Block')) X
	CROSS APPLY [Geolocation].[Block.Entity](X.[Entity]) E;
	IF (@@ROWCOUNT > 0) BEGIN
		SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/Blocks/IsExcluded')), 0);
		DELETE X FROM @entities X WHERE X.[IpNumberFrom]*X.[IpNumberTo] IS NULL;
		IF (@isFiltered = 0)
			IF (@isExcluded = 0)
				INSERT @block SELECT * FROM @entities;
			ELSE
				INSERT @block SELECT 
					B.[BlockIpNumberFrom],
					B.[BlockIpNumberTo]
				FROM [Geolocation].[Block]	B
				LEFT JOIN	@entities		E	ON	B.[BlockIpNumberFrom]	= E.[IpNumberFrom]	AND
													B.[BlockIpNumberTo]		= E.[IpNumberTo]
				WHERE COALESCE(E.[IpNumberFrom], E.[IpNumberTo]) IS NULL;
		ELSE
			IF (@isExcluded = 0)
				DELETE X FROM @block	X 
				LEFT JOIN	@entities	E	ON	X.[IpNumberFrom]	= E.[IpNumberFrom]	AND
												X.[IpNumberTo]		= E.[IpNumberTo]
				WHERE COALESCE(E.[IpNumberFrom], E.[IpNumberTo]) IS NULL;
			ELSE
				DELETE X FROM @block	X 
				INNER JOIN	@entities	E	ON	X.[IpNumberFrom]	= E.[IpNumberFrom]	AND
												X.[IpNumberTo]		= E.[IpNumberTo];
		SET @isFiltered = 1;
	END

--	Filter by location predicate
	DECLARE 
		@locationPredicate		XML,
		@locationIsCountable	BIT,
		@locationStrings		XML,
		@locationIsFiltered		BIT,
		@locationNumber			INT;
	SELECT 
		@locationPredicate		= @predicate.query('/*/LocationPredicate'),
		@locationIsCountable	= 0,
		@locationIsFiltered		= @predicate.exist('/*/LocationPredicate/*');
	IF (@locationIsFiltered = 1) BEGIN
		DECLARE @location TABLE ([Code] INT PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Geolocation].[Location.Filter]
			@predicate,
			@isCountable,
			@strings	OUTPUT,
			@isExcluded OUTPUT,
			@isFiltered OUTPUT,
			@number		OUTPUT',
			N'@predicate	XML,
			@isCountable	BIT,
			@strings		XML OUTPUT,
			@isExcluded		BIT OUTPUT,
			@isFiltered		BIT OUTPUT,
			@number			INT OUTPUT',
			@predicate		= @locationPredicate,
			@isCountable	= @locationIsCountable,
			@strings		= @locationStrings		OUTPUT,
			@isExcluded		= @isExcluded			OUTPUT,
			@isFiltered		= @locationIsFiltered	OUTPUT,
			@number			= @locationNumber		OUTPUT;
		INSERT @location SELECT * FROM [Common].[String.Entities](@locationStrings);
		IF (@locationIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @block SELECT 
						B.[BlockIpNumberFrom],
						B.[BlockIpNumberTo]
					FROM [Geolocation].[Block]	B
					INNER JOIN	@location		X	ON	B.[BlockLocationCode]	= X.[Code];
				ELSE
					INSERT @block SELECT 
						B.[BlockIpNumberFrom],
						B.[BlockIpNumberTo]
					FROM [Geolocation].[Block]	B
					LEFT JOIN	@location		X	ON	B.[BlockLocationCode]	= X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @block	X
					LEFT JOIN
					(
						SELECT 
							B.[BlockIpNumberFrom],
							B.[BlockIpNumberTo]
						FROM [Geolocation].[Block]	B
						INNER JOIN	@location		X	ON	B.[BlockLocationCode]	= X.[Code]
					)	B	ON	X.[IpNumberFrom]	= B.[BlockIpNumberFrom]	AND
								X.[IpNumberTo]		= B.[BlockIpNumberTo]
					WHERE COALESCE(B.[BlockIpNumberFrom], B.[BlockIpNumberTo]) IS NULL;
				ELSE
					DELETE X FROM @block	X
					LEFT JOIN
					(
						SELECT 
							B.[BlockIpNumberFrom],
							B.[BlockIpNumberTo]
						FROM [Geolocation].[Block]	B
						LEFT JOIN	@location		X	ON	B.[BlockLocationCode]	= X.[Code]
						WHERE X.[Code] IS NULL
					)	B	ON	X.[IpNumberFrom]	= B.[BlockIpNumberFrom]	AND
								X.[IpNumberTo]		= B.[BlockIpNumberTo]
					WHERE COALESCE(B.[BlockIpNumberFrom], B.[BlockIpNumberTo]) IS NULL;
			SET @isFiltered = 1;
		END
	END

	SET @isExcluded = ISNULL([Common].[Bool.Entity](@predicate.query('/*/IsExcluded')), 0);

	SET @longs = (SELECT * FROM @block X FOR XML PATH('long'), ROOT('Longs'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Geolocation].[Block] B;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @block X;
		ELSE
			SELECT @number = COUNT(*) FROM [Geolocation].[Block] B
			LEFT JOIN	@block	X	ON	B.[BlockIpNumberFrom]	= X.[IpNumberFrom]	AND
										B.[BlockIpNumberTo]		= X.[IpNumberTo]
			WHERE COALESCE(X.[IpNumberFrom], X.[IpNumberTo]) IS NULL;

END
GO
