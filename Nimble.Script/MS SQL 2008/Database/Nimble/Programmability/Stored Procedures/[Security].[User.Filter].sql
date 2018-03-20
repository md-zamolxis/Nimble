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
			O.[name]	= 'User.Filter'))
	DROP PROCEDURE [Security].[User.Filter];
GO

CREATE PROCEDURE [Security].[User.Filter]
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

	DECLARE @user TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Users')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/User');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Security].[User.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @user SELECT * FROM @entities;
				ELSE
					INSERT @user SELECT U.[UserId] FROM [Security].[User] U
					WHERE U.[UserId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @user X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @user X WHERE X.[Id] IN (SELECT * FROM @entities);
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
					INSERT @user SELECT U.[UserId] FROM [Security].[User] U
					INNER JOIN	@emplacement	X	ON	U.[UserEmplacementId]	= X.[Id];
				ELSE
					INSERT @user SELECT U.[UserId] FROM [Security].[User] U
					LEFT JOIN	@emplacement	X	ON	U.[UserEmplacementId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @user	X
					LEFT JOIN
					(
						SELECT U.[UserId] FROM [Security].[User] U
						INNER JOIN	@emplacement	X	ON	U.[UserEmplacementId]	= X.[Id]
					)	U	ON	X.[Id]	= U.[UserId]
					WHERE U.[UserId] IS NULL;
				ELSE
					DELETE X FROM @user		X
					LEFT JOIN
					(
						SELECT U.[UserId] FROM [Security].[User] U
						LEFT JOIN	@emplacement	X	ON	U.[UserEmplacementId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	U	ON	X.[Id]	= U.[UserId]
					WHERE U.[UserId] IS NULL;
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
					INSERT @user SELECT DISTINCT U.[UserId] FROM [Security].[User] U
					INNER JOIN	@codes	X	ON	U.[UserCode]	LIKE X.[Code];
				ELSE 
					INSERT @user SELECT DISTINCT U.[UserId] FROM [Security].[User] U
					LEFT JOIN	@codes	X	ON	U.[UserCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @user	X
					LEFT JOIN
					(
						SELECT DISTINCT U.[UserId] FROM [Security].[User] U
						INNER JOIN	@codes	X	ON	U.[UserCode]	LIKE X.[Code]
					)	U	ON	X.[Id]	= U.[UserId]
					WHERE U.[UserId] IS NULL;
				ELSE
					DELETE X FROM @user	X
					LEFT JOIN
					(
						SELECT DISTINCT U.[UserId] FROM [Security].[User] U
						LEFT JOIN	@codes	X	ON	U.[UserCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	U	ON	X.[Id]	= U.[UserId]
					WHERE U.[UserId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by facebook status
	DECLARE @isFacebook BIT;
	SET @isFacebook = [Common].[Bool.Entity](@predicate.query('/*/IsFacebook'));
	IF (@isFacebook IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @user SELECT U.[UserId] FROM [Security].[User] U
			WHERE SIGN(LEN(ISNULL(U.[UserFacebookId], ''))) = @isFacebook;
		ELSE
			DELETE X FROM @user	X
			LEFT JOIN
			(
				SELECT U.[UserId] FROM [Security].[User] U
				WHERE SIGN(LEN(ISNULL(U.[UserFacebookId], ''))) = @isFacebook
			)	U	ON	X.[Id]	= U.[UserId]
			WHERE U.[UserId]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by gmail status
	DECLARE @isGmail BIT;
	SET @isGmail = [Common].[Bool.Entity](@predicate.query('/*/IsGmail'));
	IF (@isGmail IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @user SELECT U.[UserId] FROM [Security].[User] U
			WHERE SIGN(LEN(ISNULL(U.[UserGmailId], ''))) = @isGmail;
		ELSE
			DELETE X FROM @user	X
			LEFT JOIN
			(
				SELECT U.[UserId] FROM [Security].[User] U
				WHERE SIGN(LEN(ISNULL(U.[UserGmailId], ''))) = @isGmail
			)	U	ON	X.[Id]	= U.[UserId]
			WHERE U.[UserId]	IS NULL;
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
					INSERT @user SELECT U.[UserId] FROM [Security].[User] U
					WHERE U.[UserCreatedOn] BETWEEN ISNULL(@dateFrom, U.[UserCreatedOn]) AND ISNULL(@dateTo, U.[UserCreatedOn]);
				ELSE 
					INSERT @user SELECT U.[UserId] FROM [Security].[User] U
					WHERE U.[UserCreatedOn] NOT BETWEEN ISNULL(@dateFrom, U.[UserCreatedOn]) AND ISNULL(@dateTo, U.[UserCreatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @user	X
					LEFT JOIN
					(
						SELECT U.[UserId] FROM [Security].[User] U
						WHERE U.[UserCreatedOn] BETWEEN ISNULL(@dateFrom, U.[UserCreatedOn]) AND ISNULL(@dateTo, U.[UserCreatedOn])
					)	U	ON	X.[Id]	= U.[UserId]
					WHERE U.[UserId] IS NULL;
				ELSE
					DELETE X FROM @user	X
					LEFT JOIN
					(
						SELECT U.[UserId] FROM [Security].[User] U
						WHERE U.[UserCreatedOn] NOT BETWEEN ISNULL(@dateFrom, U.[UserCreatedOn]) AND ISNULL(@dateTo, U.[UserCreatedOn])
					)	U	ON	X.[Id]	= U.[UserId]
					WHERE U.[UserId] IS NULL;
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
	IF (@criteriaExist = 1) BEGIN
		SELECT @dateFrom = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @user SELECT U.[UserId] FROM [Security].[User] U
					WHERE U.[UserLockedOn] BETWEEN ISNULL(@dateFrom, U.[UserLockedOn]) AND ISNULL(@dateTo, U.[UserLockedOn]);
				ELSE 
					INSERT @user SELECT U.[UserId] FROM [Security].[User] U
					WHERE U.[UserLockedOn] NOT BETWEEN ISNULL(@dateFrom, U.[UserLockedOn]) AND ISNULL(@dateTo, U.[UserLockedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @user	X
					LEFT JOIN
					(
						SELECT U.[UserId] FROM [Security].[User] U
						WHERE U.[UserLockedOn] BETWEEN ISNULL(@dateFrom, U.[UserLockedOn]) AND ISNULL(@dateTo, U.[UserLockedOn])
					)	U	ON	X.[Id]	= U.[UserId]
					WHERE U.[UserId] IS NULL;
				ELSE
					DELETE X FROM @user	X
					LEFT JOIN
					(
						SELECT U.[UserId] FROM [Security].[User] U
						WHERE U.[UserLockedOn] NOT BETWEEN ISNULL(@dateFrom, U.[UserLockedOn]) AND ISNULL(@dateTo, U.[UserLockedOn])
					)	U	ON	X.[Id]	= U.[UserId]
					WHERE U.[UserId] IS NULL;
		ELSE
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @user SELECT U.[UserId] FROM [Security].[User] U
					WHERE U.[UserLockedOn] IS NULL;
				ELSE 
					INSERT @user SELECT U.[UserId] FROM [Security].[User] U
					WHERE U.[UserLockedOn] IS NOT NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @user	X
					LEFT JOIN
					(
						SELECT U.[UserId] FROM [Security].[User] U
						WHERE U.[UserLockedOn] IS NULL
					)	U	ON	X.[Id]	= U.[UserId]
					WHERE U.[UserId] IS NULL;
				ELSE
					DELETE X FROM @user	X
					LEFT JOIN
					(
						SELECT U.[UserId] FROM [Security].[User] U
						WHERE U.[UserLockedOn] IS NOT NULL
					)	U	ON	X.[Id]	= U.[UserId]
					WHERE U.[UserId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @user SELECT U.[UserId] FROM [Security].[User] U
			WHERE U.[UserEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @user	X
			LEFT JOIN
			(
				SELECT U.[UserId] FROM [Security].[User] U
				WHERE U.[UserEmplacementId] = @emplacementId
			)	U	ON	X.[Id]	= U.[UserId]
			WHERE U.[UserId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @user X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Security].[User] U;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @user X;
		ELSE
			SELECT @number = COUNT(*) FROM [Security].[User] U
			LEFT JOIN	@user	X	ON	U.[UserId] = X.[Id]
			WHERE 
				U.[UserEmplacementId] = ISNULL(@emplacementId, U.[UserEmplacementId])	AND
				X.[Id] IS NULL;

END
GO
