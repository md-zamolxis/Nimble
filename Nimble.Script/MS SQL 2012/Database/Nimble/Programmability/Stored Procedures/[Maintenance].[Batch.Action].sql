SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Maintenance'	AND
			O.[type]	= 'P'			AND
			O.[name]	= 'Batch.Action'))
	DROP PROCEDURE [Maintenance].[Batch.Action];
GO

CREATE PROCEDURE [Maintenance].[Batch.Action]
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
	
	IF (@permissionType = 'BatchCreate') BEGIN
		DECLARE 
			@batchStart				DATETIMEOFFSET,
			@batchEnd				DATETIMEOFFSET,
			@batchBefore			INT,
			@batchAfter				INT,
			@operationStart			DATETIMEOFFSET,
			@operationEnd			DATETIMEOFFSET,
			@operationBefore		INT,
			@operationAfter			INT,
			@operationResults		XML,
			@name					VARCHAR(MAX),
			@tableSchema			NVARCHAR(MAX),
			@tableName				NVARCHAR(MAX),
			@maximumFragmentation	DECIMAL(28, 9),
			@objectId				INT,
			@indexName				NVARCHAR(MAX),
			@logicalFragmentation	DECIMAL(28, 9),
			@recoveryModel			NVARCHAR(MAX),
			@logicalFileName		VARCHAR(MAX),
			@results				NVARCHAR(MAX);
		DECLARE @operations TABLE 
		(
			[BatchId]				UNIQUEIDENTIFIER,
			[Code]					INT,
			[OperationTuningType]	NVARCHAR(MAX),
			[Start]					DATETIMEOFFSET,
			[End]					DATETIMEOFFSET,
			[Before]				INT,
			[After]					INT,
			[Results]				XML
		);
--	Checkpoint
		SET @batchStart = SYSDATETIMEOFFSET();
		EXEC [Maintenance].[Database.Size] 
			@name	= @name				OUTPUT, 
			@size	= @batchBefore		OUTPUT;
		SELECT
			@operationStart		= @batchStart,
			@operationBefore	= @batchBefore;
		CHECKPOINT;
		SET @operationEnd = SYSDATETIMEOFFSET();
		EXEC [Maintenance].[Database.Size] 
			@name	= @name				OUTPUT, 
			@size	= @operationAfter	OUTPUT;
		INSERT @operations 
		(
			[Code],
			[OperationTuningType],
			[Start],
			[End],
			[Before],
			[After]
		) 
		VALUES 
		(
			1,
			'CHECKPOINT',
			@operationStart,
			@operationEnd,
			@operationBefore,
			@operationAfter
		);
--	UpdateUsage
		SET @operationStart = SYSDATETIMEOFFSET();
		EXEC [Maintenance].[Database.Size] 
			@name	= @name				OUTPUT, 
			@size	= @operationBefore	OUTPUT;
		DBCC UPDATEUSAGE(@name) WITH NO_INFOMSGS;
		SET @operationEnd = SYSDATETIMEOFFSET();
		EXEC [Maintenance].[Database.Size] 
			@name	= @name				OUTPUT, 
			@size	= @operationAfter	OUTPUT;
		INSERT @operations 
		(
			[Code],
			[OperationTuningType],
			[Start],
			[End],
			[Before],
			[After]
		) 
		VALUES 
		(
			2,
			'UPDATEUSAGE',
			@operationStart,
			@operationEnd,
			@operationBefore,
			@operationAfter
		);
