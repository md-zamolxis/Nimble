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
			O.[name]	= 'Branch.Action'))
	DROP PROCEDURE [Owner].[Branch.Action];
GO

CREATE PROCEDURE [Owner].[Branch.Action]
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

	SELECT * INTO [#input] FROM [Owner].[Branch.Entity](@entity) X;
	
	DECLARE 
		@exist		BIT	= @entity.exist('/*/Employees'),
		@employees	XML	= @entity.query('/*/Employees/Employee');
	
	IF (@permissionType = 'BranchCreate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY;
			INSERT [Owner].[Branch] 
			(
				[BranchOrganisationId],
				[BranchCode],
				[BranchName],
				[BranchDescription],
				[BranchActionType],
				[BranchLockedOn],
				[BranchAddress]
			)
			OUTPUT INSERTED.[BranchId] INTO @output ([Id])
			SELECT
				X.[OrganisationId],
				X.[Code],
				X.[Name],
				X.[Description],
				X.[BranchActionType],
				X.[LockedOn],
				X.[Address]
			FROM [#input] X;
			IF (@exist = 1)
				INSERT [Owner].[EmployeeBranch]
				SELECT DISTINCT
					E.[Id]	[EmployeeId],
					X.[Id]	[BranchId]
				FROM @output X, 
				[Common].[Generic.Entities](@employees) I
				CROSS APPLY [Owner].[Employee.Entity](I.[Entity]) E;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT B.* FROM [Owner].[Entity.Branch]	B
		INNER JOIN	@output						X	ON	B.[BranchId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'BranchRead') BEGIN
		SELECT B.* FROM [Owner].[Entity.Branch]	B
		INNER JOIN	[#input]					X	ON	B.[BranchId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'BranchUpdate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			UPDATE B SET 
				B.[BranchCode]			= X.[Code],
				B.[BranchName]			= X.[Name],
				B.[BranchDescription]	= X.[Description],
				B.[BranchActionType]	= X.[BranchActionType],
				B.[BranchLockedOn]		= X.[LockedOn],
				B.[BranchAddress]		= X.[Address]
			OUTPUT INSERTED.[BranchId] INTO @output ([Id])
			FROM [Owner].[Branch]	B
			INNER JOIN	[#input]	X	ON	B.[BranchId]		= X.[Id]	AND
											B.[BranchVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			IF (@exist = 1) BEGIN
				DELETE	EB	FROM [Owner].[EmployeeBranch]	EB
				INNER JOIN	@output							X	ON	EB.[EmployeeBranchBranchId]	= X.[Id];
				INSERT [Owner].[EmployeeBranch]
				SELECT DISTINCT
					E.[Id]	[EmployeeId],
					X.[Id]	[BranchId]
				FROM @output X, 
				[Common].[Generic.Entities](@employees) I
				CROSS APPLY [Owner].[Employee.Entity](I.[Entity]) E;
			END
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT B.* FROM [Owner].[Entity.Branch]	B
		INNER JOIN	@output						X	ON	B.[BranchId]	= X.[Id];
	END

	IF (@permissionType = 'BranchDelete') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			DELETE	EB	FROM [Owner].[EmployeeBranch]	EB
			INNER JOIN	[#input]						X	ON	EB.[EmployeeBranchBranchId]	= X.[Id];
			DELETE	B	FROM [Owner].[Branch]			B
			INNER JOIN	[#input]						X	ON	B.[BranchId]				= X.[Id]	AND
																B.[BranchVersion]			= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END
	
	IF (@permissionType = 'BranchSearch') BEGIN
		CREATE TABLE [#branch] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner].[Branch.Filter]
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
		INSERT [#branch] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [BranchOrganisationId] ASC, [BranchCode] ASC ');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT B.* FROM [Owner].[Entity.Branch]				B
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT B.* FROM [#branch]						X
					INNER JOIN	[Owner].[Entity.Branch]				B	ON	X.[Id]				= B.[BranchId]
					';
				ELSE
					IF (@branches IS NOT NULL)
						SET @command = '
						SELECT B.* FROM [Owner].[Entity.Branch]		B
						INNER JOIN	[#branches]						XB	ON	B.[BranchId]		= XB.[Id]
						LEFT JOIN	[#branch]						X	ON	B.[BranchId]		= X.[Id]
						WHERE 
							' + ISNULL('B.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
							X.[Id] IS NULL
						';
					ELSE
						IF (@organisations IS NULL)
							SET @command = '
							SELECT B.* FROM [Owner].[Entity.Branch]	B
							LEFT JOIN	[#branch]					X	ON	B.[BranchId]		= X.[Id]
							WHERE 
								' + ISNULL('B.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
								X.[Id] IS NULL
							';
						ELSE
							SET @command = '
							SELECT B.* FROM [Owner].[Entity.Branch]	B
							INNER JOIN	[#organisations]			XO	ON	B.[OrganisationId]	= XO.[Id]
							LEFT JOIN	[#branch]					X	ON	B.[BranchId]		= X.[Id]
							WHERE 
								' + ISNULL('B.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
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
						B.*, 
						ROW_NUMBER() OVER(' + @order + ') [Number]
					FROM [Owner].[Entity.Branch]					B
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
						FROM [#branch]								X
						INNER JOIN	[Owner].[Entity.Branch]			B	ON	X.[Id]				= B.[BranchId]
					)	B
					WHERE B.[Number] BETWEEN
					';
				ELSE
					IF (@branches IS NOT NULL)
						SET @command = '
						SELECT * FROM
						(
							SELECT 
								B.*, 
								ROW_NUMBER() OVER(' + @order + ') [Number]
							FROM [Owner].[Entity.Branch]			B
							INNER JOIN	[#branches]					XB	ON	B.[BranchId]		= XB.[Id]
							LEFT JOIN	[#branch]					X	ON	B.[BranchId]		= X.[Id]
							WHERE 
								' + ISNULL('B.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
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
									B.*, 
									ROW_NUMBER() OVER(' + @order + ') [Number]
								FROM [Owner].[Entity.Branch]		B
								LEFT JOIN	[#branch]				X	ON	B.[BranchId]		= X.[Id]
								WHERE 
									' + ISNULL('B.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
									X.[Id] IS NULL
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
								FROM [Owner].[Entity.Branch]		B
								INNER JOIN	[#organisations]		XO	ON	B.[OrganisationId]	= XO.[Id]
								LEFT JOIN	[#branch]				X	ON	B.[BranchId]		= X.[Id]
								WHERE 
									' + ISNULL('B.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
									X.[Id] IS NULL
							)	B
							WHERE B.[Number] BETWEEN
							';
			SET @command = @command + CAST(@startNumber AS NVARCHAR(MAX)) + ' AND ' + CAST(@endNumber AS NVARCHAR(MAX));
		END
		EXEC sp_executesql @command;
	END

END
GO
