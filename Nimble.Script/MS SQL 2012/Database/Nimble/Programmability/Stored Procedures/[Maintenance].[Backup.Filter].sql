SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Maintenance'	AND
			O.[type]	= 'P'			AND
			O.[name]	= 'Backup.Filter'))
	DROP PROCEDURE [Maintenance].[Backup.Filter];
GO

CREATE PROCEDURE [Maintenance].[Backup.Filter]
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
	
	DECLARE @backup TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Backups')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Backup');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Maintenance].[Backup.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @backup SELECT * FROM @entities;
				ELSE
					INSERT @backup SELECT B.[BackupId] FROM [Maintenance].[Backup] B
					WHERE B.[BackupId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @backup X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @backup X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

--	Filter by start datetime offset
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Start')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @dateFrom = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @backup SELECT B.[BackupId] FROM [Maintenance].[Backup] B
					WHERE B.[BackupStart] BETWEEN ISNULL(@dateFrom, B.[BackupStart]) AND ISNULL(@dateTo, B.[BackupStart]);
				ELSE 
					INSERT @backup SELECT B.[BackupId] FROM [Maintenance].[Backup] B
					WHERE B.[BackupStart] NOT BETWEEN ISNULL(@dateFrom, B.[BackupStart]) AND ISNULL(@dateTo, B.[BackupStart]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @backup	X
					LEFT JOIN
					(
						SELECT B.[BackupId] FROM [Maintenance].[Backup] B
						WHERE B.[BackupStart] BETWEEN ISNULL(@dateFrom, B.[BackupStart]) AND ISNULL(@dateTo, B.[BackupStart])
					)	B	ON	X.[Id]	= B.[BackupId]
					WHERE B.[BackupId] IS NULL;
				ELSE
					DELETE X FROM @backup	X
					LEFT JOIN
					(
						SELECT B.[BackupId] FROM [Maintenance].[Backup] B
						WHERE B.[BackupStart] NOT BETWEEN ISNULL(@dateFrom, B.[BackupStart]) AND ISNULL(@dateTo, B.[BackupStart])
					)	B	ON	X.[Id]	= B.[BackupId]
					WHERE B.[BackupId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @backup X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Maintenance].[Backup] B;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @backup X;
		ELSE
			SELECT @number = COUNT(*) FROM [Maintenance].[Backup] B
			LEFT JOIN	@backup	X	ON	B.[BackupId] = X.[Id]
			WHERE X.[Id] IS NULL;

END
GO
