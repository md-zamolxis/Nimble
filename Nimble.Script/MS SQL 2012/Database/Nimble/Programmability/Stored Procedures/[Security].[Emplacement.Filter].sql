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
			O.[name]	= 'Emplacement.Filter'))
	DROP PROCEDURE [Security].[Emplacement.Filter];
GO

CREATE PROCEDURE [Security].[Emplacement.Filter]
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

	DECLARE @emplacement TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Emplacements')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Emplacement');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Security].[Emplacement.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @emplacement SELECT * FROM @entities;
				ELSE
					INSERT @emplacement SELECT E.[EmplacementId] FROM [Security].[Emplacement] E
					WHERE E.[EmplacementId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @emplacement X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @emplacement X WHERE X.[Id] IN (SELECT * FROM @entities);
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
					INSERT @emplacement SELECT DISTINCT E.[EmplacementId] FROM [Security].[Emplacement] E
					INNER JOIN	@codes	X	ON	E.[EmplacementCode]	LIKE X.[Code];
				ELSE 
					INSERT @emplacement SELECT DISTINCT E.[EmplacementId] FROM [Security].[Emplacement] E
					LEFT JOIN	@codes	X	ON	E.[EmplacementCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @emplacement	X
					LEFT JOIN
					(
						SELECT DISTINCT E.[EmplacementId] FROM [Security].[Emplacement] E
						INNER JOIN	@codes	X	ON	E.[EmplacementCode]	LIKE X.[Code]
					)	E	ON	X.[Id]	= E.[EmplacementId]
					WHERE E.[EmplacementId]	IS NULL;
				ELSE
					DELETE X FROM @emplacement	X
					LEFT JOIN
					(
						SELECT DISTINCT E.[EmplacementId] FROM [Security].[Emplacement] E
						LEFT JOIN	@codes	X	ON	E.[EmplacementCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	E	ON	X.[Id]	= E.[EmplacementId]
					WHERE E.[EmplacementId]	IS NULL;
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
					INSERT @emplacement SELECT DISTINCT E.[EmplacementId] FROM [Security].[Emplacement] E
					INNER JOIN	@descriptions	X	ON	E.[EmplacementDescription]	LIKE X.[Description];
				ELSE 
					INSERT @emplacement SELECT DISTINCT E.[EmplacementId] FROM [Security].[Emplacement] E
					LEFT JOIN	@descriptions	X	ON	E.[EmplacementDescription]	LIKE X.[Description]
					WHERE X.[Description] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @emplacement	X
					LEFT JOIN
					(
						SELECT DISTINCT E.[EmplacementId] FROM [Security].[Emplacement] E
						INNER JOIN	@descriptions	X	ON	E.[EmplacementDescription]	LIKE X.[Description]
					)	E	ON	X.[Id]	= E.[EmplacementId]
					WHERE E.[EmplacementId]	IS NULL;
				ELSE
					DELETE X FROM @emplacement	X
					LEFT JOIN
					(
						SELECT DISTINCT E.[EmplacementId] FROM [Security].[Emplacement] E
						LEFT JOIN	@descriptions	X	ON	E.[EmplacementDescription]	LIKE X.[Description]
						WHERE X.[Description] IS NULL
					)	E	ON	X.[Id]	= E.[EmplacementId]
					WHERE E.[EmplacementId]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by administrative status
	DECLARE @isAdministrative BIT;
	SET @isAdministrative = [Common].[Bool.Entity](@predicate.query('/*/IsAdministrative'));
	IF (@isAdministrative IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @emplacement SELECT E.[EmplacementId] FROM [Security].[Emplacement] E
			WHERE E.[EmplacementIsAdministrative] = @isAdministrative;
		ELSE
			DELETE X FROM @emplacement	X
			LEFT JOIN
			(
				SELECT E.[EmplacementId] FROM [Security].[Emplacement] E
				WHERE E.[EmplacementIsAdministrative] = @isAdministrative
			)	E	ON	X.[Id]	= E.[EmplacementId]
			WHERE E.[EmplacementId]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @emplacement SELECT E.[EmplacementId] FROM [Security].[Emplacement] E
			WHERE E.[EmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @emplacement	X
			LEFT JOIN
			(
				SELECT E.[EmplacementId] FROM [Security].[Emplacement] E
				WHERE E.[EmplacementId] = @emplacementId
			)	E	ON	X.[Id]	= E.[EmplacementId]
			WHERE E.[EmplacementId]	IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @emplacement X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Security].[Emplacement] E;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @emplacement X;
		ELSE
			SELECT @number = COUNT(*) FROM [Security].[Emplacement] E
			LEFT JOIN	@emplacement	X	ON	E.[EmplacementId] = X.[Id]
			WHERE 
				E.[EmplacementId] = ISNULL(@emplacementId, E.[EmplacementId])	AND
				X.[Id] IS NULL;

END
GO
