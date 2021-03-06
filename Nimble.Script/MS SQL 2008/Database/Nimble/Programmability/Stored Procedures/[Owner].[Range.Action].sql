SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner'	AND
			O.[type]	= 'P'		AND
			O.[name]	= 'Range.Action'))
	DROP PROCEDURE [Owner].[Range.Action];
GO

CREATE PROCEDURE [Owner].[Range.Action]
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
		@emplacementId	UNIQUEIDENTIFIER,
		@applicationId	UNIQUEIDENTIFIER,
		@organisations	XML,
		@branches		XML,
		@isCountable	BIT,
		@guids			XML,
		@isExcluded		BIT,
		@isFiltered		BIT,
		@command		NVARCHAR(MAX);
	
	DECLARE @output TABLE ([Id] UNIQUEIDENTIFIER);
	
	CREATE TABLE [#organisations] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	CREATE TABLE [#branches] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	EXEC [Common].[GenericInput.Action] 
		@genericInput	= @genericInput,
		@permissionType = @permissionType	OUTPUT,
		@entity			= @entity			OUTPUT,
		@predicate		= @predicate		OUTPUT,
		@startNumber	= @startNumber		OUTPUT,
		@endNumber		= @endNumber		OUTPUT,
		@order			= @order			OUTPUT,
		@emplacementId	= @emplacementId	OUTPUT,
		@applicationId	= @applicationId	OUTPUT,
		@organisations	= @organisations	OUTPUT,
		@branches		= @branches			OUTPUT;
	INSERT [#organisations] SELECT * FROM [Common].[Guid.Entities](@organisations);
	INSERT [#branches] SELECT * FROM [Common].[Guid.Entities](@branches);
	
	IF (@permissionType = 'RangeCreate') BEGIN
		INSERT [Owner].[Range] 
		(
			[RangeBranchId],
			[RangeCode],
			[RangeIpDataFrom],
			[RangeIpDataTo],
			[RangeIpNumberFrom],
			[RangeIpNumberTo],
			[RangeLockedOn],
			[RangeDescription]
		)
		OUTPUT INSERTED.[RangeId] INTO @output ([Id])
		SELECT
			X.[BranchId],
			X.[Code],
			X.[IpDataFrom],
			X.[IpDataTo],
			X.[IpNumberFrom],
			X.[IpNumberTo],
			X.[LockedOn],
			X.[Description]
		FROM [Owner].[Range.Entity](@entity) X;
		SELECT R.* FROM [Owner].[Entity.Range]	R
		INNER JOIN	@output						X	ON	R.[RangeId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'RangeRead') BEGIN
		SELECT R.* FROM [Owner].[Entity.Range]		R
		INNER JOIN	[Owner].[Range.Entity](@entity)	X	ON	R.[RangeId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'RangeUpdate') BEGIN
		UPDATE R SET 
			R.[RangeCode]			= X.[Code],
			R.[RangeIpDataFrom]		= X.[IpDataFrom],
			R.[RangeIpDataTo]		= X.[IpDataTo],
			R.[RangeIpNumberFrom]	= X.[IpNumberFrom],
			R.[RangeIpNumberTo]		= X.[IpNumberTo],
			R.[RangeLockedOn]		= X.[LockedOn],
			R.[RangeDescription]	= X.[Description]
		OUTPUT INSERTED.[RangeId] INTO @output ([Id])
		FROM [Owner].[Range]						R
		INNER JOIN	[Owner].[Range.Entity](@entity)	X	ON	R.[RangeId]			= X.[Id]	AND
															R.[RangeVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT R.* FROM [Owner].[Entity.Range]	R
		INNER JOIN	@output						X	ON	R.[RangeId]	= X.[Id];
	END

	IF (@permissionType = 'RangeDelete') BEGIN
		DELETE R FROM [Owner].[Range]				R
		INNER JOIN	[Owner].[Range.Entity](@entity)	X	ON	R.[RangeId]			= X.[Id]	AND
															R.[RangeVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
	END
	
	IF (@permissionType = 'RangeSearch') BEGIN
		CREATE TABLE [#range] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner].[Range.Filter]
			@predicate,
			@emplacementId,
			@applicationId,
			@organisations,
			@branches,
			@isCountable,
			@guids		OUTPUT,
			@isExcluded OUTPUT,
			@isFiltered OUTPUT,
			@number		OUTPUT',
			N'@predicate	XML,
			@emplacementId	UNIQUEIDENTIFIER,
			@applicationId	UNIQUEIDENTIFIER,
			@organisations	XML,
			@branches		XML,
			@isCountable	BIT,
			@guids			XML OUTPUT,
			@isExcluded		BIT OUTPUT,
			@isFiltered		BIT OUTPUT,
			@number			INT OUTPUT',
			@predicate		= @predicate,
			@emplacementId	= @emplacementId,
			@applicationId	= @applicationId,
			@organisations	= @organisations,
			@branches		= @branches,
			@isCountable	= @isCountable,
			@guids			= @guids		OUTPUT,
			@isExcluded		= @isExcluded	OUTPUT,
			@isFiltered		= @isFiltered	OUTPUT,
			@number			= @number		OUTPUT;
		INSERT [#range] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [RangeBranchId] ASC, [RangeCode] ASC ');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT R.* FROM [Owner].[Entity.Range]				R
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT R.* FROM [#range]						X
					INNER JOIN	[Owner].[Entity.Range]				R	ON	X.[Id]				= R.[RangeId]
					';
				ELSE
					IF (@branches IS NOT NULL)
						SET @command = '
						SELECT R.* FROM [Owner].[Entity.Range]		R
						INNER JOIN	[#branches]						XB	ON	R.[BranchId]		= XB.[Id]
						LEFT JOIN	[#range]						X	ON	R.[RangeId]			= X.[Id]
						WHERE 
							' + ISNULL('R.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
							X.[Id] IS NULL
						';
					ELSE
						IF (@organisations IS NULL)
							SET @command = '
							SELECT R.* FROM [Owner].[Entity.Range]	R
							LEFT JOIN	[#range]					X	ON	R.[RangeId]			= X.[Id]
							WHERE 
								' + ISNULL('R.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
								X.[Id] IS NULL
							';
						ELSE
							SET @command = '
							SELECT R.* FROM [Owner].[Entity.Range]	R
							INNER JOIN	[#organisations]			XO	ON	R.[OrganisationId]	= XO.[Id]
							LEFT JOIN	[#range]					X	ON	R.[RangeId]			= X.[Id]
							WHERE 
								' + ISNULL('R.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
								X.[Id] IS NULL
							';
			SET @command = @command + @order;
		END
		ELSE BEGIN
			IF (@isFiltered = 0)
				SET @command = '
				SELECT * FROM
				(
					SELECT 
						R.*, 
						ROW_NUMBER() OVER(' + @order + ') [Number]
					FROM [Owner].[Entity.Range]						R
				)	R
				WHERE R.[Number] BETWEEN
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							R.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [#range]								X
						INNER JOIN	[Owner].[Entity.Range]			R	ON	X.[Id]				= R.[RangeId]
					)	R
					WHERE R.[Number] BETWEEN
					';
				ELSE
					IF (@branches IS NOT NULL)
						SET @command = '
						SELECT * FROM
						(
							SELECT 
								R.*, 
								ROW_NUMBER() OVER(' + @order + ') [Number]
							FROM [Owner].[Entity.Range]				R
							INNER JOIN	[#branches]					XB	ON	R.[BranchId]		= XB.[Id]
							LEFT JOIN	[#range]					X	ON	R.[RangeId]			= X.[Id]
							WHERE 
								' + ISNULL('R.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
								X.[Id] IS NULL
						)	B
						WHERE B.[Number] BETWEEN
						';
					ELSE
						IF (@organisations IS NULL)
							SET @command = '
							SELECT * FROM
							(
								SELECT 
									R.*, 
									ROW_NUMBER() OVER(' + @order + ') [Number]
								FROM [Owner].[Entity.Range]			R
								LEFT JOIN	[#range]				X	ON	R.[RangeId]			= X.[Id]
								WHERE 
									' + ISNULL('R.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
									X.[Id] IS NULL
							)	R
							WHERE R.[Number] BETWEEN
							';
						ELSE
							SET @command = '
							SELECT * FROM
							(
								SELECT 
									R.*, 
									ROW_NUMBER() OVER(' + @order + ') [Number]
								FROM [Owner].[Entity.Range]			R
								INNER JOIN	[#organisations]		XO	ON	R.[OrganisationId]	= XO.[Id]
								LEFT JOIN	[#range]				X	ON	R.[RangeId]			= X.[Id]
								WHERE 
									' + ISNULL('R.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
									X.[Id] IS NULL
							)	R
							WHERE R.[Number] BETWEEN
							';
			SET @command = @command + CAST(@startNumber AS NVARCHAR(MAX)) + ' AND ' + CAST(@endNumber AS NVARCHAR(MAX));
		END
		EXEC sp_executesql @command;
	END

END
GO
