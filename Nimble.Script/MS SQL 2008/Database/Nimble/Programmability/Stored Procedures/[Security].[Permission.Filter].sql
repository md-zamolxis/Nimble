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
			O.[name]	= 'Permission.Filter'))
	DROP PROCEDURE [Security].[Permission.Filter];
GO

CREATE PROCEDURE [Security].[Permission.Filter]
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

	DECLARE @permission TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Permissions')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Permission');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Security].[Permission.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @permission SELECT * FROM @entities;
				ELSE
					INSERT @permission SELECT P.[PermissionId] FROM [Security].[Permission] P
					WHERE P.[PermissionId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @permission X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @permission X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
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
					INSERT @permission SELECT P.[PermissionId] FROM [Security].[Permission] P
					INNER JOIN	@application	X	ON	P.[PermissionApplicationId]	= X.[Id];
				ELSE
					INSERT @permission SELECT P.[PermissionId] FROM [Security].[Permission] P
					LEFT JOIN	@application	X	ON	P.[PermissionApplicationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @permission	X
					LEFT JOIN (
						SELECT P.[PermissionId] FROM [Security].[Permission] P
						INNER JOIN	@application	X	ON	P.[PermissionApplicationId]	= X.[Id]
					)	P	ON	X.[Id]	= P.[PermissionId]
					WHERE P.[PermissionId] IS NULL;
				ELSE
					DELETE X FROM @permission	X
					LEFT JOIN (
						SELECT P.[PermissionId] FROM [Security].[Permission] P
						LEFT JOIN	@application	X	ON	P.[PermissionApplicationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	P	ON	X.[Id]	= P.[PermissionId]
					WHERE P.[PermissionId] IS NULL;
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
					INSERT @permission SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
					INNER JOIN	@codes	X	ON	P.[PermissionCode]	LIKE X.[Code];
				ELSE 
					INSERT @permission SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
					LEFT JOIN	@codes	X	ON	P.[PermissionCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @permission	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
						INNER JOIN	@codes	X	ON	P.[PermissionCode]	LIKE X.[Code]
					)	P	ON	X.[Id]	= P.[PermissionId]
					WHERE P.[PermissionId] IS NULL;
				ELSE
					DELETE X FROM @permission	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
						LEFT JOIN	@codes	X	ON	P.[PermissionCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	P	ON	X.[Id]	= P.[PermissionId]
					WHERE P.[PermissionId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by categories
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Categories')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @categories TABLE ([Category] NVARCHAR(MAX));
		INSERT @categories SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @permission SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
					INNER JOIN	@categories	X	ON	P.[PermissionCategory]	LIKE X.[Category];
				ELSE 
					INSERT @permission SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
					LEFT JOIN	@categories	X	ON	P.[PermissionCategory]	LIKE X.[Category]
					WHERE X.[Category] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @permission	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
						INNER JOIN	@categories	X	ON	P.[PermissionCategory]	LIKE X.[Category]
					)	P	ON	X.[Id]	= P.[PermissionId]
					WHERE P.[PermissionId] IS NULL;
				ELSE
					DELETE X FROM @permission	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
						LEFT JOIN	@categories	X	ON	P.[PermissionCategory]	LIKE X.[Category]
						WHERE X.[Category] IS NULL
					)	P	ON	X.[Id]	= P.[PermissionId]
					WHERE P.[PermissionId] IS NULL;
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
					INSERT @permission SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
					INNER JOIN	@descriptions	X	ON	P.[PermissionDescription]	LIKE X.[Description];
				ELSE 
					INSERT @permission SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
					LEFT JOIN	@descriptions	X	ON	P.[PermissionDescription]	LIKE X.[Description]
					WHERE X.[Description] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @permission	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
						INNER JOIN	@descriptions	X	ON	P.[PermissionDescription]	LIKE X.[Description]
					)	P	ON	X.[Id]	= P.[PermissionId]
					WHERE P.[PermissionId] IS NULL;
				ELSE
					DELETE X FROM @permission	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
						LEFT JOIN	@descriptions	X	ON	P.[PermissionDescription]	LIKE X.[Description]
						WHERE X.[Description] IS NULL
					)	P	ON	X.[Id]	= P.[PermissionId]
					WHERE P.[PermissionId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by role predicate
	DECLARE 
		@rolePredicate		XML,
		@roleIsCountable	BIT,
		@roleGuids			XML,
		@roleIsFiltered		BIT,
		@roleNumber			INT;
	SELECT 
		@rolePredicate		= X.[Criteria],
		@roleIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/RolePredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @role TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Security].[Role.Filter]
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
			@predicate		= @rolePredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @roleIsCountable,
			@guids			= @roleGuids		OUTPUT,
			@isExcluded		= @isExcluded		OUTPUT,
			@isFiltered		= @roleIsFiltered	OUTPUT,
			@number			= @roleNumber		OUTPUT;
		INSERT @role SELECT * FROM [Common].[Guid.Entities](@roleGuids);
		IF (@roleIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @permission SELECT DISTINCT RP.[RolePermissionPermissionId] FROM [Security].[RolePermission] RP
					INNER JOIN	@role	X	ON	RP.[RolePermissionRoleId]	= X.[Id];
				ELSE
					INSERT @permission SELECT DISTINCT RP.[RolePermissionPermissionId] FROM [Security].[RolePermission] RP
					LEFT JOIN	@role	X	ON	RP.[RolePermissionRoleId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @permission	X
					LEFT JOIN (
						SELECT DISTINCT RP.[RolePermissionPermissionId] FROM [Security].[RolePermission] RP
						INNER JOIN	@role	X	ON	RP.[RolePermissionRoleId]	= X.[Id]
					)	RP	ON	X.[Id]	= RP.[RolePermissionPermissionId]
					WHERE RP.[RolePermissionPermissionId] IS NULL;
				ELSE
					DELETE X FROM @permission	X
					LEFT JOIN (
						SELECT DISTINCT RP.[RolePermissionPermissionId] FROM [Security].[RolePermission] RP
						LEFT JOIN	@role	X	ON	RP.[RolePermissionRoleId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	RP	ON	X.[Id]	= RP.[RolePermissionPermissionId]
					WHERE RP.[RolePermissionPermissionId] IS NULL;
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
					INSERT @permission SELECT DISTINCT RP.[RolePermissionPermissionId] FROM [Security].[RolePermission] RP
					INNER JOIN	[Security].[AccountRole]	AR	ON	RP.[RolePermissionRoleId]	= AR.[AccountRoleRoleId]
					INNER JOIN	[Security].[Account]		A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
					INNER JOIN	@account					X	ON	A.[AccountUserId]			= X.[UserId]	AND
																	A.[AccountApplicationId]	= X.[ApplicationId];
				ELSE
					INSERT @permission SELECT DISTINCT RP.[RolePermissionPermissionId] FROM [Security].[RolePermission] RP
					INNER JOIN	[Security].[AccountRole]	AR	ON	RP.[RolePermissionRoleId]	= AR.[AccountRoleRoleId]
					INNER JOIN	[Security].[Account]		A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
					LEFT JOIN	@account					X	ON	A.[AccountUserId]			= X.[UserId]	AND
																	A.[AccountApplicationId]	= X.[ApplicationId]
					WHERE COALESCE(X.[UserId], X.[ApplicationId]) IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @permission	X
					LEFT JOIN (
						SELECT DISTINCT RP.[RolePermissionPermissionId] FROM [Security].[RolePermission]	RP
						INNER JOIN	[Security].[AccountRole]	AR	ON	RP.[RolePermissionRoleId]	= AR.[AccountRoleRoleId]
						INNER JOIN	[Security].[Account]		A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
						INNER JOIN	@account					X	ON	A.[AccountUserId]			= X.[UserId]	AND
																		A.[AccountApplicationId]	= X.[ApplicationId]
					)	RP	ON	X.[Id]	= RP.[RolePermissionPermissionId]
					WHERE RP.[RolePermissionPermissionId] IS NULL;
				ELSE
					DELETE X FROM @permission	X
					LEFT JOIN (
						SELECT DISTINCT RP.[RolePermissionPermissionId] FROM [Security].[RolePermission]	RP
						INNER JOIN	[Security].[AccountRole]	AR	ON	RP.[RolePermissionRoleId]	= AR.[AccountRoleRoleId]
						INNER JOIN	[Security].[Account]		A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
						LEFT JOIN	@account					X	ON	A.[AccountUserId]			= X.[UserId]	AND
																		A.[AccountApplicationId]	= X.[ApplicationId]
						WHERE COALESCE(X.[UserId], X.[ApplicationId]) IS NULL
					)	RP	ON	X.[Id]	= RP.[RolePermissionPermissionId]
					WHERE RP.[RolePermissionPermissionId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by application
	IF (@applicationId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @permission SELECT P.[PermissionId] FROM [Security].[Permission] P
			WHERE P.[PermissionApplicationId] = @applicationId;
		ELSE
			DELETE X FROM @permission	X
			LEFT JOIN	(
				SELECT P.[PermissionId] FROM [Security].[Permission] P
				WHERE P.[PermissionApplicationId] = @applicationId
			)	P	ON	X.[Id]	= P.[PermissionId]
			WHERE P.[PermissionId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @permission X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Security].[Permission] P;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @permission X;
		ELSE
			SELECT @number = COUNT(*) FROM [Security].[Permission] P
			LEFT JOIN	@permission	X	ON	P.[PermissionId] = X.[Id]
			WHERE 
				P.[PermissionApplicationId] = ISNULL(@applicationId, P.[PermissionApplicationId])	AND
				X.[Id] IS NULL;

END
GO
