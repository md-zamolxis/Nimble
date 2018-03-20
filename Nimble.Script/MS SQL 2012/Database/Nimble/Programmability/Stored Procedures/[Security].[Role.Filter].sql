SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Security'	AND
			O.[type]	= 'P'			AND
			O.[name]	= 'Role.Filter'))
	DROP PROCEDURE [Security].[Role.Filter];
GO

CREATE PROCEDURE [Security].[Role.Filter]
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

	DECLARE @role TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
	DECLARE 
		@criteria			XML,
		@criteriaExist		BIT,
		@criteriaIsNull		BIT,
		@criteriaValue		XML,
		@criteriaValueExist	BIT;
	
	SET @isFiltered = 0;

--	Filter by entities
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Roles')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Role');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Security].[Role.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @role SELECT * FROM @entities;
				ELSE
					INSERT @role SELECT R.[RoleId] FROM [Security].[Role] R
					WHERE R.[RoleId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @role X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @role X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

--	Filter by emplacement predicate
	DECLARE 
		@emplacementPredicate	XML,
		@emplacementIsCountable	BIT,
		@emplacementGuids		XML,
		@emplacementIsFiltered	BIT,
		@emplacementNumber		INT;
	SELECT 
		@emplacementPredicate	= X.[Criteria],
		@emplacementIsCountable	= 0,
		@criteriaExist			= X.[CriteriaExist],
		@isExcluded				= X.[CriteriaIsExcluded],
		@criteriaIsNull			= X.[CriteriaIsNull],
		@criteriaValue			= X.[CriteriaValue],
		@criteriaValueExist		= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/EmplacementPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @emplacement TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Security].[Emplacement.Filter]
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
			@predicate		= @emplacementPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @emplacementIsCountable,
			@guids			= @emplacementGuids			OUTPUT,
			@isExcluded		= @isExcluded				OUTPUT,
			@isFiltered		= @emplacementIsFiltered	OUTPUT,
			@number			= @emplacementNumber		OUTPUT;
		INSERT @emplacement SELECT * FROM [Common].[Guid.Entities](@emplacementGuids);
		IF (@emplacementIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @role SELECT R.[RoleId] FROM [Security].[Role] R
					INNER JOIN	@emplacement	X	ON	R.[RoleEmplacementId]	= X.[Id];
				ELSE
					INSERT @role SELECT R.[RoleId] FROM [Security].[Role] R
					LEFT JOIN	@emplacement	X	ON	R.[RoleEmplacementId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @role	X
					LEFT JOIN (
						SELECT R.[RoleId] FROM [Security].[Role] R
						INNER JOIN	@emplacement	X	ON	R.[RoleEmplacementId]	= X.[Id]
					)	R	ON	X.[Id]	= R.[RoleId]
					WHERE R.[RoleId] IS NULL;
				ELSE
					DELETE X FROM @role	X
					LEFT JOIN (
						SELECT R.[RoleId] FROM [Security].[Role] R
						LEFT JOIN	@emplacement	X	ON	R.[RoleEmplacementId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	R	ON	X.[Id]	= R.[RoleId]
					WHERE R.[RoleId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by application predicate
	DECLARE 
		@applicationPredicate	XML,
		@applicationIsCountable	BIT,
		@applicationGuids		XML,
		@applicationIsFiltered	BIT,
		@applicationNumber		INT;
	SELECT 
		@applicationPredicate	= X.[Criteria],
		@applicationIsCountable	= 0,
		@criteriaExist			= X.[CriteriaExist],
		@isExcluded				= X.[CriteriaIsExcluded],
		@criteriaIsNull			= X.[CriteriaIsNull],
		@criteriaValue			= X.[CriteriaValue],
		@criteriaValueExist		= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/ApplicationPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @application TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Security].[Application.Filter]
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
			@predicate		= @applicationPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @applicationIsCountable,
			@guids			= @applicationGuids			OUTPUT,
			@isExcluded		= @isExcluded				OUTPUT,
			@isFiltered		= @applicationIsFiltered	OUTPUT,
			@number			= @applicationNumber		OUTPUT;
		INSERT @application SELECT * FROM [Common].[Guid.Entities](@applicationGuids);
		IF (@applicationIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @role SELECT R.[RoleId] FROM [Security].[Role] R
					INNER JOIN	@application	X	ON	R.[RoleApplicationId]	= X.[Id];
				ELSE
					INSERT @role SELECT R.[RoleId] FROM [Security].[Role] R
					LEFT JOIN	@application	X	ON	R.[RoleApplicationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @role	X
					LEFT JOIN (
						SELECT R.[RoleId] FROM [Security].[Role] R
						INNER JOIN	@application	X	ON	R.[RoleApplicationId]	= X.[Id]
					)	R	ON	X.[Id]	= R.[RoleId]
					WHERE R.[RoleId] IS NULL;
				ELSE
					DELETE X FROM @role	X
					LEFT JOIN (
						SELECT R.[RoleId] FROM [Security].[Role] R
						LEFT JOIN	@application	X	ON	R.[RoleApplicationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	R	ON	X.[Id]	= R.[RoleId]
					WHERE R.[RoleId] IS NULL;
			SET @isFiltered = 1;
		END
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
					INSERT @role SELECT DISTINCT R.[RoleId] FROM [Security].[Role] R
					INNER JOIN	@codes	X	ON	R.[RoleCode]	LIKE X.[Code];
				ELSE 
					INSERT @role SELECT DISTINCT R.[RoleId] FROM [Security].[Role] R
					LEFT JOIN	@codes	X	ON	R.[RoleCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @role	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[RoleId] FROM [Security].[Role] R
						INNER JOIN	@codes	X	ON	R.[RoleCode]	LIKE X.[Code]
					)	R	ON	X.[Id]	= R.[RoleId]
					WHERE R.[RoleId] IS NULL;
				ELSE
					DELETE X FROM @role	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[RoleId] FROM [Security].[Role] R
						LEFT JOIN	@codes	X	ON	R.[RoleCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	R	ON	X.[Id]	= R.[RoleId]
					WHERE R.[RoleId] IS NULL;
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
					INSERT @role SELECT DISTINCT R.[RoleId] FROM [Security].[Role] R
					INNER JOIN	@descriptions	X	ON	R.[RoleDescription]	LIKE X.[Description];
				ELSE 
					INSERT @role SELECT DISTINCT R.[RoleId] FROM [Security].[Role] R
					LEFT JOIN	@descriptions	X	ON	R.[RoleDescription]	LIKE X.[Description]
					WHERE X.[Description] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @role	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[RoleId] FROM [Security].[Role] R
						INNER JOIN	@descriptions	X	ON	R.[RoleDescription]	LIKE X.[Description]
					)	R	ON	X.[Id]	= R.[RoleId]
					WHERE R.[RoleId] IS NULL;
				ELSE
					DELETE X FROM @role	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[RoleId] FROM [Security].[Role] R
						LEFT JOIN	@descriptions	X	ON	R.[RoleDescription]	LIKE X.[Description]
						WHERE X.[Description] IS NULL
					)	R	ON	X.[Id]	= R.[RoleId]
					WHERE R.[RoleId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by permission predicate
	DECLARE 
		@permissionPredicate	XML,
		@permissionIsCountable	BIT,
		@permissionGuids		XML,
		@permissionIsFiltered	BIT,
		@permissionNumber		INT;
	SELECT 
		@permissionPredicate	= X.[Criteria],
		@permissionIsCountable	= 0,
		@criteriaExist			= X.[CriteriaExist],
		@isExcluded				= X.[CriteriaIsExcluded],
		@criteriaIsNull			= X.[CriteriaIsNull],
		@criteriaValue			= X.[CriteriaValue],
		@criteriaValueExist		= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/PermissionPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @permission TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Security].[Permission.Filter]
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
			@predicate		= @permissionPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @permissionIsCountable,
			@guids			= @permissionGuids		OUTPUT,
			@isExcluded		= @isExcluded			OUTPUT,
			@isFiltered		= @permissionIsFiltered	OUTPUT,
			@number			= @permissionNumber		OUTPUT;
		INSERT @permission SELECT * FROM [Common].[Guid.Entities](@permissionGuids);
		IF (@permissionIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @role SELECT DISTINCT RP.[RolePermissionRoleId] FROM [Security].[RolePermission] RP
					INNER JOIN	@permission	X	ON	RP.[RolePermissionPermissionId]	= X.[Id];
				ELSE
					INSERT @role SELECT DISTINCT RP.[RolePermissionRoleId] FROM [Security].[RolePermission] RP
					LEFT JOIN	@permission	X	ON	RP.[RolePermissionPermissionId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @role	X
					LEFT JOIN (
						SELECT DISTINCT RP.[RolePermissionRoleId] FROM [Security].[RolePermission] RP
						INNER JOIN	@permission	X	ON	RP.[RolePermissionPermissionId]	= X.[Id]
					)	RP	ON	X.[Id]	= RP.[RolePermissionRoleId]
					WHERE RP.[RolePermissionRoleId] IS NULL;
				ELSE
					DELETE X FROM @role	X
					LEFT JOIN (
						SELECT DISTINCT RP.[RolePermissionRoleId] FROM [Security].[RolePermission] RP
						LEFT JOIN	@permission	X	ON	RP.[RolePermissionPermissionId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	RP	ON	X.[Id]	= RP.[RolePermissionRoleId]
					WHERE RP.[RolePermissionRoleId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by account predicate
	DECLARE 
		@accountPredicate	XML,
		@accountIsCountable	BIT,
		@accountGuids		XML,
		@accountIsFiltered	BIT,
		@accountNumber		INT;
	SELECT 
		@accountPredicate	= X.[Criteria],
		@accountIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/AccountPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @account TABLE
		(
			[UserId]		UNIQUEIDENTIFIER,
			[ApplicationId]	UNIQUEIDENTIFIER,
			PRIMARY KEY CLUSTERED 
			(
				[UserId],
				[ApplicationId]
			)
		);
		EXEC sp_executesql 
			N'EXEC [Security].[Account.Filter]
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
			@predicate		= @accountPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @accountIsCountable,
			@guids			= @accountGuids			OUTPUT,
			@isExcluded		= @isExcluded			OUTPUT,
			@isFiltered		= @accountIsFiltered	OUTPUT,
			@number			= @accountNumber		OUTPUT;
		INSERT @account
		SELECT 
			LTRIM(X.[Entity].value('(UserId/text())[1]',		'UNIQUEIDENTIFIER')) [UserId],
			LTRIM(X.[Entity].value('(ApplicationId/text())[1]',	'UNIQUEIDENTIFIER')) [ApplicationId]
		FROM @accountGuids.nodes('/*/guid') X ([Entity]);
		IF (@accountIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @role SELECT DISTINCT AR.[AccountRoleRoleId] FROM [Security].[AccountRole] AR
					INNER JOIN	[Security].[Account]	A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
					INNER JOIN	@account				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																A.[AccountApplicationId]	= X.[ApplicationId];
				ELSE
					INSERT @role SELECT DISTINCT AR.[AccountRoleRoleId] FROM [Security].[AccountRole] AR
					INNER JOIN	[Security].[Account]	A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
					LEFT JOIN	@account				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																A.[AccountApplicationId]	= X.[ApplicationId]
					WHERE COALESCE(X.[UserId], X.[ApplicationId]) IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @role	X
					LEFT JOIN (
						SELECT DISTINCT AR.[AccountRoleRoleId] FROM [Security].[AccountRole] AR
						INNER JOIN	[Security].[Account]	A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
						INNER JOIN	@account				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																	A.[AccountApplicationId]	= X.[ApplicationId]
					)	AR	ON	X.[Id]	= AR.[AccountRoleRoleId]
					WHERE AR.[AccountRoleRoleId] IS NULL;
				ELSE
					DELETE X FROM @role	X
					LEFT JOIN (
							SELECT DISTINCT AR.[AccountRoleRoleId] FROM [Security].[AccountRole] AR
						INNER JOIN	[Security].[Account]	A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
						LEFT JOIN	@account				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																	A.[AccountApplicationId]	= X.[ApplicationId]
						WHERE COALESCE(X.[UserId], X.[ApplicationId]) IS NULL
					)	AR	ON	X.[Id]	= AR.[AccountRoleRoleId]
					WHERE AR.[AccountRoleRoleId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @role SELECT R.[RoleId] FROM [Security].[Role] R
			WHERE R.[RoleEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @role	X
			LEFT JOIN	(
				SELECT R.[RoleId] FROM [Security].[Role] R
				WHERE R.[RoleEmplacementId] = @emplacementId
			)	R	ON	X.[Id]	= R.[RoleId]
			WHERE R.[RoleId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by application
	IF (@applicationId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @role SELECT R.[RoleId] FROM [Security].[Role] R
			WHERE R.[RoleApplicationId] = @applicationId;
		ELSE
			DELETE X FROM @role	X
			LEFT JOIN	(
				SELECT R.[RoleId] FROM [Security].[Role] R
				WHERE R.[RoleApplicationId] = @applicationId
			)	R	ON	X.[Id]	= R.[RoleId]
			WHERE R.[RoleId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @role X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Security].[Role] R;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @role X;
		ELSE
			SELECT @number = COUNT(*) FROM [Security].[Role] R
			LEFT JOIN	@role	X	ON	R.[RoleId] = X.[Id]
			WHERE 
				R.[RoleEmplacementId] = ISNULL(@emplacementId, R.[RoleEmplacementId])	AND
				R.[RoleApplicationId] = ISNULL(@applicationId, R.[RoleApplicationId])	AND
				X.[Id] IS NULL;

END
GO
