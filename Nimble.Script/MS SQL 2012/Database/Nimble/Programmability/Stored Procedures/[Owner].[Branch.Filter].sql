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
			O.[name]	= 'Branch.Filter'))
	DROP PROCEDURE [Owner].[Branch.Filter];
GO

CREATE PROCEDURE [Owner].[Branch.Filter]
(
	@predicate		XML,
	@emplacementId	UNIQUEIDENTIFIER	= NULL,
	@applicationId	UNIQUEIDENTIFIER	= NULL,
	@organisations	XML					= NULL,
	@branches		XML					= NULL,
	@isCountable	BIT					= NULL,
	@guids			XML							OUTPUT,
	@isExcluded		BIT							OUTPUT,
	@isFiltered		BIT							OUTPUT,
	@number			INT							OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @branch TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
	DECLARE 
		@criteria			XML,
		@criteriaExist		BIT,
		@criteriaIsNull		BIT,
		@criteriaValue		XML,
		@criteriaValueExist	BIT,
		@amountFrom			DECIMAL(28, 9),
		@amountTo			DECIMAL(28, 9),
		@dateFrom			DATETIMEOFFSET,
		@dateTo				DATETIMEOFFSET,
		@flagsNumber		INT,
		@flagsIsExact		BIT;
	
	SET @isFiltered = 0;

--	Filter by entities
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Branches')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Branch');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Owner].[Branch.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @branch SELECT * FROM @entities;
				ELSE
					INSERT @branch SELECT B.[BranchId] FROM [Owner].[Branch] B
					WHERE B.[BranchId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @branch X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @branch X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
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
					INSERT @branch SELECT B.[BranchId] FROM [Owner].[Branch] B
					INNER JOIN	@organisation	X	ON	B.[BranchOrganisationId]	= X.[Id];
				ELSE
					INSERT @branch SELECT B.[BranchId] FROM [Owner].[Branch] B
					LEFT JOIN	@organisation	X	ON	B.[BranchOrganisationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT B.[BranchId] FROM [Owner].[Branch] B
						INNER JOIN	@organisation	X	ON	B.[BranchOrganisationId]	= X.[Id]
					)	B	ON	X.[Id]	= B.[BranchId]
					WHERE B.[BranchId] IS NULL;
				ELSE
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT B.[BranchId] FROM [Owner].[Branch] B
						LEFT JOIN	@organisation	X	ON	B.[BranchOrganisationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	B	ON	X.[Id]	= B.[BranchId]
					WHERE B.[BranchId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	DECLARE @branchIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@branches IS NOT NULL) BEGIN
		INSERT @branchIds SELECT * FROM [Common].[Guid.Entities](@branches);
		IF (@isFiltered = 0)
			INSERT @branch SELECT XB.[Id] FROM @branchIds XB;
		ELSE
			DELETE X FROM @branch	X 
			LEFT JOIN	@branchIds	XB	ON	X.[Id]	= XB.[Id]
			WHERE XB.[Id] IS NULL;
		SET @isFiltered = 1;
	END
	ELSE
		IF (@organisations IS NOT NULL) BEGIN
			INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
			IF (@isFiltered = 0)
				INSERT @branch SELECT B.[BranchId] FROM [Owner].[Branch] B
				INNER JOIN	@organisationIds	XO	ON	B.[BranchOrganisationId]	= XO.[Id];
			ELSE
				DELETE X FROM @branch			X 
				INNER JOIN	[Owner].[Branch]	B	ON	X.[Id]						= B.[BranchId]
				LEFT JOIN	@organisationIds	XO	ON	B.[BranchOrganisationId]	= XO.[Id]
				WHERE XO.[Id] IS NULL;
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
					INSERT @branch SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
					INNER JOIN	@codes	X	ON	B.[BranchCode]	LIKE X.[Code];
				ELSE 
					INSERT @branch SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
					LEFT JOIN	@codes	X	ON	B.[BranchCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
						INNER JOIN	@codes	X	ON	B.[BranchCode]	LIKE X.[Code]
					)	B	ON	X.[Id]	= B.[BranchId]
					WHERE B.[BranchId] IS NULL;
				ELSE
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
						LEFT JOIN	@codes	X	ON	B.[BranchCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	B	ON	X.[Id]	= B.[BranchId]
					WHERE B.[BranchId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by names
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Names')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @names TABLE ([Name] NVARCHAR(MAX));
		INSERT @names SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @branch SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
					INNER JOIN	@names	X	ON	B.[BranchName]	LIKE X.[Name];
				ELSE 
					INSERT @branch SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
					LEFT JOIN	@names	X	ON	B.[BranchName]	LIKE X.[Name]
					WHERE X.[Name] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
						INNER JOIN	@names	X	ON	B.[BranchName]	LIKE X.[Name]
					)	B	ON	X.[Id]	= B.[BranchId]
					WHERE B.[BranchId] IS NULL;
				ELSE
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
						LEFT JOIN	@names	X	ON	B.[BranchName]	LIKE X.[Name]
						WHERE X.[Name] IS NULL
					)	B	ON	X.[Id]	= B.[BranchId]
					WHERE B.[BranchId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by descriptions
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Descriptions')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @descriptions TABLE ([Description] NVARCHAR(MAX));
		INSERT @descriptions SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @branch SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
					INNER JOIN	@descriptions	X	ON	B.[BranchDescription]	LIKE X.[Description];
				ELSE 
					INSERT @branch SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
					LEFT JOIN	@descriptions	X	ON	B.[BranchDescription]	LIKE X.[Description]
					WHERE X.[Description] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
						INNER JOIN	@descriptions	X	ON	B.[BranchDescription]	LIKE X.[Description]
					)	B	ON	X.[Id]	= B.[BranchId]
					WHERE B.[BranchId] IS NULL;
				ELSE
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
						LEFT JOIN	@descriptions	X	ON	B.[BranchDescription]	LIKE X.[Description]
						WHERE X.[Description] IS NULL
					)	B	ON	X.[Id]	= B.[BranchId]
					WHERE B.[BranchId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by locked datetime offset
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/LockedOn')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @dateFrom = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @branch SELECT B.[BranchId] FROM [Owner].[Branch] B
					WHERE 
						B.[BranchLockedOn] IS NULL OR 
						B.[BranchLockedOn] BETWEEN ISNULL(@dateFrom, B.[BranchLockedOn]) AND ISNULL(@dateTo, B.[BranchLockedOn]);
				ELSE 
					INSERT @branch SELECT B.[BranchId] FROM [Owner].[Branch] B
					WHERE  
						B.[BranchLockedOn] IS NULL OR 
						B.[BranchLockedOn] NOT BETWEEN ISNULL(@dateFrom, B.[BranchLockedOn]) AND ISNULL(@dateTo, B.[BranchLockedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT B.[BranchId] FROM [Owner].[Branch] B
						WHERE  
							B.[BranchLockedOn] IS NULL OR 
							B.[BranchLockedOn] BETWEEN ISNULL(@dateFrom, B.[BranchLockedOn]) AND ISNULL(@dateTo, B.[BranchLockedOn])
					)	B	ON	X.[Id]	= B.[BranchId]
					WHERE B.[BranchId] IS NULL;
				ELSE
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT B.[BranchId] FROM [Owner].[Branch] B
						WHERE  
							B.[BranchLockedOn] IS NULL OR 
							B.[BranchLockedOn] NOT BETWEEN ISNULL(@dateFrom, B.[BranchLockedOn]) AND ISNULL(@dateTo, B.[BranchLockedOn])
					)	B	ON	X.[Id]	= B.[BranchId]
					WHERE B.[BranchId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by branch action type
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/BranchActionType')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @flagsNumber = NULL, @flagsIsExact = NULL;
		SELECT 
			@flagsNumber	= X.[Number], 
			@flagsIsExact	= X.[IsExact] 
		FROM [Common].[Flags.Entity](@criteriaValue) X;
		IF (@flagsNumber > 0 OR @flagsIsExact = 1)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @branch SELECT B.[BranchId] FROM [Owner].[Branch] B
					WHERE [Common].[Flags.NumberIsEqual](B.[BranchActionType], @flagsNumber, @flagsIsExact) = 1;
				ELSE 
					INSERT @branch SELECT B.[BranchId] FROM [Owner].[Branch] B
					WHERE [Common].[Flags.NumberIsEqual](B.[BranchActionType], @flagsNumber, @flagsIsExact) = 0;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT B.[BranchId] FROM [Owner].[Branch] B
						WHERE [Common].[Flags.NumberIsEqual](B.[BranchActionType], @flagsNumber, @flagsIsExact) = 1
					)	B	ON	X.[Id]	= B.[BranchId]
					WHERE B.[BranchId] IS NULL;
				ELSE
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT B.[BranchId] FROM [Owner].[Branch] B
						WHERE [Common].[Flags.NumberIsEqual](B.[BranchActionType], @flagsNumber, @flagsIsExact) = 0
					)	B	ON	X.[Id]	= B.[BranchId]
					WHERE B.[BranchId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by addresses
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Addresses')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @addresses TABLE ([Address] NVARCHAR(MAX));
		INSERT @addresses SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @branch SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
					INNER JOIN	@addresses	X	ON	B.[BranchAddress]	LIKE X.[Address];
				ELSE 
					INSERT @branch SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
					LEFT JOIN	@addresses	X	ON	B.[BranchAddress]	LIKE X.[Address]
					WHERE X.[Address] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
						INNER JOIN	@addresses	X	ON	B.[BranchAddress]	LIKE X.[Address]
					)	B	ON	X.[Id]	= B.[BranchId]
					WHERE B.[BranchId] IS NULL;
				ELSE
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
						LEFT JOIN	@addresses	X	ON	B.[BranchAddress]	LIKE X.[Address]
						WHERE X.[Address] IS NULL
					)	B	ON	X.[Id]	= B.[BranchId]
					WHERE B.[BranchId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by group predicate
	DECLARE 
		@groupPredicate		XML,
		@groupIsCountable	BIT,
		@groupGuids			XML,
		@groupIsFiltered	BIT,
		@groupNumber		INT;
	SELECT 
		@groupPredicate		= X.[Criteria],
		@groupIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/GroupPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @group TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Common].[Group.Filter]
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
			@guids			XML	OUTPUT,
			@isExcluded		BIT OUTPUT,
			@isFiltered		BIT OUTPUT,
			@number			INT OUTPUT',
			@predicate		= @groupPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @groupIsCountable,
			@guids			= @groupGuids		OUTPUT,
			@isExcluded		= @isExcluded		OUTPUT,
			@isFiltered		= @groupIsFiltered	OUTPUT,
			@number			= @groupNumber		OUTPUT;
		INSERT @group SELECT * FROM [Common].[Guid.Entities](@groupGuids);
		IF (@groupIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @branch SELECT DISTINCT B.[BondEntityId] FROM [Common].[Bond] B
					INNER JOIN	@group	X	ON	B.[BondGroupId]	= X.[Id];
				ELSE
					INSERT @branch SELECT DISTINCT B.[BondEntityId] FROM [Common].[Bond] B
					LEFT JOIN	@group	X	ON	B.[BondGroupId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT DISTINCT B.[BondEntityId] FROM [Common].[Bond] B
						INNER JOIN	@group	X	ON	B.[BondGroupId]	= X.[Id]
					)	B	ON	X.[Id]	= B.[BondEntityId]
					WHERE B.[BondEntityId] IS NULL;
				ELSE
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT DISTINCT B.[BondEntityId] FROM [Common].[Bond] B
						LEFT JOIN	@group	X	ON	B.[BondGroupId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	B	ON	X.[Id]	= B.[BondEntityId]
					WHERE B.[BondEntityId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by employee predicate
	DECLARE 
		@employeePredicate		XML,
		@employeeIsCountable	BIT,
		@employeeGuids			XML,
		@employeeIsFiltered		BIT,
		@employeeNumber			INT;
	SELECT 
		@employeePredicate		= X.[Criteria],
		@employeeIsCountable	= 0,
		@criteriaExist			= X.[CriteriaExist],
		@isExcluded				= X.[CriteriaIsExcluded],
		@criteriaIsNull			= X.[CriteriaIsNull],
		@criteriaValue			= X.[CriteriaValue],
		@criteriaValueExist		= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/EmployeePredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @employee TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
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
			@predicate		= @employeePredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @employeeIsCountable,
			@guids			= @employeeGuids		OUTPUT,
			@isExcluded		= @isExcluded			OUTPUT,
			@isFiltered		= @employeeIsFiltered	OUTPUT,
			@number			= @employeeNumber		OUTPUT;
		INSERT @employee SELECT * FROM [Common].[Guid.Entities](@employeeGuids);
		IF (@employeeIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @branch SELECT DISTINCT EB.[EmployeeBranchBranchId] FROM [Owner].[EmployeeBranch] EB
					INNER JOIN	@employee	X	ON	EB.[EmployeeBranchEmployeeId]	= X.[Id];
				ELSE
					INSERT @branch SELECT DISTINCT EB.[EmployeeBranchBranchId] FROM [Owner].[EmployeeBranch] EB
					LEFT JOIN	@employee	X	ON	EB.[EmployeeBranchEmployeeId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT DISTINCT EB.[EmployeeBranchBranchId] FROM [Owner].[EmployeeBranch] EB
						INNER JOIN	@employee	X	ON	EB.[EmployeeBranchEmployeeId]	= X.[Id]
					)	EB	ON	X.[Id]	= EB.[EmployeeBranchBranchId]
					WHERE EB.[EmployeeBranchBranchId] IS NULL;
				ELSE
					DELETE X FROM @branch	X
					LEFT JOIN
					(
						SELECT DISTINCT EB.[EmployeeBranchBranchId] FROM [Owner].[EmployeeBranch] EB
						LEFT JOIN	@employee	X	ON	EB.[EmployeeBranchEmployeeId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	EB	ON	X.[Id]	= EB.[EmployeeBranchBranchId]
					WHERE EB.[EmployeeBranchBranchId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by branch group predicate
	DECLARE 
		@branchGroupPredicate	XML,
		@branchGroupIsCountable	BIT,
		@branchGroupGuids		XML,
		@branchGroupIsFiltered	BIT,
		@branchGroupNumber		INT,
		@splitNumber			INT;
	SELECT 
		@branchGroupPredicate	= X.[Criteria],
		@branchGroupIsCountable	= 0,
		@criteriaExist			= X.[CriteriaExist],
		@isExcluded				= X.[CriteriaIsExcluded],
		@criteriaIsNull			= X.[CriteriaIsNull],
		@criteriaValue			= X.[CriteriaValue],
		@criteriaValueExist		= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/BranchGroupPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @branchGroup TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner.Branch].[Group.Filter]
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
			@predicate		= @branchGroupPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@branches		= NULL,
			@isCountable	= @branchGroupIsCountable,
			@guids			= @branchGroupGuids			OUTPUT,
			@isExcluded		= @isExcluded				OUTPUT,
			@isFiltered		= @branchGroupIsFiltered	OUTPUT,
			@number			= @branchGroupNumber		OUTPUT;
		INSERT @branchGroup SELECT * FROM [Common].[Guid.Entities](@branchGroupGuids);
		IF (ISNULL([Common].[Bool.Entity](@predicate.query('/*/BranchGroupPredicate/BranchSplitIntersect')), 0) = 0) BEGIN
			IF (ISNULL([Common].[Bool.Entity](@predicate.query('/*/BranchGroupExclude')), 0) = 0) BEGIN
				IF (@branchGroupIsFiltered = 1) BEGIN
					IF (@isFiltered = 0)
						IF (@isExcluded = 0)
							INSERT @branch SELECT DISTINCT B.[BondBranchId] FROM [Owner.Branch].[Bond] B
							INNER JOIN	@branchGroup	X	ON	B.[BondGroupId]	= X.[Id];
						ELSE
							INSERT @branch SELECT DISTINCT B.[BondBranchId] FROM [Owner.Branch].[Bond] B
							LEFT JOIN	@branchGroup	X	ON	B.[BondGroupId]	= X.[Id]
							WHERE X.[Id] IS NULL;
				ELSE
					IF (@isExcluded = 0)
						DELETE X FROM @branch	X
						LEFT JOIN
						(
							SELECT DISTINCT B.[BondBranchId] 
							FROM [Owner.Branch].[Bond]	B
							INNER JOIN	@branchGroup	X	ON	B.[BondGroupId]	= X.[Id]
						)	G	ON	X.[Id]	= G.[BondBranchId]
						WHERE G.[BondBranchId] IS NULL;
					ELSE
						DELETE X FROM @branch	X
						LEFT JOIN
						(
							SELECT DISTINCT B.[BondBranchId] 
							FROM [Owner.Branch].[Bond]	B
							LEFT JOIN	@branchGroup	X	ON	B.[BondGroupId]	= X.[Id]
							WHERE X.[Id] IS NULL
						)	G	ON	X.[Id]	= G.[BondBranchId]
						WHERE G.[BondBranchId] IS NULL;
					SET @isFiltered = 1;
				END
			END
			ELSE BEGIN
				IF (@branchGroupIsFiltered = 1) BEGIN
					IF (@isFiltered = 0)
						IF (@isExcluded = 0)
							INSERT @branch SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
							LEFT JOIN 
							(
								SELECT DISTINCT B.[BondBranchId] 
								FROM [Owner.Branch].[Bond]	B
								INNER JOIN	@branchGroup	X	ON	B.[BondGroupId]	= X.[Id]
							)	G	ON	B.[BranchId]	= G.[BondBranchId]
							WHERE G.[BondBranchId] IS NULL;
						ELSE
							INSERT @branch SELECT DISTINCT B.[BranchId] FROM [Owner].[Branch] B
							LEFT JOIN 
							(
								SELECT DISTINCT B.[BondBranchId] 
								FROM [Owner.Branch].[Bond]	B
								LEFT JOIN	@branchGroup	X	ON	B.[BondGroupId]	= X.[Id]
								WHERE X.[Id] IS NULL
							)	G	ON	B.[BranchId]	= G.[BondBranchId]
							WHERE G.[BondBranchId] IS NULL;
					ELSE
						IF (@isExcluded = 0)
							DELETE X FROM @branch	X
							INNER JOIN
							(
								SELECT DISTINCT B.[BondBranchId] 
								FROM [Owner.Branch].[Bond]	B
								INNER JOIN	@branchGroup	X	ON	B.[BondGroupId]	= X.[Id]
							)	G	ON	X.[Id]	= G.[BondBranchId];
						ELSE
							DELETE X FROM @branch	X
							INNER JOIN
							(
								SELECT DISTINCT B.[BondBranchId] 
								FROM [Owner.Branch].[Bond]	B
								LEFT JOIN	@branchGroup	X	ON	B.[BondGroupId]	= X.[Id]
								WHERE X.[Id] IS NULL
							)	G	ON	X.[Id]	= G.[BondBranchId];
					SET @isFiltered = 1;
				END
			END
		END
		ELSE BEGIN
			IF (@branchGroupIsFiltered = 1) BEGIN
				SELECT @splitNumber = COUNT(DISTINCT G.[GroupSplitId]) FROM @branchGroup X
				INNER JOIN	[Owner.Branch].[Group]	G	ON	X.[Id] = G.[GroupId];
				IF (@isFiltered = 0)
					IF (@isExcluded = 0)
						INSERT @branch SELECT DISTINCT B.[BondBranchId]
						FROM [Owner.Branch].[Bond]			B
						INNER JOIN	[Owner.Branch].[Group]	G	ON	B.[BondGroupId]	= G.[GroupId]
						INNER JOIN	@branchGroup			X	ON	B.[BondGroupId]	= X.[Id]
						GROUP BY B.[BondBranchId]
						HAVING COUNT(DISTINCT G.[GroupSplitId]) = @splitNumber;
					ELSE
						INSERT @branch SELECT DISTINCT B.[BondBranchId]
						FROM [Owner.Branch].[Bond]			B
						INNER JOIN	[Owner.Branch].[Group]	G	ON	B.[BondGroupId]	= G.[GroupId]
						INNER JOIN	@branchGroup			X	ON	B.[BondGroupId]	= X.[Id]
						GROUP BY B.[BondBranchId]
						HAVING COUNT(DISTINCT G.[GroupSplitId]) <> @splitNumber;
				ELSE
					IF (@isExcluded = 0)
						DELETE X FROM @branch	X
						LEFT JOIN
						(
							SELECT DISTINCT B.[BondBranchId]
							FROM [Owner.Branch].[Bond]			B
							INNER JOIN	[Owner.Branch].[Group]	G	ON	B.[BondGroupId]	= G.[GroupId]
							INNER JOIN	@branchGroup			X	ON	B.[BondGroupId]	= X.[Id]
							GROUP BY B.[BondBranchId]
							HAVING COUNT(DISTINCT G.[GroupSplitId]) = @splitNumber
						)	B	ON	X.[Id]	= B.[BondBranchId]
						WHERE B.[BondBranchId] IS NULL;
					ELSE
						DELETE X FROM @branch	X
						LEFT JOIN
						(
							SELECT DISTINCT B.[BondBranchId]
							FROM [Owner.Branch].[Bond]			B
							INNER JOIN	[Owner.Branch].[Group]	G	ON	B.[BondGroupId]	= G.[GroupId]
							INNER JOIN	@branchGroup			X	ON	B.[BondGroupId]	= X.[Id]
							GROUP BY B.[BondBranchId]
							HAVING COUNT(DISTINCT G.[GroupSplitId]) <> @splitNumber
						)	B	ON	X.[Id]	= B.[BondBranchId]
						WHERE B.[BondBranchId] IS NULL;
				SET @isFiltered = 1;
			END
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @branch SELECT B.[BranchId] FROM [Owner].[Branch] B
			INNER JOIN	[Owner].[Organisation]	O	ON	B.[BranchOrganisationId]	= O.[OrganisationId]
			WHERE O.[OrganisationEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @branch	X
			LEFT JOIN
			(
				SELECT B.[BranchId] FROM [Owner].[Branch]	B
				INNER JOIN	[Owner].[Organisation]			O	ON	B.[BranchOrganisationId]	= O.[OrganisationId]
				WHERE O.[OrganisationEmplacementId] = @emplacementId
			)	B	ON	X.[Id]	= B.[BranchId]
			WHERE B.[BranchId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @branch X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Owner].[Branch] B;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @branch X;
		ELSE
			IF (@branches IS NOT NULL)
				SELECT @number = COUNT(*) FROM [Owner].[Branch] B
				INNER JOIN	[Owner].[Organisation]	O	ON	B.[BranchOrganisationId]	= O.[OrganisationId]
				INNER JOIN	@branchIds				XB	ON	B.[BranchId]				= XB.[Id]
				LEFT JOIN	@branch					X	ON	B.[BranchId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE
				IF (@organisations IS NULL)
					SELECT @number = COUNT(*) FROM [Owner].[Branch] B
					INNER JOIN	[Owner].[Organisation]	O	ON	B.[BranchOrganisationId]	= O.[OrganisationId]
					LEFT JOIN	@branch					X	ON	B.[BranchId]				= X.[Id]
					WHERE 
						O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
						X.[Id] IS NULL;
				ELSE
					SELECT @number = COUNT(*) FROM [Owner].[Branch] B
					INNER JOIN	[Owner].[Organisation]	O	ON	B.[BranchOrganisationId]	= O.[OrganisationId]
					INNER JOIN	@organisationIds		XO	ON	O.[OrganisationId]			= XO.[Id]
					LEFT JOIN	@branch					X	ON	B.[BranchId]				= X.[Id]
					WHERE 
						O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
						X.[Id] IS NULL;

END
GO
