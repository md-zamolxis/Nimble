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
			O.[name]	= 'Person.Filter'))
	DROP PROCEDURE [Owner].[Person.Filter];
GO

CREATE PROCEDURE [Owner].[Person.Filter]
(
	@predicate		XML,
	@emplacementId	UNIQUEIDENTIFIER	= NULL,
	@applicationId	UNIQUEIDENTIFIER	= NULL,
	@personId		UNIQUEIDENTIFIER	= NULL,
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

	DECLARE @person TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Persons')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Person');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Owner].[Person.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @person SELECT * FROM @entities;
				ELSE
					INSERT @person SELECT P.[PersonId] FROM [Owner].[Person] P
					WHERE P.[PersonId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @person X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @person X WHERE X.[Id] IN (SELECT * FROM @entities);
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
					INSERT @person SELECT P.[PersonId] FROM [Owner].[Person] P
					INNER JOIN	@emplacement	X	ON	P.[PersonEmplacementId]	= X.[Id];
				ELSE
					INSERT @person SELECT P.[PersonId] FROM [Owner].[Person] P
					LEFT JOIN	@emplacement	X	ON	P.[PersonEmplacementId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT P.[PersonId] FROM [Owner].[Person] P
						INNER JOIN	@emplacement	X	ON	P.[PersonEmplacementId]	= X.[Id]
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
				ELSE
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT P.[PersonId] FROM [Owner].[Person] P
						LEFT JOIN	@emplacement	X	ON	P.[PersonEmplacementId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
			SET @isFiltered = 1;
		END
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
					INSERT @person SELECT P.[PersonId] FROM [Owner].[Person] P
					INNER JOIN	@user	X	ON	P.[PersonUserId]	= X.[Id];
				ELSE
					INSERT @person SELECT P.[PersonId] FROM [Owner].[Person] P
					LEFT JOIN	@user	X	ON	P.[PersonUserId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT P.[PersonId] FROM [Owner].[Person] P
						INNER JOIN	@user	X	ON	P.[PersonUserId]	= X.[Id]
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
				ELSE
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT P.[PersonId] FROM [Owner].[Person] P
						LEFT JOIN	@user	X	ON	P.[PersonUserId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by person
	IF (@personId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @person SELECT P.[PersonId] FROM [Owner].[Person] P
			WHERE P.[PersonId] = @personId;
		ELSE
			DELETE X FROM @person	X
			LEFT JOIN
			(
				SELECT P.[PersonId] FROM [Owner].[Person] P
				WHERE P.[PersonId] = @personId
			)	P	ON	X.[Id]	= P.[PersonId]
			WHERE P.[PersonId] IS NULL;
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
					INSERT @person SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
					INNER JOIN	@codes	X	ON	P.[PersonCode]	LIKE X.[Code];
				ELSE 
					INSERT @person SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
					LEFT JOIN	@codes	X	ON	P.[PersonCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
						INNER JOIN	@codes	X	ON	P.[PersonCode]	LIKE X.[Code]
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
				ELSE
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
						LEFT JOIN	@codes	X	ON	P.[PersonCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by IDNPs
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/IDNPs')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @IDNPs TABLE ([IDNP] NVARCHAR(MAX));
		INSERT @IDNPs SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @person SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
					INNER JOIN	@IDNPs	X	ON	P.[PersonIDNP]	LIKE X.[IDNP];
				ELSE 
					INSERT @person SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
					LEFT JOIN	@IDNPs	X	ON	P.[PersonIDNP]	LIKE X.[IDNP]
					WHERE X.[IDNP] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
						INNER JOIN	@IDNPs	X	ON	P.[PersonIDNP]	LIKE X.[IDNP]
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
				ELSE
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
						LEFT JOIN	@IDNPs	X	ON	P.[PersonIDNP]	LIKE X.[IDNP]
						WHERE X.[IDNP] IS NULL
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emails
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Emails')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @emails TABLE ([Email] NVARCHAR(MAX));
		INSERT @emails SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @person SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
					INNER JOIN	@emails	X	ON	P.[PersonEmail]	LIKE X.[Email];
				ELSE 
					INSERT @person SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
					LEFT JOIN	@emails	X	ON	P.[PersonEmail]	LIKE X.[Email]
					WHERE X.[Email] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
						INNER JOIN	@emails	X	ON	P.[PersonEmail]	LIKE X.[Email]
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
				ELSE
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
						LEFT JOIN	@emails	X	ON	P.[PersonEmail]	LIKE X.[Email]
						WHERE X.[Email] IS NULL
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by first names
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/FirstNames')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @firstNames TABLE ([FirstName] NVARCHAR(MAX));
		INSERT @firstNames SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @person SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
					INNER JOIN	@firstNames	X	ON	P.[PersonFirstName]	LIKE X.[FirstName];
				ELSE 
					INSERT @person SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
					LEFT JOIN	@firstNames	X	ON	P.[PersonFirstName]	LIKE X.[FirstName]
					WHERE X.[FirstName] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
						INNER JOIN	@firstNames	X	ON	P.[PersonFirstName]	LIKE X.[FirstName]
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
				ELSE
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
						LEFT JOIN	@firstNames	X	ON	P.[PersonFirstName]	LIKE X.[FirstName]
						WHERE X.[FirstName] IS NULL
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by last names
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/LastNames')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @lastNames TABLE ([LastName] NVARCHAR(MAX));
		INSERT @lastNames SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @person SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
					INNER JOIN	@lastNames	X	ON	P.[PersonLastName]	LIKE X.[LastName];
				ELSE 
					INSERT @person SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
					LEFT JOIN	@lastNames	X	ON	P.[PersonLastName]	LIKE X.[LastName]
					WHERE X.[LastName] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
						INNER JOIN	@lastNames	X	ON	P.[PersonLastName]	LIKE X.[LastName]
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
				ELSE
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
						LEFT JOIN	@lastNames	X	ON	P.[PersonLastName]	LIKE X.[LastName]
						WHERE X.[LastName] IS NULL
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by patronymics
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Patronymics')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @patronymics TABLE ([Patronymic] NVARCHAR(MAX));
		INSERT @patronymics SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @person SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
					INNER JOIN	@patronymics	X	ON	P.[PersonPatronymic]	LIKE X.[Patronymic];
				ELSE 
					INSERT @person SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
					LEFT JOIN	@patronymics	X	ON	P.[PersonPatronymic]	LIKE X.[Patronymic]
					WHERE X.[Patronymic] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
						INNER JOIN	@patronymics	X	ON	P.[PersonPatronymic]	LIKE X.[Patronymic]
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
				ELSE
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
						LEFT JOIN	@patronymics	X	ON	P.[PersonPatronymic]	LIKE X.[Patronymic]
						WHERE X.[Patronymic] IS NULL
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by born datetime offset
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
					INSERT @person SELECT P.[PersonId] FROM [Owner].[Person] P
					WHERE P.[PersonBornOn] BETWEEN ISNULL(@dateFrom, P.[PersonBornOn]) AND ISNULL(@dateTo, P.[PersonBornOn]);
				ELSE 
					INSERT @person SELECT P.[PersonId] FROM [Owner].[Person] P
					WHERE P.[PersonBornOn] NOT BETWEEN ISNULL(@dateFrom, P.[PersonBornOn]) AND ISNULL(@dateTo, P.[PersonBornOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT P.[PersonId] FROM [Owner].[Person] P
						WHERE P.[PersonBornOn] BETWEEN ISNULL(@dateFrom, P.[PersonBornOn]) AND ISNULL(@dateTo, P.[PersonBornOn])
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
				ELSE
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT P.[PersonId] FROM [Owner].[Person] P
						WHERE P.[PersonBornOn] NOT BETWEEN ISNULL(@dateFrom, P.[PersonBornOn]) AND ISNULL(@dateTo, P.[PersonBornOn])
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by person sex types
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/PersonSexTypes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @personSexTypes TABLE ([PersonSexType] NVARCHAR(MAX));
		INSERT @personSexTypes SELECT DISTINCT * FROM [Common].[Enum.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @person SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
					INNER JOIN	@personSexTypes		X	ON	P.[PersonSexType]	LIKE X.[PersonSexType];
				ELSE 
					INSERT @person SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
					LEFT JOIN	@personSexTypes		X	ON	P.[PersonSexType]	LIKE X.[PersonSexType]
					WHERE X.[PersonSexType] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
						INNER JOIN	@personSexTypes		X	ON	P.[PersonSexType]	LIKE X.[PersonSexType]
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
				ELSE
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT DISTINCT P.[PersonId] FROM [Owner].[Person] P
						LEFT JOIN	@personSexTypes		X	ON	P.[PersonSexType]	LIKE X.[PersonSexType]
						WHERE X.[PersonSexType] IS NULL
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
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
					INSERT @person SELECT P.[PersonId] FROM [Owner].[Person] P
					WHERE P.[PersonLockedOn] BETWEEN ISNULL(@dateFrom, P.[PersonLockedOn]) AND ISNULL(@dateTo, P.[PersonLockedOn]);
				ELSE 
					INSERT @person SELECT P.[PersonId] FROM [Owner].[Person] P
					WHERE P.[PersonLockedOn] NOT BETWEEN ISNULL(@dateFrom, P.[PersonLockedOn]) AND ISNULL(@dateTo, P.[PersonLockedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT P.[PersonId] FROM [Owner].[Person] P
						WHERE P.[PersonLockedOn] BETWEEN ISNULL(@dateFrom, P.[PersonLockedOn]) AND ISNULL(@dateTo, P.[PersonLockedOn])
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
				ELSE
					DELETE X FROM @person	X
					LEFT JOIN
					(
						SELECT P.[PersonId] FROM [Owner].[Person] P
						WHERE P.[PersonLockedOn] NOT BETWEEN ISNULL(@dateFrom, P.[PersonLockedOn]) AND ISNULL(@dateTo, P.[PersonLockedOn])
					)	P	ON	X.[Id]	= P.[PersonId]
					WHERE P.[PersonId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @person SELECT P.[PersonId] FROM [Owner].[Person] P
			WHERE P.[PersonEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @person	X
			LEFT JOIN
			(
				SELECT P.[PersonId] FROM [Owner].[Person] P
				WHERE P.[PersonEmplacementId] = @emplacementId
			)	P	ON	X.[Id]	= P.[PersonId]
			WHERE P.[PersonId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @person X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Owner].[Person] P;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @person X;
		ELSE
			SELECT @number = COUNT(*) FROM [Owner].[Person] P
			LEFT JOIN	@person	X	ON	P.[PersonId] = X.[Id]
			WHERE 
				P.[PersonEmplacementId] = ISNULL(@emplacementId, P.[PersonEmplacementId])	AND
				P.[PersonId] = ISNULL(@personId, P.[PersonId])								AND
				X.[Id] IS NULL;

END
GO
