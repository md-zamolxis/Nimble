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
			E.[name]	= 'Employee.Filter'))
	DROP PROCEDURE [Owner].[Employee.Filter];
GO

CREATE PROCEDURE [Owner].[Employee.Filter]
(
	@predicate		XML,
	@emplacementId	UNIQUEIDENTIFIER	= NULL,
	@applicationId	UNIQUEIDENTIFIER	= NULL,
	@organisations	XML					= NULL,
	@isCountable	BIT					= NULL,
	@guids			XML							OUTPUT,
	@isExcluded		BIT							OUTPUT,
	@isFiltered		BIT							OUTPUT,
	@number			INT							OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @employee TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
	DECLARE 
		@criteria			XML,
		@criteriaExist		BIT,
		@criteriaIsNull		BIT,
		@criteriaValue		XML,
		@criteriaValueExist	BIT,
		@dateFrom			DATETIMEOFFSET,
		@dateTo				DATETIMEOFFSET;
	
	SET @isFiltered = 0;

--	Filter by entities
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Employees')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Employee');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Owner].[Employee.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @employee SELECT * FROM @entities;
				ELSE
					INSERT @employee SELECT E.[EmployeeId] FROM [Owner].[Employee] E
					WHERE E.[EmployeeId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @employee X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @employee X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

--	Filter by person predicate
	DECLARE 
		@personPredicate	XML,
		@personIsCountable	BIT,
		@personGuids		XML,
		@personIsFiltered	BIT,
		@personNumber		INT;
	SELECT 
		@personPredicate	= X.[Criteria],
		@personIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/PersonPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @person TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner].[Person.Filter]
			@predicate,
			@emplacementId,
			@applicationId,
			@personId,
			@organisations,
			@isCountable,
			@guids		OUTPUT,
			@isExcluded OUTPUT,
			@isFiltered OUTPUT,
			@number		OUTPUT',
			N'@predicate	XML,
			@emplacementId	UNIQUEIDENTIFIER,
			@applicationId	UNIQUEIDENTIFIER,
			@personId		UNIQUEIDENTIFIER,
			@organisations	XML,
			@isCountable	BIT,
			@guids			XML OUTPUT,
			@isExcluded		BIT OUTPUT,
			@isFiltered		BIT OUTPUT,
			@number			INT OUTPUT',
			@predicate		= @personPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@personId		= NULL,
			@organisations	= NULL,
			@isCountable	= @personIsCountable,
			@guids			= @personGuids		OUTPUT,
			@isExcluded		= @isExcluded		OUTPUT,
			@isFiltered		= @personIsFiltered	OUTPUT,
			@number			= @personNumber		OUTPUT;
		INSERT @person SELECT * FROM [Common].[Guid.Entities](@personGuids);
		IF (@personIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @employee SELECT E.[EmployeeId] FROM [Owner].[Employee] E
					INNER JOIN	@person	X	ON	E.[EmployeePersonId]	= X.[Id];
				ELSE
					INSERT @employee SELECT E.[EmployeeId] FROM [Owner].[Employee] E
					LEFT JOIN	@person	X	ON	E.[EmployeePersonId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @employee	X
					LEFT JOIN
					(
						SELECT E.[EmployeeId] FROM [Owner].[Employee] E
						INNER JOIN	@person	X	ON	E.[EmployeePersonId]	= X.[Id]
					)	E	ON	X.[Id]	= E.[EmployeeId]
					WHERE E.[EmployeeId] IS NULL;
				ELSE
					DELETE X FROM @employee	X
					LEFT JOIN
					(
						SELECT E.[EmployeeId] FROM [Owner].[Employee] E
						LEFT JOIN	@person	X	ON	E.[EmployeePersonId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	E	ON	X.[Id]	= E.[EmployeeId]
					WHERE E.[EmployeeId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisation predicate
	DECLARE 
		@organisationPredicate		XML,
		@organisationIsCountable	BIT,
		@organisationGuids			XML,
		@organisationIsFiltered		BIT,
		@organisationNumber			INT;
	SELECT 
		@organisationPredicate		= X.[Criteria],
		@organisationIsCountable	= 0,
		@criteriaExist				= X.[CriteriaExist],
		@isExcluded					= X.[CriteriaIsExcluded],
		@criteriaIsNull				= X.[CriteriaIsNull],
		@criteriaValue				= X.[CriteriaValue],
		@criteriaValueExist			= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/OrganisationPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @organisation TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner].[Organisation.Filter]
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
			@predicate		= @organisationPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @organisationIsCountable,
			@guids			= @organisationGuids		OUTPUT,
			@isExcluded		= @isExcluded				OUTPUT,
			@isFiltered		= @organisationIsFiltered	OUTPUT,
			@number			= @organisationNumber		OUTPUT;
		INSERT @organisation SELECT * FROM [Common].[Guid.Entities](@organisationGuids);
		IF (@organisationIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @employee SELECT E.[EmployeeId] FROM [Owner].[Employee] E
					INNER JOIN	@organisation	X	ON	E.[EmployeeOrganisationId]	= X.[Id];
				ELSE
					INSERT @employee SELECT E.[EmployeeId] FROM [Owner].[Employee] E
					LEFT JOIN	@organisation	X	ON	E.[EmployeeOrganisationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @employee	X
					LEFT JOIN
					(
						SELECT E.[EmployeeId] FROM [Owner].[Employee] E
						INNER JOIN	@organisation	X	ON	E.[EmployeeOrganisationId]	= X.[Id]
					)	E	ON	X.[Id]	= E.[EmployeeId]
					WHERE E.[EmployeeId] IS NULL;
				ELSE
					DELETE X FROM @employee	X
					LEFT JOIN
					(
						SELECT E.[EmployeeId] FROM [Owner].[Employee] E
						LEFT JOIN	@organisation	X	ON	E.[EmployeeOrganisationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	E	ON	X.[Id]	= E.[EmployeeId]
					WHERE E.[EmployeeId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@organisations IS NOT NULL) BEGIN
		INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
		IF (@isFiltered = 0)
			INSERT @employee SELECT E.[EmployeeId] FROM [Owner].[Employee] E
			INNER JOIN	@organisationIds	XO	ON	E.[EmployeeOrganisationId]	= XO.[Id];
		ELSE
			DELETE X FROM @employee			X
			INNER JOIN	[Owner].[Employee]	E	ON	X.[Id]						= E.[EmployeeId]
			LEFT JOIN	@organisationIds	XO	ON	E.[EmployeeOrganisationId]	= XO.[Id]
			WHERE XO.[Id] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by functions
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Functions')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @functions TABLE ([Function] NVARCHAR(MAX));
		INSERT @functions SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @employee SELECT DISTINCT E.[EmployeeId] FROM [Owner].[Employee] E
					INNER JOIN	@functions	X	ON	E.[EmployeeFunction]	LIKE X.[Function];
				ELSE 
					INSERT @employee SELECT DISTINCT E.[EmployeeId] FROM [Owner].[Employee] E
					LEFT JOIN	@functions	X	ON	E.[EmployeeFunction]	LIKE X.[Function]
					WHERE X.[Function] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @employee	X
					LEFT JOIN
					(
						SELECT DISTINCT E.[EmployeeId] FROM [Owner].[Employee] E
						INNER JOIN	@functions	X	ON	E.[EmployeeFunction]	LIKE X.[Function]
					)	E	ON	X.[Id]	= E.[EmployeeId]
					WHERE E.[EmployeeId] IS NULL;
				ELSE
					DELETE X FROM @employee	X
					LEFT JOIN
					(
						SELECT DISTINCT E.[EmployeeId] FROM [Owner].[Employee] E
						LEFT JOIN	@functions	X	ON	E.[EmployeeFunction]	LIKE X.[Function]
						WHERE X.[Function] IS NULL
					)	E	ON	X.[Id]	= E.[EmployeeId]
					WHERE E.[EmployeeId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by codes
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Codes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @codes TABLE ([Code] NVARCHAR(MAX));
		INSERT @codes SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @employee SELECT DISTINCT E.[EmployeeId] FROM [Owner].[Employee] E
					INNER JOIN	@codes	X	ON	E.[EmployeeCode]	LIKE X.[Code];
				ELSE 
					INSERT @employee SELECT DISTINCT E.[EmployeeId] FROM [Owner].[Employee] E
					LEFT JOIN	@codes	X	ON	E.[EmployeeCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @employee	X
					LEFT JOIN
					(
						SELECT DISTINCT E.[EmployeeId] FROM [Owner].[Employee] E
						INNER JOIN	@codes	X	ON	E.[EmployeeCode]	LIKE X.[Code]
					)	E	ON	X.[Id]	= E.[EmployeeId]
					WHERE E.[EmployeeId] IS NULL;
				ELSE
					DELETE X FROM @employee	X
					LEFT JOIN
					(
						SELECT DISTINCT E.[EmployeeId] FROM [Owner].[Employee] E
						LEFT JOIN	@codes	X	ON	E.[EmployeeCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	E	ON	X.[Id]	= E.[EmployeeId]
					WHERE E.[EmployeeId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by default status
	DECLARE @isDefault BIT;
	SET @isDefault = [Common].[Bool.Entity](@predicate.query('/*/IsDefault'));
	IF (@isDefault IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @employee SELECT E.[EmployeeId] FROM [Owner].[Employee] E
			WHERE E.[EmployeeIsDefault] = @isDefault;
		ELSE
			DELETE X FROM @employee	X
			LEFT JOIN
			(
				SELECT E.[EmployeeId] FROM [Owner].[Employee] E
				WHERE E.[EmployeeIsDefault] = @isDefault
			)	E	ON	X.[Id]	= E.[EmployeeId]
			WHERE E.[EmployeeId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by created datetime offset
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/CreatedOn')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @dateFrom = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @employee SELECT E.[EmployeeId] FROM [Owner].[Employee] E
					WHERE E.[EmployeeCreatedOn] BETWEEN ISNULL(@dateFrom, E.[EmployeeCreatedOn]) AND ISNULL(@dateTo, E.[EmployeeCreatedOn]);
				ELSE 
					INSERT @employee SELECT E.[EmployeeId] FROM [Owner].[Employee] E
					WHERE E.[EmployeeCreatedOn] NOT BETWEEN ISNULL(@dateFrom, E.[EmployeeCreatedOn]) AND ISNULL(@dateTo, E.[EmployeeCreatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @employee	X
					LEFT JOIN
					(
						SELECT E.[EmployeeId] FROM [Owner].[Employee] E
						WHERE E.[EmployeeCreatedOn] BETWEEN ISNULL(@dateFrom, E.[EmployeeCreatedOn]) AND ISNULL(@dateTo, E.[EmployeeCreatedOn])
					)	E	ON	X.[Id]	= E.[EmployeeId]
					WHERE E.[EmployeeId] IS NULL;
				ELSE
					DELETE X FROM @employee	X
					LEFT JOIN
					(
						SELECT E.[EmployeeId] FROM [Owner].[Employee] E
						WHERE E.[EmployeeCreatedOn] NOT BETWEEN ISNULL(@dateFrom, E.[EmployeeCreatedOn]) AND ISNULL(@dateTo, E.[EmployeeCreatedOn])
					)	E	ON	X.[Id]	= E.[EmployeeId]
					WHERE E.[EmployeeId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by employee actor types
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/EmployeeActorTypes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @employeeActorTypes TABLE ([EmployeeActorType] NVARCHAR(MAX));
		INSERT @employeeActorTypes SELECT DISTINCT * FROM [Common].[Enum.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @employee SELECT E.[EmployeeId] FROM [Owner].[Employee] E
					INNER JOIN	@employeeActorTypes	X	ON	E.[EmployeeActorType]	LIKE X.[EmployeeActorType];
				ELSE 
					INSERT @employee SELECT E.[EmployeeId] FROM [Owner].[Employee] E
					LEFT JOIN	@employeeActorTypes	X	ON	E.[EmployeeActorType]	LIKE X.[EmployeeActorType]
					WHERE X.[EmployeeActorType] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @employee	X
					LEFT JOIN
					(
						SELECT E.[EmployeeId] FROM [Owner].[Employee] E
						INNER JOIN	@employeeActorTypes	X	ON	E.[EmployeeActorType]	LIKE X.[EmployeeActorType]
					)	E	ON	X.[Id]	= E.[EmployeeId]
					WHERE E.[EmployeeId] IS NULL;
				ELSE
					DELETE X FROM @employee	X
					LEFT JOIN
					(
						SELECT E.[EmployeeId] FROM [Owner].[Employee] E
						LEFT JOIN	@employeeActorTypes	X	ON	E.[EmployeeActorType]	LIKE X.[EmployeeActorType]
						WHERE X.[EmployeeActorType] IS NULL
					)	E	ON	X.[Id]	= E.[EmployeeId]
					WHERE E.[EmployeeId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by state
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/State')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE 
			@from		DATETIMEOFFSET,
			@to			DATETIMEOFFSET,
			@appliedOn	DATETIMEOFFSET	 = SYSDATETIMEOFFSET(),
			@isActive	BIT;
		SELECT 
			@from		= X.[From],
			@to			= X.[To],
			@appliedOn	= X.[AppliedOn],
			@isActive	= X.[IsActive]
		FROM [Common].[State.Entity](@criteriaValue) X;
		IF (@isActive IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @employee SELECT DISTINCT S.[EmployeeStateEmployeeId] FROM [Owner].[EmployeeState] S
					WHERE
						(S.[EmployeeFrom] < @appliedOn AND @appliedOn <= S.[EmployeeTo])	AND
						S.[EmployeeIsActive] = @isActive;
				ELSE
					INSERT @employee SELECT DISTINCT S.[EmployeeStateEmployeeId] FROM [Owner].[EmployeeState] S
					WHERE NOT 
						(
							(S.[EmployeeFrom] < @appliedOn AND @appliedOn <= S.[EmployeeTo])	AND
							S.[EmployeeIsActive] = @isActive
						);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @employee	X
					LEFT JOIN
					(
						SELECT DISTINCT S.[EmployeeStateEmployeeId] FROM [Owner].[EmployeeState] S
						WHERE
							(S.[EmployeeFrom] < @appliedOn AND @appliedOn <= S.[EmployeeTo])	AND
							S.[EmployeeIsActive] = @isActive
					)	S	ON	X.[Id]	= S.[EmployeeStateEmployeeId]
					WHERE S.[EmployeeStateEmployeeId] IS NULL;
				ELSE
					DELETE X FROM @employee	X
					LEFT JOIN
					(
						SELECT DISTINCT S.[EmployeeStateEmployeeId] FROM [Owner].[EmployeeState] S
						WHERE NOT 
							(
								(S.[EmployeeFrom] < @appliedOn AND @appliedOn <= S.[EmployeeTo])	AND
								S.[EmployeeIsActive] = @isActive
							)
					)	S	ON	X.[Id]	= S.[EmployeeStateEmployeeId]
					WHERE S.[EmployeeStateEmployeeId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by branch predicate
	DECLARE 
		@branchPredicate	XML,
		@branchIsCountable	BIT,
		@branchGuids		XML,
		@branchIsFiltered	BIT,
		@branchNumber		INT;
	SELECT 
		@branchPredicate	= X.[Criteria],
		@branchIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/BranchPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @branch TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
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
			@predicate		= @branchPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@branches		= NULL,
			@isCountable	= @branchIsCountable,
			@guids			= @branchGuids		OUTPUT,
			@isExcluded		= @isExcluded		OUTPUT,
			@isFiltered		= @branchIsFiltered	OUTPUT,
			@number			= @branchNumber		OUTPUT;
		INSERT @branch SELECT * FROM [Common].[Guid.Entities](@branchGuids);
		IF (@branchIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @employee SELECT DISTINCT EB.[EmployeeBranchEmployeeId] FROM [Owner].[EmployeeBranch] EB
					INNER JOIN	@branch	X	ON	EB.[EmployeeBranchBranchId]	= X.[Id];
				ELSE
					INSERT @employee SELECT DISTINCT EB.[EmployeeBranchEmployeeId] FROM [Owner].[EmployeeBranch] EB
					LEFT JOIN	@branch	X	ON	EB.[EmployeeBranchBranchId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @employee	X
					LEFT JOIN
					(
						SELECT DISTINCT EB.[EmployeeBranchEmployeeId] FROM [Owner].[EmployeeBranch] EB
						INNER JOIN	@branch	X	ON	EB.[EmployeeBranchBranchId]	= X.[Id]
					)	EB	ON	X.[Id]	= EB.[EmployeeBranchEmployeeId]
					WHERE EB.[EmployeeBranchEmployeeId] IS NULL;
				ELSE
					DELETE X FROM @employee	X
					LEFT JOIN
					(
						SELECT DISTINCT EB.[EmployeeBranchEmployeeId] FROM [Owner].[EmployeeBranch] EB
						LEFT JOIN	@branch	X	ON	EB.[EmployeeBranchBranchId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	EB	ON	X.[Id]	= EB.[EmployeeBranchEmployeeId]
					WHERE EB.[EmployeeBranchEmployeeId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @employee SELECT E.[EmployeeId] FROM [Owner].[Employee] E
			INNER JOIN	[Owner].[Person]	P	ON	E.[EmployeePersonId] = P.[PersonId]
			WHERE P.[PersonEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @employee	X
			LEFT JOIN
			(
				SELECT E.[EmployeeId] FROM [Owner].[Employee] E
				INNER JOIN	[Owner].[Person]	P	ON	E.[EmployeePersonId] = P.[PersonId]
				WHERE P.[PersonEmplacementId] = @emplacementId
			)	E	ON	X.[Id]	= E.[EmployeeId]
			WHERE E.[EmployeeId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @employee X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Owner].[Employee] E;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @employee X;
		ELSE
			IF (@organisations IS NULL)
				SELECT @number = COUNT(*) FROM [Owner].[Employee] E
				INNER JOIN	[Owner].[Person]	P	ON	E.[EmployeePersonId]	= P.[PersonId]
				LEFT JOIN	@employee			X	ON	E.[EmployeeId]			= X.[Id]
				WHERE 
					P.[PersonEmplacementId] = ISNULL(@emplacementId, P.[PersonEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE 
				SELECT @number = COUNT(*) FROM [Owner].[Employee] E
				INNER JOIN	[Owner].[Person]	P	ON	E.[EmployeePersonId]		= P.[PersonId]
				INNER JOIN	@organisationIds	XO	ON	E.[EmployeeOrganisationId]	= XO.[Id]
				LEFT JOIN	@employee			X	ON	E.[EmployeeId]				= X.[Id]
				WHERE 
					P.[PersonEmplacementId] = ISNULL(@emplacementId, P.[PersonEmplacementId])	AND
					X.[Id] IS NULL;

END
GO
