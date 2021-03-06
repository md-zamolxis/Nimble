SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		E	ON	S.[schema_id]	= E.[schema_id]
		WHERE 
			S.[name]	= 'Owner'	AND
			E.[type]	= 'P'		AND
			E.[name]	= 'Employee.Action'))
	DROP PROCEDURE [Owner].[Employee.Action];
GO

CREATE PROCEDURE [Owner].[Employee.Action]
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

	SELECT * INTO [#input] FROM [Owner].[Employee.Entity](@entity) X;
	
	DECLARE 
		@exist		BIT	= @entity.exist('/*/Branches'),
		@branches	XML	= @entity.query('/*/Branches/Branch'),
		@from		DATETIMEOFFSET,
		@to			DATETIMEOFFSET,
		@appliedOn	DATETIMEOFFSET	= SYSDATETIMEOFFSET(),
		@isActive	BIT;

	IF (@permissionType = 'EmployeeCreate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			UPDATE E SET E.[EmployeeIsDefault] = 0
			FROM [Owner].[Employee]	E
			INNER JOIN	[#input]	X	ON	E.[EmployeeOrganisationId]	= X.[OrganisationId]	AND
											E.[EmployeeIsDefault]		= 1
			WHERE X.[IsDefault] = 1;
			WITH XC AS
			(
				SELECT ISNULL(MAX(CAST(E.[EmployeeCode] AS INT)), 0) + 1	[Code]
				FROM [#input]					X
				INNER JOIN	[Owner].[Employee]	E	ON	X.[OrganisationId]	= E.[EmployeeOrganisationId]
				WHERE [Common].[Code.IsNumeric](E.[EmployeeCode]) = 1
			)
			INSERT [Owner].[Employee] 
			(
				[EmployeePersonId],
				[EmployeeOrganisationId],
				[EmployeeCode],
				[EmployeeFunction],
				[EmployeeCreatedOn],
				[EmployeeActorType],
                [EmployeeIsDefault]
			)
			OUTPUT INSERTED.[EmployeeId] INTO @output ([Id])
			SELECT
				X.[PersonId],
				X.[OrganisationId],
				ISNULL(X.[Code], XC.[Code]),
				X.[Function],
				X.[CreatedOn],
				X.[EmployeeActorType],
				X.[IsDefault]
			FROM [#input]	X
			OUTER APPLY		XC;
			SELECT 
				@from		= X.[From],
				@to			= X.[To],
				@appliedOn	= X.[AppliedOn],
				@isActive	= X.[IsActive]
			FROM [Common].[State.Entity](@entity.query('/*/State')) X;
			INSERT [Owner].[EmployeeState]
			( 
				[EmployeeStateEmployeeId],
				[EmployeeFrom],
				[EmployeeTo],
				[EmployeeIsActive]
			)
			SELECT * FROM 
			(
				SELECT
					X.[Id]			[EmployeeId],
					@from			[From],
					@appliedOn		[To],
					@isActive ^ 1	[IsActive]
				FROM @output X
				UNION ALL
				SELECT
					X.[Id]			[EmployeeId],
					@appliedOn		[From],
					@to				[To],
					@isActive		[IsActive]
				FROM @output X
			) X;
			IF (@exist = 1)
				INSERT [Owner].[EmployeeBranch]
				SELECT DISTINCT
					X.[Id]	[EmployeeId],
					E.[Id]	[BranchId]
				FROM @output X, 
				[Common].[Generic.Entities](@branches) I
				CROSS APPLY [Owner].[Branch.Entity](I.[Entity]) E;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SET @appliedOn = SYSDATETIMEOFFSET();
		SELECT 
			E.*,
			ES.*
		FROM [Owner].[Entity.Employee]		E
		INNER JOIN	[Owner].[EmployeeState]	ES	ON	E.[EmployeeId]	= ES.[EmployeeStateEmployeeId]
		INNER JOIN	@output					X	ON	E.[EmployeeId]	= X.[Id]
		WHERE (ES.[EmployeeFrom] <= @appliedOn AND @appliedOn < ES.[EmployeeTo]);
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'EmployeeRead') BEGIN
		SELECT 
			@from		= X.[From],
			@to			= X.[To],
			@appliedOn	= X.[AppliedOn],
			@isActive	= X.[IsActive]
		FROM [Common].[State.Entity](@entity.query('/*/State')) X;
		SELECT 
			E.*,
			ES.*
		FROM [Owner].[Entity.Employee]		E
		INNER JOIN	[Owner].[EmployeeState]	ES	ON	E.[EmployeeId]	= ES.[EmployeeStateEmployeeId]
		INNER JOIN	[#input]				X	ON	E.[EmployeeId]	= X.[Id]
		WHERE (ES.[EmployeeFrom] <= @appliedOn AND @appliedOn < ES.[EmployeeTo]);
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'EmployeeUpdate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			UPDATE E SET E.[EmployeeIsDefault] = 0
			FROM [Owner].[Employee]	E
			INNER JOIN	[#input]	X	ON	E.[EmployeeId]				<>	X.[Id]				AND
											E.[EmployeeOrganisationId]	=	X.[OrganisationId]	AND
											E.[EmployeeIsDefault]		=	1
			WHERE X.[IsDefault] = 1;
			UPDATE E SET 
				E.[EmployeeCode]		= X.[Code],
				E.[EmployeeFunction]	= X.[Function],
				E.[EmployeeActorType]	= X.[EmployeeActorType],
				E.[EmployeeIsDefault]	= X.[IsDefault]
			OUTPUT INSERTED.[EmployeeId] INTO @output ([Id])
			FROM [Owner].[Employee]	E
			INNER JOIN	[#input]	X	ON	E.[EmployeeId]		= X.[Id]	AND
											E.[EmployeeVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			SELECT 
				@from		= X.[From],
				@to			= X.[To],
				@appliedOn	= X.[AppliedOn],
				@isActive	= X.[IsActive]
			FROM [Common].[State.Entity](@entity.query('/*/State')) X;
			DECLARE @state TABLE ([To] DATETIMEOFFSET);
			UPDATE ES SET ES.[EmployeeTo] = @appliedOn
			OUTPUT DELETED.[EmployeeTo] INTO @state ([To])
			FROM [Owner].[EmployeeState]	ES
			INNER JOIN	@output				X	ON	ES.[EmployeeStateEmployeeId]	= X.[Id]
			WHERE
				(ES.[EmployeeFrom] <= @appliedOn AND @appliedOn < ES.[EmployeeTo])	AND
				ES.[EmployeeIsActive] <> @isActive;
			INSERT [Owner].[EmployeeState] 
			(
				[EmployeeStateEmployeeId],
				[EmployeeFrom],
				[EmployeeTo],
				[EmployeeIsActive]
			) 
			SELECT
				X.[Id],
				@appliedOn,
				S.[To],
				@isActive
			FROM @output X, @state S;
			IF (@exist = 1) BEGIN
				DELETE	EB	FROM [Owner].[EmployeeBranch]	EB
				INNER JOIN	@output							X	ON	EB.[EmployeeBranchEmployeeId]	= X.[Id];
				INSERT [Owner].[EmployeeBranch]
				SELECT DISTINCT
					X.[Id]	[EmployeeId],
					E.[Id]	[BranchId]
				FROM @output X, 
				[Common].[Generic.Entities](@branches) I
				CROSS APPLY [Owner].[Branch.Entity](I.[Entity]) E;
			END
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT 
			E.*,
			ES.*
		FROM [Owner].[Entity.Employee]		E
		INNER JOIN	[Owner].[EmployeeState]	ES	ON	E.[EmployeeId]	= ES.[EmployeeStateEmployeeId]
		INNER JOIN	@output					X	ON	E.[EmployeeId]	= X.[Id]
		WHERE (ES.[EmployeeFrom] <= @appliedOn AND @appliedOn < ES.[EmployeeTo]);
	END

	IF (@permissionType = 'EmployeeDelete') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			DELETE	EB	FROM [Owner].[EmployeeBranch]	EB
			INNER JOIN	[#input]						X	ON	EB.[EmployeeBranchEmployeeId]	= X.[Id];
			DELETE	ES	FROM [Owner].[EmployeeState]	ES
			INNER JOIN	[#input]						X	ON	ES.[EmployeeStateEmployeeId]	= X.[Id];
			DELETE	E	FROM [Owner].[Employee]	E
			INNER JOIN	[#input]				X	ON	E.[EmployeeId]		= X.[Id]	AND
														E.[EmployeeVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END
	
	IF (@permissionType = 'EmployeeSearch') BEGIN
		CREATE TABLE [#employee] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner].[Employee.Filter]
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
		INSERT [#employee] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [OrganisationName] ASC, [PersonCode] ASC ');
		SELECT 
			@from		= X.[From],
			@to			= X.[To],
			@appliedOn	= X.[AppliedOn],
			@isActive	= X.[IsActive]
		FROM [Common].[State.Entity](@predicate.query('/*/State/Value')) X;
		DECLARE @employeeState NVARCHAR(MAX);
		SET @employeeState = '''' + CONVERT(NVARCHAR(MAX), @appliedOn, 120) + '''';
		SET @employeeState = 'ES.[EmployeeFrom] <= ' + @employeeState + ' AND ' + @employeeState + ' < ES.[EmployeeTo]';
		IF (@isFiltered = 0)
			SET @command = '
			SELECT E.*, ES.* FROM [Owner].[Entity.Employee]			E
			INNER JOIN	[Owner].[EmployeeState]						ES	ON	E.[EmployeeId]				= ES.[EmployeeStateEmployeeId]
			WHERE ' + @employeeState + '
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT E.*, ES.* FROM [#employee]					X
				INNER JOIN	[Owner].[Entity.Employee]				E	ON	X.[Id]						= E.[EmployeeId]
				INNER JOIN	[Owner].[EmployeeState]					ES	ON	E.[EmployeeId]				= ES.[EmployeeStateEmployeeId]
				WHERE ' + @employeeState + '
				';
			ELSE
				IF (@organisations IS NULL)
					SET @command = '
					SELECT E.*, ES.* FROM [Owner].[Entity.Employee]	E
					INNER JOIN	[Owner].[EmployeeState]				ES	ON	E.[EmployeeId]				= ES.[EmployeeStateEmployeeId]
					LEFT JOIN	[#employee]							X	ON	E.[EmployeeId]				= X.[Id]
					WHERE ' + @employeeState + ' AND
						' + ISNULL('E.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						X.[Id] IS NULL
					';
				ELSE
					SET @command = '
					SELECT E.*, ES.* FROM [Owner].[Entity.Employee]	E
					INNER JOIN	[Owner].[EmployeeState]				ES	ON	E.[EmployeeId]				= ES.[EmployeeStateEmployeeId]
					INNER JOIN	[#organisations]					XO	ON	E.[EmployeeOrganisationId]	= XO.[Id]
					LEFT JOIN	[#employee]							X	ON	E.[EmployeeId]				= X.[Id]
					WHERE ' + @employeeState + ' AND
						' + ISNULL('E.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						X.[Id] IS NULL
					';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
