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
			O.[name]	= 'Operation.Filter'))
	DROP PROCEDURE [Maintenance].[Operation.Filter];
GO

CREATE PROCEDURE [Maintenance].[Operation.Filter]
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
	
	DECLARE @operation TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
	DECLARE 
		@criteria			XML,
		@criteriaExist		BIT,
		@criteriaIsNull		BIT,
		@criteriaValue		XML,
		@criteriaValueExist	BIT;
		
	SET @isFiltered = 0;

--	Filter by batch predicate
	DECLARE 
		@batchPredicate		XML,
		@batchIsCountable	BIT,
		@batchGuids			XML,
		@batchIsFiltered	BIT,
		@batchNumber		INT;
	SELECT 
		@batchPredicate		= X.[Criteria],
		@batchIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/BatchPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @batch TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Maintenance].[Batch.Filter]
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
			@predicate		= @batchPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @batchIsCountable,
			@guids			= @batchGuids		OUTPUT,
			@isExcluded		= @isExcluded		OUTPUT,
			@isFiltered		= @batchIsFiltered	OUTPUT,
			@number			= @batchNumber		OUTPUT;
		INSERT @batch SELECT * FROM [Common].[Guid.Entities](@batchGuids);
		IF (@batchIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @operation SELECT O.[OperationId] FROM [Maintenance].[Operation] O
					INNER JOIN	@batch	X	ON	O.[OperationBatchId]	= X.[Id];
				ELSE
					INSERT @operation SELECT O.[OperationId] FROM [Maintenance].[Operation] O
					LEFT JOIN	@batch	X	ON	O.[OperationBatchId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @operation	X
					LEFT JOIN (
						SELECT O.[OperationId] FROM [Maintenance].[Operation] O
						INNER JOIN	@batch	X	ON	O.[OperationBatchId]	= X.[Id]
					)	O	ON	X.[Id]				= O.[OperationId]
					WHERE O.[OperationId] IS NULL;
				ELSE
					DELETE X FROM @operation	X
					LEFT JOIN (
						SELECT O.[OperationId] FROM [Maintenance].[Operation] O
						LEFT JOIN	@batch	X	ON	O.[OperationBatchId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	O	ON	X.[Id]				= O.[OperationId]
					WHERE O.[OperationId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by operation tuning types
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/OperationTuningTypes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @operationTuningTypes TABLE ([OperationTuningType] NVARCHAR(MAX));
		INSERT @operationTuningTypes SELECT * FROM [Common].[Enum.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @operation SELECT DISTINCT O.[OperationId] FROM [Maintenance].[Operation] O
					INNER JOIN	@operationTuningTypes	X	ON O.[OperationTuningType]	LIKE X.[OperationTuningType];
				ELSE 
					INSERT @operation SELECT DISTINCT O.[OperationId] FROM [Maintenance].[Operation] O
					LEFT JOIN	@operationTuningTypes	X	ON O.[OperationTuningType]	LIKE X.[OperationTuningType]
					WHERE X.[OperationTuningType] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @operation	X
					LEFT JOIN
					(
						SELECT DISTINCT O.[OperationId] FROM [Maintenance].[Operation] O
						INNER JOIN	@operationTuningTypes	X	ON O.[OperationTuningType]	LIKE X.[OperationTuningType]
					)	O	ON	X.[Id]	= O.[OperationId]
					WHERE O.[OperationId] IS NULL;
				ELSE
					DELETE X FROM @operation	X
					LEFT JOIN
					(
						SELECT DISTINCT O.[OperationId] FROM [Maintenance].[Operation] O
						LEFT JOIN	@operationTuningTypes	X	ON O.[OperationTuningType]	LIKE X.[OperationTuningType]
						WHERE X.[OperationTuningType] IS NULL
					)	O	ON	X.[Id]	= O.[OperationId]
					WHERE O.[OperationId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @operation X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Maintenance].[Operation] O;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @operation X;
		ELSE
			SELECT @number = COUNT(*) FROM [Maintenance].[Operation] O
			LEFT JOIN	@operation	X	ON	O.[OperationId] = X.[Id]
			WHERE X.[Id] IS NULL;

END
GO
