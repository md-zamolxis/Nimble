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
			O.[name]	= 'Backup.Action'))
	DROP PROCEDURE [Maintenance].[Backup.Action];
GO

CREATE PROCEDURE [Maintenance].[Backup.Action]
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
		@isCountable	BIT,
		@guids			XML,
		@isExcluded		BIT,
		@isFiltered		BIT,
		@command		NVARCHAR(MAX);
	
	DECLARE @input TABLE	
	(
		[Id]			UNIQUEIDENTIFIER,
		[Start]			DATETIMEOFFSET,
		[End]			DATETIMEOFFSET,
		[Data]			INT,
		[Destination]	NVARCHAR(MAX),
		[Size]			INT
	);
	
	DECLARE @output TABLE ([Id] UNIQUEIDENTIFIER);
	
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
		@organisations	= @organisations	OUTPUT;
	
	IF (@permissionType = 'BackupCreate') BEGIN
		DECLARE 
			@databaseSize	INT,
			@databaseName	NVARCHAR(MAX),
			@destination	VARCHAR(MAX),
			@backupSize		DECIMAL(20, 0);
		EXEC [Maintenance].[Database.Size] 
			@size	= @databaseSize	OUTPUT,
			@name	= @databaseName	OUTPUT; 
		INSERT @input SELECT 
			X.[Id],
			SYSDATETIMEOFFSET(),
			X.[End],
			@databaseSize,
			X.[Destination],
			X.[Size]
		FROM [Maintenance].[Backup.Entity](@entity) X;
		SELECT @destination = X.[Destination] FROM @input X;
		IF (@destination IS NULL)
			RAISERROR 
			(
				'Cannot perform backup operation - invalid destination.', 
				16, 
				0
			);
		ELSE BEGIN
			IF ((SELECT CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(MAX))) LIKE '9%')
				SET @command = 'BACKUP DATABASE [' + @databaseName + '] TO DISK = ''' + @destination + ''' WITH INIT';
			ELSE
				SET @command = 'BACKUP DATABASE [' + @databaseName + '] TO DISK = ''' + @destination + ''' WITH INIT, CHECKSUM';
			EXEC (@command);
			SELECT @backupSize = BS.[backup_size] FROM [msdb].[dbo].[backupset]	BS 
			INNER JOIN	
			(
				SELECT 
					BS.[database_name],
					MAX(BS.[backup_finish_date]) [backup_finish_date]
				FROM [msdb].[dbo].[backupset] BS 
				GROUP BY BS.[database_name]
			)	LBS	ON	BS.[database_name]		= LBS.[database_name]	AND
						BS.[backup_finish_date]	= LBS.[backup_finish_date]
			WHERE BS.[database_name] = @databaseName;
			INSERT [Maintenance].[Backup] 
			(
				[BackupStart],
				[BackupEnd],
				[BackupData],
				[BackupDestination],
				[BackupSize]
			)
			OUTPUT INSERTED.[BackupId] INTO @output ([Id])
			SELECT 
				X.[Start],
				SYSDATETIMEOFFSET(),
				X.[Data],
				X.[Destination],
				@backupSize
			FROM @input X;
		END
		SELECT B.* FROM [Maintenance].[Backup]				B
		INNER JOIN	@output									X	ON	B.[BackupId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'BackupRead') BEGIN
		SELECT B.* FROM [Maintenance].[Backup]				B
		INNER JOIN	[Maintenance].[Backup.Entity](@entity)	X	ON	B.[BackupId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'BackupDelete' OR
		@permissionType = 'BackupSearch') 
	BEGIN
		CREATE TABLE [#backup] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Maintenance].[Backup.Filter]
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
		INSERT [#backup] SELECT * FROM [Common].[Guid.Entities](@guids);
	END

	IF (@permissionType = 'BackupDelete') BEGIN
		DELETE B FROM [Maintenance].[Backup]				B
		INNER JOIN	[#backup]								X	ON	B.[BackupId]	= X.[Id];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
	END
	
	IF (@permissionType = 'BackupSearch') BEGIN
		SET @order = ISNULL(@order, ' ORDER BY [BackupStart] DESC ');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT B.* FROM [Maintenance].[Backup]		B
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT B.* FROM [#backup]				X
					INNER JOIN	[Maintenance].[Backup]		B	ON	X.[Id]			= B.[BackupId]
					';
				ELSE
					SET @command = '
					SELECT B.* FROM [Maintenance].[Backup]	B
					LEFT JOIN	[#backup]					X	ON	B.[BackupId]	= X.[Id]
					WHERE X.[Id] IS NULL
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
					FROM [Maintenance].[Backup]				B
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
						FROM [#backup]						X
						INNER JOIN	[Maintenance].[Backup]	B	ON	X.[Id]			= B.[BackupId]
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
						FROM [Maintenance].[Backup]			B
						LEFT JOIN	[#backup]				X	ON	B.[BackupId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	B
					WHERE B.[Number] BETWEEN
					';
			SET @command = @command + CAST(@startNumber AS NVARCHAR(MAX)) + ' AND ' + CAST(@endNumber AS NVARCHAR(MAX));
		END
		EXEC sp_executesql @command;
	END

END
GO