--	ShowContig
		SET @operationStart = SYSDATETIMEOFFSET();
		EXEC [Maintenance].[Database.Size] 
			@name	= @name				OUTPUT, 
			@size	= @operationBefore	OUTPUT;
		DECLARE @showContigs TABLE 
		(
			[ObjectName]			NVARCHAR(MAX),
			[ObjectId]				INT,
			[IndexName]				NVARCHAR(MAX),
			[IndexId]				INT,
			[Level]					INT,
			[Pages]					INT,
			[Rows]					INT,
			[MinimumRecordSize]		INT,
			[MaximumRecordSize]		INT,
			[AverageRecordSize]		INT,
			[ForwardedRecords]		INT,
			[Extents]				INT,
			[ExtentSwitches]		INT,
			[AverageFreeBytes]		INT,
			[AveragePageDensity]	INT,
			[ScanDensity]			DECIMAL(28, 9),
			[BestCount]				INT,
			[ActualtCount]			INT,
			[LogicalFragmentation]	DECIMAL(28, 9),
			[ExtentFragmentation]	DECIMAL(28, 9)
		);
		DECLARE databaseTables CURSOR FOR
		SELECT 
			IST.[TABLE_SCHEMA], 
			IST.[TABLE_NAME]
		FROM [INFORMATION_SCHEMA].[TABLES] IST
		WHERE TABLE_TYPE = 'BASE TABLE';
		OPEN databaseTables;
		FETCH NEXT FROM databaseTables INTO 
			@tableSchema, 
			@tableName;
		WHILE @@FETCH_STATUS = 0 BEGIN
			SELECT @command = 'DBCC SHOWCONTIG(''[' + @tableSchema + '].[' + @tableName + ']'') WITH FAST, TABLERESULTS, ALL_INDEXES, NO_INFOMSGS';
			INSERT INTO @showContigs EXEC (@command);
			UPDATE SC SET SC.[ObjectName] = '[' + @tableSchema + '].[' + @tableName + ']' 
			FROM @showContigs SC WHERE SC.[ObjectName] = @tableName;
			FETCH NEXT FROM databaseTables INTO 
				@tableSchema, 
				@tableName;
		END
		CLOSE databaseTables;
		DEALLOCATE databaseTables;
		SET @operationResults = (SELECT * FROM @showContigs FOR XML RAW('ShowContig'), ELEMENTS);
		SET @operationEnd = SYSDATETIMEOFFSET();
		EXEC [Maintenance].[Database.Size] 
			@name	= @name				OUTPUT, 
			@size	= @operationAfter	OUTPUT;
		INSERT @operations 
		(
			[Code],
			[OperationTuningType],
			[Start],
			[End],
			[Before],
			[After],
			[Results]
		) 
		VALUES 
		(
			3,
			'SHOWCONTIG',
			@operationStart,
			@operationEnd,
			@operationBefore,
			@operationAfter,
			@operationResults
		);
