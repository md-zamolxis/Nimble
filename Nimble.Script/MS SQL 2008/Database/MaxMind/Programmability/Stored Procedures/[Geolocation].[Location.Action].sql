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
			O.[name]	= 'Location.Action'))
	DROP PROCEDURE [Geolocation].[Location.Action];
GO

CREATE PROCEDURE [Geolocation].[Location.Action]
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
		@strings		XML,
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
	
	IF (@permissionType = 'LocationSearch') BEGIN
		CREATE TABLE [#location] ([Code] INT PRIMARY KEY CLUSTERED);
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
			@predicate		= @predicate,
			@isCountable	= @isCountable,
			@strings		= @strings		OUTPUT,
			@isExcluded		= @isExcluded	OUTPUT,
			@isFiltered		= @isFiltered	OUTPUT,
			@number			= @number		OUTPUT;
		INSERT [#location] SELECT * FROM [Common].[String.Entities](@strings);
		SET @order = ISNULL(@order, ' ORDER BY [LocationCode] DESC ');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT L.* FROM [Geolocation].[Location]		L
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT L.* FROM [#location]					X
					INNER JOIN	[Geolocation].[Location]		L	ON	X.[Code]			= L.[LocationCode]
					';
				ELSE
					SET @command = '
					SELECT L.* FROM [Geolocation].[Location]	L
					LEFT JOIN	[#location]						X	ON	L.[LocationCode]	= X.[Code]
					WHERE X.[Code] IS NULL
					';
			SET @command = @command + @order;
		END
		ELSE BEGIN
			IF (@isFiltered = 0)
				SET @command = '
				SELECT * FROM
				(
					SELECT 
						L.*, 
						ROW_NUMBER() OVER(' + @order + ') [Number]
					FROM [Geolocation].[Location]				L
				)	L
				WHERE L.[Number] BETWEEN
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							L.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [#location]						X
						INNER JOIN	[Geolocation].[Location]	L	ON	X.[Code]			= L.[LocationCode]
					)	L
					WHERE L.[Number] BETWEEN
					';
				ELSE
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							L.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [Geolocation].[Location]			L
						LEFT JOIN	[#location]					X	ON	L.[LocationCode]	= X.[Code]
						WHERE X.[Code] IS NULL
					)	L
					WHERE L.[Number] BETWEEN
					';
			SET @command = @command + CAST(@startNumber AS NVARCHAR(MAX)) + ' AND ' + CAST(@endNumber AS NVARCHAR(MAX));
		END
		EXEC sp_executesql @command;
	END

END
GO
