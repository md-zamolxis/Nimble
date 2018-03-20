SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'P'		AND
			O.[name]	= 'Preset.Filter'))
	DROP PROCEDURE [Common].[Preset.Filter];
GO

CREATE PROCEDURE [Common].[Preset.Filter]
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
	
	DECLARE @preset TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
	DECLARE 
		@criteria			XML,
		@criteriaExist		BIT,
		@criteriaIsNull		BIT,
		@criteriaValue		XML,
		@criteriaValueExist	BIT,
		@amountFrom			DECIMAL(28, 9),
		@amountTo			DECIMAL(28, 9);
	
	SET @isFiltered = 0;

--	Filter by entities
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Presets')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Preset');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Common].[Preset.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @preset SELECT * FROM @entities;
				ELSE
					INSERT @preset SELECT P.[PresetId] FROM [Common].[Preset] P
					WHERE P.[PresetId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @preset X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @preset X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
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
					INSERT @preset SELECT P.[PresetId] FROM [Common].[Preset] P
					INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]			= A.[AccountId]
					INNER JOIN	@account				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																A.[AccountApplicationId]	= X.[ApplicationId];
				ELSE
					INSERT @preset SELECT P.[PresetId] FROM [Common].[Preset] P
					INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]			= A.[AccountId]
					LEFT JOIN	@account				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																A.[AccountApplicationId]	= X.[ApplicationId]
					WHERE  COALESCE(X.[UserId], X.[ApplicationId]) IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @preset	X
					LEFT JOIN (
						SELECT P.[PresetId] FROM [Common].[Preset]	P
						INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]			= A.[AccountId]
						INNER JOIN	@account				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																	A.[AccountApplicationId]	= X.[ApplicationId]
					)	P	ON	X.[Id]	= P.[PresetId]
					WHERE P.[PresetId] IS NULL;
				ELSE
					DELETE X FROM @preset	X
					LEFT JOIN (
						SELECT P.[PresetId] FROM [Common].[Preset]	P
						INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]			= A.[AccountId]
						LEFT JOIN	@account				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																	A.[AccountApplicationId]	= X.[ApplicationId]
						WHERE  COALESCE(X.[UserId], X.[ApplicationId]) IS NULL
					)	P	ON	X.[Id]	= P.[PresetId]
					WHERE P.[PresetId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @preset SELECT P.[PresetId] FROM [Common].[Preset]	P
			INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]	= A.[AccountId]
			INNER JOIN	[Security].[User]		U	ON	A.[AccountUserId]	= U.[UserId]
			WHERE U.[UserEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @preset	X
			LEFT JOIN	(
				SELECT P.[PresetId] FROM [Common].[Preset]	P
				INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]	= A.[AccountId]
				INNER JOIN	[Security].[User]		U	ON	A.[AccountUserId]	= U.[UserId]
				WHERE U.[UserEmplacementId] = @emplacementId
			)	P	ON	X.[Id]	= P.[PresetId]
			WHERE P.[PresetId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by application
	IF (@applicationId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @preset SELECT P.[PresetId] FROM [Common].[Preset]	P
			INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]	= A.[AccountId]
			WHERE A.[AccountApplicationId] = @applicationId;
		ELSE
			DELETE X FROM @preset	X
			LEFT JOIN	(
				SELECT P.[PresetId] FROM [Common].[Preset]	P
				INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]	= A.[AccountId]
				WHERE A.[AccountApplicationId] = @applicationId
			)	P	ON	X.[Id]	= P.[PresetId]
			WHERE P.[PresetId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by preset entity types
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/PresetEntityTypes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @presetEntityTypes TABLE ([PresetEntityType] NVARCHAR(MAX));
		INSERT @presetEntityTypes SELECT DISTINCT * FROM [Common].[Enum.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @preset SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
					INNER JOIN	@presetEntityTypes		X	ON	P.[PresetEntityType]	LIKE X.[PresetEntityType];
				ELSE 
					INSERT @preset SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
					LEFT JOIN	@presetEntityTypes		X	ON	P.[PresetEntityType]	LIKE X.[PresetEntityType]
					WHERE X.[PresetEntityType] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @preset	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
						INNER JOIN	@presetEntityTypes		X	ON	P.[PresetEntityType]	LIKE X.[PresetEntityType]
					)	P	ON	X.[Id]	= P.[PresetId]
					WHERE P.[PresetId] IS NULL;
				ELSE
					DELETE X FROM @preset	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
						LEFT JOIN	@presetEntityTypes		X	ON	P.[PresetEntityType]	LIKE X.[PresetEntityType]
						WHERE X.[PresetEntityType] IS NULL
					)	P	ON	X.[Id]	= P.[PresetId]
					WHERE P.[PresetId] IS NULL;
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
					INSERT @preset SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
					INNER JOIN	@codes	X	ON	P.[PresetCode]	LIKE X.[Code];
				ELSE 
					INSERT @preset SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
					LEFT JOIN	@codes	X	ON	P.[PresetCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @preset	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
						INNER JOIN	@codes	X	ON	P.[PresetCode]	LIKE X.[Code]
					)	P	ON	X.[Id]	= P.[PresetId]
					WHERE P.[PresetId] IS NULL;
				ELSE
					DELETE X FROM @preset	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
						LEFT JOIN	@codes	X	ON	P.[PresetCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	P	ON	X.[Id]	= P.[PresetId]
					WHERE P.[PresetId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by category
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Category')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @amountFrom = NULL, @amountTo = NULL;
		SELECT 
			@amountFrom	= X.[AmountFrom], 
			@amountTo	= X.[AmountTo] 
		FROM [Common].[AmountInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@amountFrom, @amountTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @preset SELECT P.[PresetId] FROM [Common].[Preset] P
					WHERE P.[PresetCategory] BETWEEN ISNULL(@amountFrom, P.[PresetCategory]) AND ISNULL(@amountTo, P.[PresetCategory]);
				ELSE 
					INSERT @preset SELECT P.[PresetId] FROM [Common].[Preset] P
					WHERE P.[PresetCategory] NOT BETWEEN ISNULL(@amountFrom, P.[PresetCategory]) AND ISNULL(@amountTo, P.[PresetCategory]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @preset	X
					LEFT JOIN
					(
						SELECT P.[PresetId] FROM [Common].[Preset] P
						WHERE P.[PresetCategory] BETWEEN ISNULL(@amountFrom, P.[PresetCategory]) AND ISNULL(@amountTo, P.[PresetCategory])
					)	P	ON	X.[Id]	= P.[PresetId]
					WHERE P.[PresetId] IS NULL;
				ELSE
					DELETE X FROM @preset	X
					LEFT JOIN
					(
						SELECT P.[PresetId] FROM [Common].[Preset] P
						WHERE P.[PresetCategory] NOT BETWEEN ISNULL(@amountFrom, P.[PresetCategory]) AND ISNULL(@amountTo, P.[PresetCategory])
					)	P	ON	X.[Id]	= P.[PresetId]
					WHERE P.[PresetId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by default status
	DECLARE @isDefault BIT;
	SET @isDefault = [Common].[Bool.Entity](@predicate.query('/*/IsDefault'));
	IF (@isDefault IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @preset SELECT P.[PresetId] FROM [Common].[Preset] P
			WHERE P.[PresetIsDefault] = @isDefault;
		ELSE
			DELETE X FROM @preset	X
			LEFT JOIN
			(
				SELECT P.[PresetId] FROM [Common].[Preset] P
				WHERE P.[PresetIsDefault] = @isDefault
			)	P	ON	X.[Id]	= P.[PresetId]
			WHERE P.[PresetId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by instantly status
	DECLARE @isInstantly BIT;
	SET @isInstantly = [Common].[Bool.Entity](@predicate.query('/*/IsInstantly'));
	IF (@isInstantly IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @preset SELECT P.[PresetId] FROM [Common].[Preset] P
			WHERE P.[PresetIsInstantly] = @isInstantly;
		ELSE
			DELETE X FROM @preset	X
			LEFT JOIN
			(
				SELECT P.[PresetId] FROM [Common].[Preset] P
				WHERE P.[PresetIsInstantly] = @isInstantly
			)	P	ON	X.[Id]	= P.[PresetId]
			WHERE P.[PresetId] IS NULL;
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
					INSERT @preset SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
					INNER JOIN	@descriptions	X	ON	P.[PresetDescription]	LIKE X.[Description];
				ELSE 
					INSERT @preset SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
					LEFT JOIN	@descriptions	X	ON	P.[PresetDescription]	LIKE X.[Description]
					WHERE X.[Description] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @preset	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
						INNER JOIN	@descriptions	X	ON	P.[PresetDescription]	LIKE X.[Description]
					)	P	ON	X.[Id]	= P.[PresetId]
					WHERE P.[PresetId] IS NULL;
				ELSE
					DELETE X FROM @preset	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
						LEFT JOIN	@descriptions	X	ON	P.[PresetDescription]	LIKE X.[Description]
						WHERE X.[Description] IS NULL
					)	P	ON	X.[Id]	= P.[PresetId]
					WHERE P.[PresetId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @preset X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Common].[Preset] P;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @preset X;
		ELSE
			SELECT @number = COUNT(*) FROM [Common].[Preset]	P
			INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]	= A.[AccountId]
			INNER JOIN	[Security].[User]		U	ON	A.[AccountUserId]	= U.[UserId]
			LEFT JOIN	@preset					X	ON	P.[PresetId]		= X.[Id]
			WHERE 
				U.[UserEmplacementId]		= ISNULL(@emplacementId, U.[UserEmplacementId])		AND
				A.[AccountApplicationId]	= ISNULL(@applicationId, A.[AccountApplicationId])	AND
				X.[Id] IS NULL;

END
GO