--	DbReindex
		SET @operationStart = SYSDATETIMEOFFSET();
		EXEC [Maintenance].[Database.Size] 
			@name	= @name				OUTPUT, 
			@size	= @operationBefore	OUTPUT;
		SELECT @maximumFragmentation = X.[MaximumFragmentation] FROM [Maintenance].[Batch.Entity](@entity) X;
		SET @maximumFragmentation = ISNULL(@maximumFragmentation, 30);
		DECLARE databaseIndexes CURSOR FOR
		SELECT 
			SC.[ObjectName],
			SC.[ObjectId],
			SC.[IndexName],
			SC.[LogicalFragmentation]
		FROM @showContigs SC
		WHERE 
			SC.[LogicalFragmentation] >= @maximumFragmentation	AND
			INDEXPROPERTY(SC.[ObjectId], SC.[IndexName], 'IndexDepth') > 0;
		SET @results = '<string>Re-index database indexes, fragmented more than ' + RTRIM(CAST(@maximumFragmentation AS NVARCHAR(MAX))) + '%.</string>';
		OPEN databaseIndexes;
		FETCH NEXT FROM databaseIndexes INTO 
			@tableName, 
			@objectId, 
			@indexName, 
			@logicalFragmentation;
		WHILE @@FETCH_STATUS = 0 BEGIN
			SET @results = @results + '<string>Re-index [' + RTRIM(@indexName) + '] of [' + RTRIM(@indexName) + '] table, fragmented at ' + RTRIM(CAST(@logicalFragmentation AS NVARCHAR(MAX))) + '%.</string>';
			SET @command = 'DBCC DBREINDEX(''' + RTRIM(@tableName) + ''', ''' + RTRIM(@indexName) + ''', 0) WITH NO_INFOMSGS';
			EXEC (@command);
			FETCH NEXT FROM databaseIndexes INTO 
				@tableName, 
				@objectId, 
				@indexName, 
				@logicalFragmentation;
		END
		CLOSE databaseIndexes;
		DEALLOCATE databaseIndexes;
		SET @operationResults = CAST(@results AS XML);
		SET @operationEnd = SYSDATETIMEOFFSET();
		EXEC [Maintenance].[Database.Size] 
			@name	= @name				OUTPUT, 
			@size	= @operationAfter	OUTPUT;
		INSERT @operations 
		(
			[Code],
			[OperationTuningType],
			[Start],
			[End],
			[Before],
			[After],
			[Results]
		) 
		VALUES 
		(
			4,
			'DBREINDEX',
			@operationStart,
			@operationEnd,
			@operationBefore,
			@operationAfter,
			@operationResults
		);
--	ShrinkDatabase
		SET @operationStart = SYSDATETIMEOFFSET();
		EXEC [Maintenance].[Database.Size] 
			@name	= @name				OUTPUT, 
			@size	= @operationBefore	OUTPUT;
		DBCC SHRINKDATABASE(@name, 0) WITH NO_INFOMSGS;
		SET @operationEnd = SYSDATETIMEOFFSET();
		EXEC [Maintenance].[Database.Size] 
			@name	= @name				OUTPUT, 
			@size	= @operationAfter	OUTPUT;
		INSERT @operations 
		(
			[Code],
			[OperationTuningType],
			[Start],
			[End],
			[Before],
			[After]
		) 
		VALUES 
		(
			5,
			'SHRINKDATABASE',
			@operationStart,
			@operationEnd,
			@operationBefore,
			@operationAfter
		);
--	BackupLog
		IF ((SELECT CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(MAX))) LIKE '9%') BEGIN 
			SET @operationStart = SYSDATETIMEOFFSET();
			EXEC [Maintenance].[Database.Size] 
				@name	= @name				OUTPUT, 
				@size	= @operationBefore	OUTPUT;
			CHECKPOINT;
			SET @command = 'BACKUP LOG [' + @name + '] WITH TRUNCATE_ONLY';
			EXEC (@command);
			SET @operationEnd = SYSDATETIMEOFFSET();
			EXEC [Maintenance].[Database.Size] 
				@name	= @name				OUTPUT, 
				@size	= @operationAfter	OUTPUT;
			INSERT @operations 
			(
				[Code],
				[OperationTuningType],
				[Start],
				[End],
				[Before],
				[After]
			) 
			VALUES 
			(
				6,
				'BACKUPLOG',
				@operationStart,
				@operationEnd,
				@operationBefore,
				@operationAfter
			);
		END
--	ShrinkFile
		SET @operationStart = SYSDATETIMEOFFSET();
		EXEC [Maintenance].[Database.Size] 
			@name	= @name				OUTPUT, 
			@size	= @operationBefore	OUTPUT;
		SELECT @recoveryModel = D.[recovery_model_desc] FROM [sys].[databases] D WHERE D.[name] = @name;
		SET @command = 'ALTER DATABASE [' + @name + '] SET RECOVERY SIMPLE';
		EXEC (@command);
		CHECKPOINT;
		SELECT @logicalFileName = DF.[name] FROM [sys].[database_files] DF WHERE DF.[type] = 0;
		DBCC SHRINKFILE(@logicalFileName, TRUNCATEONLY) WITH NO_INFOMSGS;
		SELECT @logicalFileName = DF.[name] FROM [sys].[database_files] DF WHERE DF.[type] = 1;
		DBCC SHRINKFILE(@logicalFileName, TRUNCATEONLY) WITH NO_INFOMSGS;
		SET @command = 'ALTER DATABASE [' + @name + '] SET RECOVERY ' + @recoveryModel;
		EXEC (@command);
		SET @operationEnd = SYSDATETIMEOFFSET();
		EXEC [Maintenance].[Database.Size] 
			@name	= @name				OUTPUT, 
			@size	= @operationAfter	OUTPUT;
		INSERT @operations 
		(
			[Code],
			[OperationTuningType],
			[Start],
			[End],
			[Before],
			[After]
		) 
		VALUES 
		(
			7,
			'SHRINKFILE',
			@operationStart,
			@operationEnd,
			@operationBefore,
			@operationAfter
		);
--	UpdateStatistics
		SET @operationStart = SYSDATETIMEOFFSET();
		EXEC [Maintenance].[Database.Size] 
			@name	= @name				OUTPUT, 
			@size	= @operationBefore	OUTPUT;
		EXEC sp_updatestats;
		SET @operationEnd = SYSDATETIMEOFFSET();
		EXEC [Maintenance].[Database.Size] 
			@name	= @name				OUTPUT, 
			@size	= @operationAfter	OUTPUT;
		INSERT @operations 
		(
			[Code],
			[OperationTuningType],
			[Start],
			[End],
			[Before],
			[After]
		) 
		VALUES 
		(
			8,
			'UPDATESTATISTICS',
			@operationStart,
			@operationEnd,
			@operationBefore,
			@operationAfter
		);
--	Save data
		SELECT
			@batchEnd	= @operationEnd,
			@batchAfter	= @operationAfter;
		INSERT [Maintenance].[Batch] 
		(
			[BatchStart],
			[BatchEnd],
			[BatchBefore],
			[BatchAfter]
		)
		OUTPUT INSERTED.[BatchId] INTO @output ([Id])
		VALUES 
		( 
			@batchStart,
			@batchEnd,
			@batchBefore,
			@batchAfter
		);
		SET @number = @@ROWCOUNT;
		UPDATE O SET O.[BatchId] = X.[Id] FROM @operations O, @output X;
		INSERT [Maintenance].[Operation] 
		(
			[OperationBatchId],
			[OperationCode],
			[OperationTuningType],
			[OperationStart],
			[OperationEnd],
			[OperationBefore],
			[OperationAfter],
			[OperationResults]
		)
		SELECT * FROM @operations O;
		SELECT B.* FROM [Maintenance].[Batch]				B
		INNER JOIN	@output									X	ON	B.[BatchId]				= X.[Id];
	END
	
	IF (@permissionType = 'BatchRead') BEGIN
		SELECT B.* FROM [Maintenance].[Batch]				B
		INNER JOIN	[Maintenance].[Batch.Entity](@entity)	X	ON	B.[BatchId]				= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	CREATE TABLE [#batch] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);

	IF (@permissionType = 'BatchDelete') BEGIN
		EXEC [Maintenance].[Batch.Filter]
			@predicate		= @predicate,
			@emplacementId	= @emplacementId,
			@applicationId	= @applicationId,
			@isExcluded		= @isExcluded	OUTPUT,
			@isFiltered		= @isFiltered	OUTPUT,
			@number			= @number		OUTPUT;
		BEGIN TRANSACTION;
		BEGIN TRY
			DELETE O FROM [Maintenance].[Operation]			O
			INNER JOIN	[#batch]							X	ON	O.[OperationBatchId]	= [Id];
			DELETE B FROM [Maintenance].[Batch]				B
			INNER JOIN	[#batch]							X	ON	B.[BatchId]				= X.[Id];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END
	
	IF (@permissionType = 'BatchSearch') BEGIN
		EXEC sp_executesql 
			N'EXEC [Maintenance].[Batch.Filter]
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
		INSERT [#batch] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [BatchStart] DESC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT B.* FROM [Maintenance].[Batch]		B
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT B.* FROM [#batch]				X
				INNER JOIN	[Maintenance].[Batch]		B	ON	X.[Id]		= B.[BatchId]
				';
			ELSE
				SET @command = '
				SELECT B.* FROM [Maintenance].[Batch]	B
				LEFT JOIN	[#batch]					X	ON	B.[BatchId]	= X.[Id]
				WHERE X.[Id] IS NULL
				';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
