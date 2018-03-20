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
			O.[name]	= 'Application.Filter'))
	DROP PROCEDURE [Security].[Application.Filter];
GO

CREATE PROCEDURE [Security].[Application.Filter]
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

	DECLARE @application TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Applications')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Application');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Security].[Application.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @application SELECT * FROM @entities;
				ELSE
					INSERT @application SELECT A.[ApplicationId] FROM [Security].[Application] A
					WHERE A.[ApplicationId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @application X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @application X WHERE X.[Id] IN (SELECT * FROM @entities);
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
					INSERT @application SELECT DISTINCT A.[ApplicationId] FROM [Security].[Application] A
					INNER JOIN	@codes	X	ON	A.[ApplicationCode]	LIKE X.[Code];
				ELSE 
					INSERT @application SELECT DISTINCT A.[ApplicationId] FROM [Security].[Application] A
					LEFT JOIN	@codes	X	ON	A.[ApplicationCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @application	X
					LEFT JOIN
					(
						SELECT DISTINCT A.[ApplicationId] FROM [Security].[Application] A
						INNER JOIN	@codes	X	ON	A.[ApplicationCode]		LIKE X.[Code]
					)	A	ON	X.[Id]	= A.[ApplicationId]
					WHERE A.[ApplicationId]	IS NULL;
				ELSE
					DELETE X FROM @application	X
					LEFT JOIN
					(
						SELECT DISTINCT A.[ApplicationId] FROM [Security].[Application] A
						LEFT JOIN	@codes	X	ON	A.[ApplicationCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	A	ON	X.[Id]	= A.[ApplicationId]
					WHERE A.[ApplicationId]	IS NULL;
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
					INSERT @application SELECT DISTINCT A.[ApplicationId] FROM [Security].[Application] A
					INNER JOIN	@descriptions	X	ON	A.[ApplicationDescription]	LIKE X.[Description];
				ELSE 
					INSERT @application SELECT DISTINCT A.[ApplicationId] FROM [Security].[Application] A
					LEFT JOIN	@descriptions	X	ON	A.[ApplicationDescription]	LIKE X.[Description]
					WHERE X.[Description] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @application	X
					LEFT JOIN
					(
						SELECT DISTINCT A.[ApplicationId] FROM [Security].[Application] A
						INNER JOIN	@descriptions	X	ON	A.[ApplicationDescription]	LIKE X.[Description]
					)	A	ON	X.[Id]	= A.[ApplicationId]
					WHERE A.[ApplicationId]	IS NULL;
				ELSE
					DELETE X FROM @application	X
					LEFT JOIN
					(
						SELECT DISTINCT A.[ApplicationId] FROM [Security].[Application] A
						LEFT JOIN	@descriptions	X	ON	A.[ApplicationDescription]	LIKE X.[Description]
						WHERE X.[Description] IS NULL
					)	A	ON	X.[Id]	= A.[ApplicationId]
					WHERE A.[ApplicationId]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by administrative status
	DECLARE @isAdministrative BIT;
	SET @isAdministrative = [Common].[Bool.Entity](@predicate.query('/*/IsAdministrative'));
	IF (@isAdministrative IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @application SELECT A.[ApplicationId] FROM [Security].[Application] A
			WHERE A.[ApplicationIsAdministrative] = @isAdministrative;
		ELSE
			DELETE X FROM @application	X
			LEFT JOIN
			(
				SELECT A.[ApplicationId] FROM [Security].[Application] A
				WHERE A.[ApplicationIsAdministrative] = @isAdministrative
			)	A	ON	X.[Id]	= A.[ApplicationId]
			WHERE A.[ApplicationId]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by application
	IF (@applicationId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @application SELECT A.[ApplicationId] FROM [Security].[Application] A
			WHERE A.[ApplicationId] = @applicationId;
		ELSE
			DELETE X FROM @application	X
			LEFT JOIN
			(
				SELECT A.[ApplicationId] FROM [Security].[Application] A
				WHERE A.[ApplicationId] = @applicationId
			)	A	ON	X.[Id]	= A.[ApplicationId]
			WHERE A.[ApplicationId]	IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @application X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Security].[Application] A;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @application X;
		ELSE
			SELECT @number = COUNT(*) FROM [Security].[Application] A
			LEFT JOIN	@application	X	ON	A.[ApplicationId] = X.[Id]
			WHERE 
				A.[ApplicationId] = ISNULL(@applicationId, A.[ApplicationId])	AND
				X.[Id] IS NULL;

END
GO
