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
			O.[name]	= 'Account.Filter'))
	DROP PROCEDURE [Security].[Account.Filter];
GO

CREATE PROCEDURE [Security].[Account.Filter]
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
	
	DECLARE 
		@criteria			XML,
		@criteriaExist		BIT,
		@criteriaIsNull		BIT,
		@criteriaValue		XML,
		@criteriaValueExist	BIT,
		@dateFrom			DATETIMEOFFSET,
		@dateTo				DATETIMEOFFSET,
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Accounts')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Account');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Security].[Account.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @account SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account]	A
					INNER JOIN	@entities				X	ON	A.[AccountId]	= X.[Id];
				ELSE
					INSERT @account SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account]	A
					LEFT JOIN	@entities				X	ON	A.[AccountId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @account	X
					LEFT JOIN
					(
						SELECT 
							A.[UserId],
							A.[ApplicationId]
						FROM [Security].[Entity.Account]	A
						INNER JOIN	@entities				X	ON	A.[AccountId]	= X.[Id]
					)	A	ON	X.[UserId]			= A.[UserId]	AND
								X.[ApplicationId]	= A.[ApplicationId]
					WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
				ELSE
					DELETE X FROM @account	X
					LEFT JOIN
					(
						SELECT 
							A.[UserId],
							A.[ApplicationId]
						FROM [Security].[Entity.Account]	A
						LEFT JOIN	@entities				X	ON	A.[AccountId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	A	ON	X.[UserId]			= A.[UserId]	AND
							X.[ApplicationId]	= A.[ApplicationId]
					WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by user predicate
	DECLARE 
		@userPredicate		XML,
		@userIsCountable	BIT,
		@userGuids			XML,
		@userIsFiltered		BIT,
		@userNumber			INT;
	SELECT 
		@userPredicate		= X.[Criteria],
		@userIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/UserPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @user TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Security].[User.Filter]
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
			@predicate		= @userPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @userIsCountable,
			@guids			= @userGuids		OUTPUT,
			@isExcluded		= @isExcluded		OUTPUT,
			@isFiltered		= @userIsFiltered	OUTPUT,
			@number			= @userNumber		OUTPUT;
		INSERT @user SELECT * FROM [Common].[Guid.Entities](@userGuids);
		IF (@userIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @account SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account]	A
					INNER JOIN	@user					X	ON	A.[AccountUserId]	= X.[Id];
				ELSE
					INSERT @account SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account]	A
					LEFT JOIN	@user					X	ON	A.[AccountUserId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @account	X
					LEFT JOIN
					(
						SELECT 
							A.[UserId],
							A.[ApplicationId]
						FROM [Security].[Entity.Account]	A
						INNER JOIN	@user					X	ON	A.[AccountUserId]	= X.[Id]
					)	A	ON	X.[UserId]			= A.[UserId]	AND
								X.[ApplicationId]	= A.[ApplicationId]
					WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
				ELSE
					DELETE X FROM @account	X
					LEFT JOIN
					(
						SELECT 
							A.[UserId],
							A.[ApplicationId]
						FROM [Security].[Entity.Account]	A
						LEFT JOIN	@user					X	ON	A.[AccountUserId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	A	ON	X.[UserId]			= A.[UserId]	AND
								X.[ApplicationId]	= A.[ApplicationId]
					WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
			SET @isFiltered = 1;
		END
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
					INSERT @account SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account] A
					WHERE A.[AccountLockedOn] BETWEEN ISNULL(@dateFrom, A.[AccountLockedOn]) AND ISNULL(@dateTo, A.[AccountLockedOn]);
				ELSE 
					INSERT @account SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account] A
					WHERE A.[AccountLockedOn] NOT BETWEEN ISNULL(@dateFrom, A.[AccountLockedOn]) AND ISNULL(@dateTo, A.[AccountLockedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @account	X
					LEFT JOIN
					(
						SELECT 
							A.[UserId],
							A.[ApplicationId]
						FROM [Security].[Entity.Account] A
						WHERE A.[AccountLockedOn] BETWEEN ISNULL(@dateFrom, A.[AccountLockedOn]) AND ISNULL(@dateTo, A.[AccountLockedOn])
					)	A	ON	X.[UserId]			= A.[UserId]	AND
								X.[ApplicationId]	= A.[ApplicationId]
					WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
				ELSE
					DELETE X FROM @account	X
					LEFT JOIN
					(
						SELECT 
							A.[UserId],
							A.[ApplicationId]
						FROM [Security].[Entity.Account] A
						WHERE A.[AccountLockedOn] NOT BETWEEN ISNULL(@dateFrom, A.[AccountLockedOn]) AND ISNULL(@dateTo, A.[AccountLockedOn])
					)	A	ON	X.[UserId]			= A.[UserId]	AND
								X.[ApplicationId]	= A.[ApplicationId]
					WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/LastUsedOn')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @dateFrom = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @account SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account] A
					WHERE A.[AccountLastUsedOn] BETWEEN ISNULL(@dateFrom, A.[AccountLastUsedOn]) AND ISNULL(@dateTo, A.[AccountLastUsedOn]);
				ELSE 
					INSERT @account SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account] A
					WHERE A.[AccountLastUsedOn] NOT BETWEEN ISNULL(@dateFrom, A.[AccountLastUsedOn]) AND ISNULL(@dateTo, A.[AccountLastUsedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @account	X
					LEFT JOIN
					(
						SELECT 
							A.[UserId],
							A.[ApplicationId]
						FROM [Security].[Entity.Account] A
						WHERE A.[AccountLastUsedOn] BETWEEN ISNULL(@dateFrom, A.[AccountLastUsedOn]) AND ISNULL(@dateTo, A.[AccountLastUsedOn])
					)	A	ON	X.[UserId]			= A.[UserId]	AND
								X.[ApplicationId]	= A.[ApplicationId]
					WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
				ELSE
					DELETE X FROM @account	X
					LEFT JOIN
					(
						SELECT 
							A.[UserId],
							A.[ApplicationId]
						FROM [Security].[Entity.Account] A
						WHERE A.[AccountLastUsedOn] NOT BETWEEN ISNULL(@dateFrom, A.[AccountLastUsedOn]) AND ISNULL(@dateTo, A.[AccountLastUsedOn])
					)	A	ON	X.[UserId]			= A.[UserId]	AND
								X.[ApplicationId]	= A.[ApplicationId]
					WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by sessions
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Sessions')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @amountFrom = NULL, @amountTo = NULL;
		SELECT 
			@amountFrom	= X.[AmountFrom], 
			@amountTo	= X.[AmountTo] 
		FROM [Common].[AmountInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@amountFrom, @amountTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @account SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account] A
					WHERE A.[AccountSessions] BETWEEN ISNULL(@amountFrom, A.[AccountSessions]) AND ISNULL(@amountTo, A.[AccountSessions]);
				ELSE 
					INSERT @account SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account] A
					WHERE A.[AccountSessions] NOT BETWEEN ISNULL(@amountFrom, A.[AccountSessions]) AND ISNULL(@amountTo, A.[AccountSessions]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @account	X
					LEFT JOIN
					(
						SELECT 
							A.[UserId],
							A.[ApplicationId]
						FROM [Security].[Entity.Account] A
						WHERE A.[AccountSessions] BETWEEN ISNULL(@amountFrom, A.[AccountSessions]) AND ISNULL(@amountTo, A.[AccountSessions])
					)	A	ON	X.[UserId]			= A.[UserId]	AND
								X.[ApplicationId]	= A.[ApplicationId]
					WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
				ELSE
					DELETE X FROM @account	X
					LEFT JOIN
					(
						SELECT 
							A.[UserId],
							A.[ApplicationId]
						FROM [Security].[Entity.Account] A
						WHERE A.[AccountSessions] NOT BETWEEN ISNULL(@amountFrom, A.[AccountSessions]) AND ISNULL(@amountTo, A.[AccountSessions])
					)	A	ON	X.[UserId]			= A.[UserId]	AND
								X.[ApplicationId]	= A.[ApplicationId]
					WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
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
					INSERT @account SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account]	A
					INNER JOIN	@application			X	ON	A.[ApplicationId]	= X.[Id];
				ELSE
					INSERT @account SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account]	A
					LEFT JOIN	@application			X	ON	A.[ApplicationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @account	X
					LEFT JOIN
					(
						SELECT 
							A.[UserId],
							A.[ApplicationId]
						FROM [Security].[Entity.Account]	A
						INNER JOIN	@application			X	ON	A.[ApplicationId]	= X.[Id]
					)	A	ON	X.[UserId]			= A.[UserId]	AND
								X.[ApplicationId]	= A.[ApplicationId]
					WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
				ELSE
					DELETE X FROM @account	X
					LEFT JOIN
					(
						SELECT 
							A.[UserId],
							A.[ApplicationId]
						FROM [Security].[Entity.Account]	A
						LEFT JOIN	@application			X	ON	A.[ApplicationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	A	ON	X.[UserId]			= A.[UserId]	AND
								X.[ApplicationId]	= A.[ApplicationId]
					WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @account SELECT 
				A.[UserId],
				A.[ApplicationId]
			FROM [Security].[Entity.Account]	A
			WHERE A.[EmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @account	X
			LEFT JOIN
			(
				SELECT 
					A.[UserId],
					A.[ApplicationId]
				FROM [Security].[Entity.Account]	A
				WHERE A.[EmplacementId] = @emplacementId
			)	A	ON	X.[UserId]			= A.[UserId]	AND
						X.[ApplicationId]	= A.[ApplicationId]
			WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by application
	IF (@applicationId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @account SELECT 
				A.[UserId],
				A.[ApplicationId]
			FROM [Security].[Entity.Account]	A
			WHERE A.[ApplicationId] = @applicationId;
		ELSE
			DELETE X FROM @account	X
			LEFT JOIN
			(
				SELECT 
					A.[UserId],
					A.[ApplicationId]
				FROM [Security].[Entity.Account]	A
				WHERE A.[ApplicationId] = @applicationId
			)	A	ON	X.[UserId]			= A.[UserId]	AND
						X.[ApplicationId]	= A.[ApplicationId]
			WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
		SET @isFiltered = 1;
	END
	
--	Filter by assigned status
	DECLARE @assigned BIT;
	SET @assigned = [Common].[Bool.Entity](@predicate.query('/*/Assigned'));
	IF (@assigned IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @account SELECT 
				A.[UserId],
				A.[ApplicationId]
			FROM [Security].[Entity.Account]	A
			WHERE 
				(
					@assigned = 1	AND
					A.[AccountId] IS NOT NULL
				)	OR
				(
					@assigned = 0	AND
					A.[AccountId] IS NULL
				);
		ELSE
			DELETE X FROM @account	X
			LEFT JOIN
			(
				SELECT 
					A.[UserId],
					A.[ApplicationId]
				FROM [Security].[Entity.Account]	A
				WHERE 
					(
						@assigned = 1	AND
						A.[AccountId] IS NOT NULL
					)	OR
					(
						@assigned = 0	AND
						A.[AccountId] IS NULL
					)
			)	A	ON	X.[UserId]			= A.[UserId]	AND
						X.[ApplicationId]	= A.[ApplicationId]
			WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT * FROM @account X FOR XML PATH('guid'), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Security].[Entity.Account] A;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @account X;
		ELSE
			SELECT @number = COUNT(*) FROM [Security].[Entity.Account] A
			LEFT JOIN	@account	X	ON	A.[UserId]			= X.[UserId]	AND
											A.[ApplicationId]	= X.[ApplicationId]
			WHERE 
				A.[EmplacementId] = ISNULL(@emplacementId, A.[EmplacementId])	AND
				A.[ApplicationId] = ISNULL(@applicationId, A.[ApplicationId])	AND
				COALESCE(X.[UserId], X.[ApplicationId]) IS NULL;

END
GO
