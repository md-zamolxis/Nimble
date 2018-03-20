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
			O.[name]	= 'Mark.Filter'))
	DROP PROCEDURE [Owner].[Mark.Filter];
GO

CREATE PROCEDURE [Owner].[Mark.Filter]
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

	DECLARE @mark TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Marks')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Mark');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Owner].[Mark.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @mark SELECT * FROM @entities;
				ELSE
					INSERT @mark SELECT M.[MarkId] FROM [Owner].[Mark] M
					WHERE M.[MarkId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @mark X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @mark X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

--	Filter by person predicate
	DECLARE 
		@personPredicate	XML,
		@personIsCountable	BIT,
		@personGuids		XML,
		@personIsFiltered	BIT,
		@personNumber		INT;
	SELECT 
		@personPredicate	= X.[Criteria],
		@personIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/PersonPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @person TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner].[Person.Filter]
			@predicate,
			@emplacementId,
			@applicationId,
			@personId,
			@organisations,
			@isCountable,
			@guids		OUTPUT,
			@isExcluded OUTPUT,
			@isFiltered OUTPUT,
			@number		OUTPUT',
			N'@predicate	XML,
			@emplacementId	UNIQUEIDENTIFIER,
			@applicationId	UNIQUEIDENTIFIER,
			@personId		UNIQUEIDENTIFIER,
			@organisations	XML,
			@isCountable	BIT,
			@guids			XML OUTPUT,
			@isExcluded		BIT OUTPUT,
			@isFiltered		BIT OUTPUT,
			@number			INT OUTPUT',
			@predicate		= @personPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@personId		= NULL,
			@organisations	= NULL,
			@isCountable	= @personIsCountable,
			@guids			= @personGuids		OUTPUT,
			@isExcluded		= @isExcluded		OUTPUT,
			@isFiltered		= @personIsFiltered	OUTPUT,
			@number			= @personNumber		OUTPUT;
		INSERT @person SELECT * FROM [Common].[Guid.Entities](@personGuids);
		IF (@personIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @mark SELECT M.[MarkId] FROM [Owner].[Mark] M
					INNER JOIN	@person	X	ON	M.[MarkPersonId]	= X.[Id];
				ELSE
					INSERT @mark SELECT M.[MarkId] FROM [Owner].[Mark] M
					LEFT JOIN	@person	X	ON	M.[MarkPersonId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @mark	X
					LEFT JOIN
					(
						SELECT M.[MarkId] FROM [Owner].[Mark] M
						INNER JOIN	@person	X	ON	M.[MarkPersonId]	= X.[Id]
					)	M	ON	X.[Id]	= M.[MarkId]
					WHERE M.[MarkId] IS NULL;
				ELSE
					DELETE X FROM @mark	X
					LEFT JOIN
					(
						SELECT M.[MarkId] FROM [Owner].[Mark] M
						LEFT JOIN	@person	X	ON	M.[MarkPersonId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	M	ON	X.[Id]	= M.[MarkId]
					WHERE M.[MarkId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by person
	IF (@personId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @mark SELECT M.[MarkId] FROM [Owner].[Mark] M
			WHERE M.[MarkPersonId] = @personId;
		ELSE
			DELETE X FROM @mark	X
			LEFT JOIN
			(
				SELECT M.[MarkId] FROM [Owner].[Mark] M
				WHERE M.[MarkPersonId] = @personId
			)	M	ON	X.[Id]	= M.[MarkId]
			WHERE M.[MarkId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by mark entity types
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/MarkEntityTypes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @markEntityTypes TABLE ([MarkEntityType] NVARCHAR(MAX));
		INSERT @markEntityTypes SELECT DISTINCT * FROM [Common].[Enum.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @mark SELECT DISTINCT M.[MarkId] FROM [Owner].[Mark] M
					INNER JOIN	@markEntityTypes	X	ON	M.[MarkEntityType]	LIKE X.[MarkEntityType];
				ELSE 
					INSERT @mark SELECT DISTINCT M.[MarkId] FROM [Owner].[Mark] M
					LEFT JOIN	@markEntityTypes	X	ON	M.[MarkEntityType]	LIKE X.[MarkEntityType]
					WHERE X.[MarkEntityType] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @mark	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MarkId] FROM [Owner].[Mark] M
						INNER JOIN	@markEntityTypes		X	ON	M.[MarkEntityType]	LIKE X.[MarkEntityType]
					)	M	ON	X.[Id]	= M.[MarkId]
					WHERE M.[MarkId] IS NULL;
				ELSE
					DELETE X FROM @mark	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MarkId] FROM [Owner].[Mark] M
						LEFT JOIN	@markEntityTypes		X	ON	M.[MarkEntityType]	LIKE X.[MarkEntityType]
						WHERE X.[MarkEntityType] IS NULL
					)	M	ON	X.[Id]	= M.[MarkId]
					WHERE M.[MarkId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by entity ids
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/EntityIds')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @entityIds TABLE ([EntityId] UNIQUEIDENTIFIER);
		INSERT @entityIds SELECT DISTINCT * FROM [Common].[Guid.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @mark SELECT DISTINCT M.[MarkId] FROM [Owner].[Mark] M
					INNER JOIN	@entityIds	X	ON	M.[MarkEntityId]	= X.[EntityId];
				ELSE 
					INSERT @mark SELECT DISTINCT M.[MarkId] FROM [Owner].[Mark] M
					LEFT JOIN	@entityIds	X	ON	M.[MarkEntityId]	= X.[EntityId]
					WHERE X.[EntityId] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @mark	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MarkId] FROM [Owner].[Mark] M
						INNER JOIN	@entityIds	X	ON	M.[MarkEntityId]	= X.[EntityId]
					)	M	ON	X.[Id]	= M.[MarkId]
					WHERE M.[MarkId] IS NULL;
				ELSE
					DELETE X FROM @mark	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MarkId] FROM [Owner].[Mark] M
						LEFT JOIN	@entityIds	X	ON	M.[MarkEntityId]	= X.[EntityId]
						WHERE X.[EntityId] IS NULL
					)	M	ON	X.[Id]	= M.[MarkId]
					WHERE M.[MarkId] IS NULL;
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
					INSERT @mark SELECT M.[MarkId] FROM [Owner].[Mark] M
					WHERE M.[MarkCreatedOn] BETWEEN ISNULL(@dateFrom, M.[MarkCreatedOn]) AND ISNULL(@dateTo, M.[MarkCreatedOn]);
				ELSE 
					INSERT @mark SELECT M.[MarkId] FROM [Owner].[Mark] M
					WHERE M.[MarkCreatedOn] NOT BETWEEN ISNULL(@dateFrom, M.[MarkCreatedOn]) AND ISNULL(@dateTo, M.[MarkCreatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @mark	X
					LEFT JOIN
					(
						SELECT M.[MarkId] FROM [Owner].[Mark] M
						WHERE M.[MarkCreatedOn] BETWEEN ISNULL(@dateFrom, M.[MarkCreatedOn]) AND ISNULL(@dateTo, M.[MarkCreatedOn])
					)	M	ON	X.[Id]	= M.[MarkId]
					WHERE M.[MarkId] IS NULL;
				ELSE
					DELETE X FROM @mark	X
					LEFT JOIN
					(
						SELECT M.[MarkId] FROM [Owner].[Mark] M
						WHERE M.[MarkCreatedOn] NOT BETWEEN ISNULL(@dateFrom, M.[MarkCreatedOn]) AND ISNULL(@dateTo, M.[MarkCreatedOn])
					)	M	ON	X.[Id]	= M.[MarkId]
					WHERE M.[MarkId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by updated datetime offset
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/UpdatedOn')) X;
	IF (@criteriaExist = 1) BEGIN
		SELECT @dateFrom = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @mark SELECT M.[MarkId] FROM [Owner].[Mark] M
					WHERE M.[MarkUpdatedOn] BETWEEN ISNULL(@dateFrom, M.[MarkUpdatedOn]) AND ISNULL(@dateTo, M.[MarkUpdatedOn]);
				ELSE 
					INSERT @mark SELECT M.[MarkId] FROM [Owner].[Mark] M
					WHERE M.[MarkUpdatedOn] NOT BETWEEN ISNULL(@dateFrom, M.[MarkUpdatedOn]) AND ISNULL(@dateTo, M.[MarkUpdatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @mark	X
					LEFT JOIN
					(
						SELECT M.[MarkId] FROM [Owner].[Mark] M
						WHERE M.[MarkUpdatedOn] BETWEEN ISNULL(@dateFrom, M.[MarkUpdatedOn]) AND ISNULL(@dateTo, M.[MarkUpdatedOn])
					)	M	ON	X.[Id]	= M.[MarkId]
					WHERE M.[MarkId] IS NULL;
				ELSE
					DELETE X FROM @mark	X
					LEFT JOIN
					(
						SELECT M.[MarkId] FROM [Owner].[Mark] M
						WHERE M.[MarkUpdatedOn] NOT BETWEEN ISNULL(@dateFrom, M.[MarkUpdatedOn]) AND ISNULL(@dateTo, M.[MarkUpdatedOn])
					)	M	ON	X.[Id]	= M.[MarkId]
					WHERE M.[MarkId] IS NULL;
		ELSE
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @mark SELECT M.[MarkId] FROM [Owner].[Mark] M
					WHERE M.[MarkUpdatedOn] IS NULL;
				ELSE 
					INSERT @mark SELECT M.[MarkId] FROM [Owner].[Mark] M
					WHERE M.[MarkUpdatedOn] IS NOT NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @mark	X
					LEFT JOIN
					(
						SELECT M.[MarkId] FROM [Owner].[Mark] M
						WHERE M.[MarkUpdatedOn] IS NULL
					)	M	ON	X.[Id]	= M.[MarkId]
					WHERE M.[MarkId] IS NULL;
				ELSE
					DELETE X FROM @mark	X
					LEFT JOIN
					(
						SELECT M.[MarkId] FROM [Owner].[Mark] M
						WHERE M.[MarkUpdatedOn] IS NOT NULL
					)	M	ON	X.[Id]	= M.[MarkId]
					WHERE M.[MarkId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by mark action types
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/MarkActionTypes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @markActionTypes TABLE ([MarkActionType] NVARCHAR(MAX));
		INSERT @markActionTypes SELECT DISTINCT * FROM [Common].[Enum.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @mark SELECT DISTINCT M.[MarkId] FROM [Owner].[Mark] M
					INNER JOIN	@markActionTypes	X	ON	M.[MarkActionType]	LIKE X.[MarkActionType];
				ELSE 
					INSERT @mark SELECT DISTINCT M.[MarkId] FROM [Owner].[Mark] M
					LEFT JOIN	@markActionTypes	X	ON	M.[MarkActionType]	LIKE X.[MarkActionType]
					WHERE X.[MarkActionType] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @mark	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MarkId] FROM [Owner].[Mark] M
						INNER JOIN	@markActionTypes		X	ON	M.[MarkActionType]	LIKE X.[MarkActionType]
					)	M	ON	X.[Id]	= M.[MarkId]
					WHERE M.[MarkId] IS NULL;
				ELSE
					DELETE X FROM @mark	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MarkId] FROM [Owner].[Mark] M
						LEFT JOIN	@markActionTypes		X	ON	M.[MarkActionType]	LIKE X.[MarkActionType]
						WHERE X.[MarkActionType] IS NULL
					)	M	ON	X.[Id]	= M.[MarkId]
					WHERE M.[MarkId] IS NULL;
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Comments')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @comments TABLE ([Comment] NVARCHAR(MAX));
		INSERT @comments SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @mark SELECT DISTINCT M.[MarkId] FROM [Owner].[Mark] M
					INNER JOIN	@comments	X	ON	M.[MarkComment]	LIKE X.[Comment];
				ELSE 
					INSERT @mark SELECT DISTINCT M.[MarkId] FROM [Owner].[Mark] M
					LEFT JOIN	@comments	X	ON	M.[MarkComment]	LIKE X.[Comment]
					WHERE X.[Comment] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @mark	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MarkId] FROM [Owner].[Mark] M
						INNER JOIN	@comments	X	ON	M.[MarkComment]	LIKE X.[Comment]
					)	M	ON	X.[Id]	= M.[MarkId]
					WHERE M.[MarkId] IS NULL;
				ELSE
					DELETE X FROM @mark	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MarkId] FROM [Owner].[Mark] M
						LEFT JOIN	@comments	X	ON	M.[MarkComment]	LIKE X.[Comment]
						WHERE X.[Comment] IS NULL
					)	M	ON	X.[Id]	= M.[MarkId]
					WHERE M.[MarkId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @mark SELECT M.[MarkId] FROM [Owner].[Mark] M
			INNER JOIN	[Owner].[Person]	P	ON	M.[MarkPersonId]	= P.[PersonId]
			WHERE P.[PersonEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @mark	X
			LEFT JOIN	(
				SELECT M.[MarkId] FROM [Owner].[Mark]	M
				INNER JOIN	[Owner].[Person]			P	ON	M.[MarkPersonId]	= P.[PersonId]
				WHERE P.[PersonEmplacementId] = @emplacementId
			)	M	ON	X.[Id]	= M.[MarkId]
			WHERE M.[MarkId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @mark X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Owner].[Mark] M;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @mark X;
		ELSE
			SELECT @number = COUNT(*) FROM [Owner].[Mark]	M
			INNER JOIN	[Owner].[Person]	P	ON	M.[MarkPersonId]	= P.[PersonId]
			LEFT JOIN	@mark				X	ON	M.[MarkId]			= X.[Id]
			WHERE 
				P.[PersonEmplacementId] = ISNULL(@emplacementId, P.[PersonEmplacementId])	AND
				P.[PersonId] = ISNULL(@personId, P.[PersonId])								AND
				X.[Id] IS NULL;

END
GO
