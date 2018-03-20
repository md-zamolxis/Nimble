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
			O.[name]	= 'Log.Filter'))
	DROP PROCEDURE [Security].[Log.Filter];
GO

CREATE PROCEDURE [Security].[Log.Filter]
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

	DECLARE @log TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Logs')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Log');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Security].[Log.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @log SELECT * FROM @entities;
				ELSE
					INSERT @log SELECT L.[LogId] FROM [Security].[Log] L
					WHERE L.[LogId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @log X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @log X WHERE X.[Id] IN (SELECT * FROM @entities);
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
					INSERT @log SELECT L.[LogId] FROM [Security].[Log] L
					WHERE L.[LogCreatedOn] BETWEEN ISNULL(@dateFrom, L.[LogCreatedOn]) AND ISNULL(@dateTo, L.[LogCreatedOn]);
				ELSE 
					INSERT @log SELECT L.[LogId] FROM [Security].[Log] L
					WHERE L.[LogCreatedOn] NOT BETWEEN ISNULL(@dateFrom, L.[LogCreatedOn]) AND ISNULL(@dateTo, L.[LogCreatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @log	X
					LEFT JOIN
					(
						SELECT L.[LogId] FROM [Security].[Log] L
						WHERE L.[LogCreatedOn] BETWEEN ISNULL(@dateFrom, L.[LogCreatedOn]) AND ISNULL(@dateTo, L.[LogCreatedOn])
					)	L	ON	X.[Id]	= L.[LogId]
					WHERE L.[LogId] IS NULL;
				ELSE
					DELETE X FROM @log	X
					LEFT JOIN
					(
						SELECT L.[LogId] FROM [Security].[Log] L
						WHERE L.[LogCreatedOn] NOT BETWEEN ISNULL(@dateFrom, L.[LogCreatedOn]) AND ISNULL(@dateTo, L.[LogCreatedOn])
					)	L	ON	X.[Id]	= L.[LogId]
					WHERE L.[LogId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by log action types
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/LogActionTypes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @logActionTypes TABLE ([LogActionType] NVARCHAR(MAX));
		INSERT @logActionTypes SELECT DISTINCT * FROM [Common].[Enum.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @log SELECT DISTINCT L.[LogId] FROM [Security].[Log] L
					INNER JOIN	@logActionTypes		X	ON	L.[LogActionType]	LIKE X.[LogActionType];
				ELSE 
					INSERT @log SELECT DISTINCT L.[LogId] FROM [Security].[Log] L
					LEFT JOIN	@logActionTypes		X	ON	L.[LogActionType]	LIKE X.[LogActionType]
					WHERE X.[LogActionType] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @log	X
					LEFT JOIN
					(
						SELECT DISTINCT L.[LogId] FROM [Security].[Log] L
						INNER JOIN	@logActionTypes		X	ON	L.[LogActionType]	LIKE X.[LogActionType]
					)	L	ON	X.[Id]	= L.[LogId]
					WHERE L.[LogId] IS NULL;
				ELSE
					DELETE X FROM @log	X
					LEFT JOIN
					(
						SELECT DISTINCT L.[LogId] FROM [Security].[Log] L
						LEFT JOIN	@logActionTypes		X	ON	L.[LogActionType]	LIKE X.[LogActionType]
						WHERE X.[LogActionType] IS NULL
					)	L	ON	X.[Id]	= L.[LogId]
					WHERE L.[LogId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by comments
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Codes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @comments TABLE ([Comment] NVARCHAR(MAX));
		INSERT @comments SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @log SELECT DISTINCT L.[LogId] FROM [Security].[Log] L
					INNER JOIN	@comments	X	ON	L.[LogComment]	LIKE X.[Comment];
				ELSE 
					INSERT @log SELECT DISTINCT L.[LogId] FROM [Security].[Log] L
					LEFT JOIN	@comments	X	ON	L.[LogComment]	LIKE X.[Comment]
					WHERE X.[Comment] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @log	X
					LEFT JOIN
					(
						SELECT DISTINCT L.[LogId] FROM [Security].[Log] L
						INNER JOIN	@comments	X	ON	L.[LogComment]	LIKE X.[Comment]
					)	L	ON	X.[Id]	= L.[LogId]
					WHERE L.[LogId] IS NULL;
				ELSE
					DELETE X FROM @log	X
					LEFT JOIN
					(
						SELECT DISTINCT L.[LogId] FROM [Security].[Log] L
						LEFT JOIN	@comments	X	ON	L.[LogComment]	LIKE X.[Comment]
						WHERE X.[Comment] IS NULL
					)	L	ON	X.[Id]	= L.[LogId]
					WHERE L.[LogId] IS NULL;
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
					INSERT @log SELECT L.[LogId] FROM [Security].[Log] L
					INNER JOIN	@application	X	ON	L.[LogApplicationId]	= X.[Id];
				ELSE
					INSERT @log SELECT L.[LogId] FROM [Security].[Log] L
					LEFT JOIN	@application	X	ON	L.[LogApplicationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @log	X
					LEFT JOIN (
						SELECT L.[LogId] FROM [Security].[Log] L
						INNER JOIN	@application	X	ON	L.[LogApplicationId]	= X.[Id]
					)	L	ON	X.[Id]	= L.[LogId]
					WHERE L.[LogId] IS NULL;
				ELSE
					DELETE X FROM @log	X
					LEFT JOIN (
						SELECT L.[LogId] FROM [Security].[Log] L
						LEFT JOIN	@application	X	ON	L.[LogApplicationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	L	ON	X.[Id]	= L.[LogId]
					WHERE L.[LogId] IS NULL;
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
					INSERT @log SELECT L.[LogId] FROM [Security].[Log] L
					INNER JOIN	[Security].[Account]	A	ON	L.[LogAccountId]			= A.[AccountId]
					INNER JOIN	@account				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																A.[AccountApplicationId]	= X.[ApplicationId];
				ELSE
					INSERT @log SELECT L.[LogId] FROM [Security].[Log] L
					INNER JOIN	[Security].[Account]	A	ON	L.[LogAccountId]			= A.[AccountId]
					LEFT JOIN	@account				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																A.[AccountApplicationId]	= X.[ApplicationId]
					WHERE  COALESCE(X.[UserId], X.[ApplicationId]) IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @log	X
					LEFT JOIN (
						SELECT L.[LogId] FROM [Security].[Log]	L
						INNER JOIN	[Security].[Account]	A	ON	L.[LogAccountId]			= A.[AccountId]
						INNER JOIN	@account				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																	A.[AccountApplicationId]	= X.[ApplicationId]
					)	L	ON	X.[Id]	= L.[LogId]
					WHERE L.[LogId] IS NULL;
				ELSE
					DELETE X FROM @log	X
					LEFT JOIN (
						SELECT L.[LogId] FROM [Security].[Log]	L
						INNER JOIN	[Security].[Account]	A	ON	L.[LogAccountId]			= A.[AccountId]
						LEFT JOIN	@account				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																	A.[AccountApplicationId]	= X.[ApplicationId]
						WHERE  COALESCE(X.[UserId], X.[ApplicationId]) IS NULL
					)	L	ON	X.[Id]	= L.[LogId]
					WHERE L.[LogId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @log SELECT L.[LogId] FROM [Security].[Log] L
			INNER JOIN	[Security].[Account]	A	ON	L.[LogAccountId]	= A.[AccountId]
			INNER JOIN	[Security].[User]		U	ON	A.[AccountUserId]	= U.[UserId]
			WHERE U.[UserEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @log	X
			LEFT JOIN	(
				SELECT L.[LogId] FROM [Security].[Log] L
				INNER JOIN	[Security].[Account]	A	ON	L.[LogAccountId]	= A.[AccountId]
				INNER JOIN	[Security].[User]		U	ON	A.[AccountUserId]	= U.[UserId]
				WHERE U.[UserEmplacementId] = @emplacementId
			)	L	ON	X.[Id]	= L.[LogId]
			WHERE L.[LogId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by application
	IF (@applicationId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @log SELECT L.[LogId] FROM [Security].[Log] L
			WHERE L.[LogApplicationId] = @applicationId;
		ELSE
			DELETE X FROM @log	X
			LEFT JOIN	(
				SELECT L.[LogId] FROM [Security].[Log] L
				WHERE L.[LogApplicationId] = @applicationId
			)	L	ON	X.[Id]	= L.[LogId]
			WHERE L.[LogId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @log X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Security].[Log] L;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @log X;
		ELSE
			SELECT @number = COUNT(*) FROM [Security].[Log] L
			INNER JOIN	[Security].[Account]	A	ON	L.[LogAccountId]	= A.[AccountId]
			INNER JOIN	[Security].[User]		U	ON	A.[AccountUserId]	= U.[UserId]
			LEFT JOIN	@log					X	ON	L.[LogId]			= X.[Id]
			WHERE 
				U.[UserEmplacementId]	= ISNULL(@emplacementId, U.[UserEmplacementId])	AND
				L.[LogApplicationId]	= ISNULL(@applicationId, L.[LogApplicationId])	AND
				X.[Id] IS NULL;

END
GO
