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
			O.[name]	= 'Range.Filter'))
	DROP PROCEDURE [Owner].[Range.Filter];
GO

CREATE PROCEDURE [Owner].[Range.Filter]
(
	@predicate		XML,
	@emplacementId	UNIQUEIDENTIFIER	= NULL,
	@applicationId	UNIQUEIDENTIFIER	= NULL,
	@organisations	XML					= NULL,
	@branches		XML					= NULL,
	@isCountable	BIT					= NULL,
	@guids			XML							OUTPUT,
	@isExcluded		BIT							OUTPUT,
	@isFiltered		BIT							OUTPUT,
	@number			INT							OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @range TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Ranges')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Range');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Owner].[Range.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @range SELECT * FROM @entities;
				ELSE
					INSERT @range SELECT R.[RangeId] FROM [Owner].[Range] R
					WHERE R.[RangeId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @range X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @range X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

--	Filter by branch predicate
	DECLARE 
		@branchPredicate	XML,
		@branchIsCountable	BIT,
		@branchGuids		XML,
		@branchIsFiltered	BIT,
		@branchNumber		INT;
	SELECT 
		@branchPredicate	= X.[Criteria],
		@branchIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/BranchPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @branch TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner].[Branch.Filter]
			@predicate,
			@emplacementId,
			@applicationId,
			@organisations,
			@branches,
			@isCountable,
			@guids		OUTPUT,
			@isExcluded OUTPUT,
			@isFiltered OUTPUT,
			@number		OUTPUT',
			N'@predicate	XML,
			@emplacementId	UNIQUEIDENTIFIER,
			@applicationId	UNIQUEIDENTIFIER,
			@organisations	XML,
			@branches		XML,
			@isCountable	BIT,
			@guids			XML OUTPUT,
			@isExcluded		BIT OUTPUT,
			@isFiltered		BIT OUTPUT,
			@number			INT OUTPUT',
			@predicate		= @branchPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@branches		= NULL,
			@isCountable	= @branchIsCountable,
			@guids			= @branchGuids		OUTPUT,
			@isExcluded		= @isExcluded		OUTPUT,
			@isFiltered		= @branchIsFiltered	OUTPUT,
			@number			= @branchNumber		OUTPUT;
		INSERT @branch SELECT * FROM [Common].[Guid.Entities](@branchGuids);
		IF (@branchIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @range SELECT R.[RangeId] FROM [Owner].[Range] R
					INNER JOIN	@branch	X	ON	R.[RangeBranchId]	= X.[Id];
				ELSE
					INSERT @range SELECT R.[RangeId] FROM [Owner].[Range] R
					LEFT JOIN	@branch	X	ON	R.[RangeBranchId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @range	X
					LEFT JOIN
					(
						SELECT R.[RangeId] FROM [Owner].[Range] R
						INNER JOIN	@branch	X	ON	R.[RangeBranchId]	= X.[Id]
					)	R	ON	X.[Id]	= R.[RangeId]
					WHERE R.[RangeId] IS NULL;
				ELSE
					DELETE X FROM @range	X
					LEFT JOIN
					(
						SELECT R.[RangeId] FROM [Owner].[Range] R
						LEFT JOIN	@branch	X	ON	R.[RangeBranchId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	R	ON	X.[Id]	= R.[RangeId]
					WHERE R.[RangeId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	DECLARE @branchIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@branches IS NOT NULL) BEGIN
		INSERT @branchIds SELECT * FROM [Common].[Guid.Entities](@branches);
		IF (@isFiltered = 0)
			INSERT @range SELECT R.[RangeId] FROM [Owner].[Range] R
			INNER JOIN	@branchIds		XB	ON	R.[RangeBranchId]	= XB.[Id];
		ELSE
			DELETE X FROM @range		X
			INNER JOIN	[Owner].[Range]	R	ON	X.[Id]				= R.[RangeId]
			LEFT JOIN	@branchIds		XB	ON	R.[RangeBranchId]	= XB.[Id]
			WHERE XB.[Id] IS NULL;
		SET @isFiltered = 1;
	END
	ELSE
		IF (@organisations IS NOT NULL) BEGIN
			INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
			IF (@isFiltered = 0)
				INSERT @range SELECT R.[RangeId] FROM [Owner].[Range] R
				INNER JOIN	[Owner].[Branch]	B	ON	R.[RangeBranchId]			= B.[BranchId]
				INNER JOIN	@organisationIds	XO	ON	B.[BranchOrganisationId]	= XO.[Id];
			ELSE
				DELETE X FROM @range			X 
				INNER JOIN	[Owner].[Range]		R	ON	X.[Id]						= R.[RangeId]
				INNER JOIN	[Owner].[Branch]	B	ON	R.[RangeBranchId]			= B.[BranchId]
				LEFT JOIN	@organisationIds	XO	ON	B.[BranchOrganisationId]	= XO.[Id]
				WHERE XO.[Id] IS NULL;
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
					INSERT @range SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
					INNER JOIN	@codes	X	ON	R.[RangeCode]	LIKE X.[Code];
				ELSE 
					INSERT @range SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
					LEFT JOIN	@codes	X	ON	R.[RangeCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @range	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
						INNER JOIN	@codes	X	ON	R.[RangeCode]	LIKE X.[Code]
					)	R	ON	X.[Id]	= R.[RangeId]
					WHERE R.[RangeId] IS NULL;
				ELSE
					DELETE X FROM @range	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
						LEFT JOIN	@codes	X	ON	R.[RangeCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	R	ON	X.[Id]	= R.[RangeId]
					WHERE R.[RangeId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by IP Numbers
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/IpNumbers')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @ipNumbers TABLE ([IpNumber] BIGINT);
		INSERT @ipNumbers SELECT DISTINCT * FROM [Common].[Long.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @range SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
					INNER JOIN	@ipNumbers	N	ON	N.[IpNumber]		BETWEEN R.[RangeIpNumberFrom] AND R.[RangeIpNumberTo];
				ELSE 
					INSERT @range SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
					INNER JOIN	@ipNumbers	N	ON	N.[IpNumber]	NOT	BETWEEN R.[RangeIpNumberFrom] AND R.[RangeIpNumberTo];
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @range	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
						INNER JOIN	@ipNumbers	N	ON	N.[IpNumber]		BETWEEN R.[RangeIpNumberFrom] AND R.[RangeIpNumberTo]
					)	R	ON	X.[Id]	= R.[RangeId]
					WHERE R.[RangeId] IS NULL;
				ELSE
					DELETE X FROM @range	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
						INNER JOIN	@ipNumbers	N	ON	N.[IpNumber]	NOT	BETWEEN R.[RangeIpNumberFrom] AND R.[RangeIpNumberTo]
					)	R	ON	X.[Id]	= R.[RangeId]
					WHERE R.[RangeId] IS NULL;
		SET @isFiltered = 1;
	END
  
--	Filter by IP data from
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/IpDataFrom')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @ipDataFrom TABLE ([IpDataFrom] NVARCHAR(MAX));
		INSERT @ipDataFrom SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @range SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
					INNER JOIN	@ipDataFrom	X	ON	R.[RangeIpDataFrom]	LIKE X.[IpDataFrom];
				ELSE 
					INSERT @range SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
					LEFT JOIN	@ipDataFrom	X	ON	R.[RangeIpDataFrom]	LIKE X.[IpDataFrom]
					WHERE X.[IpDataFrom] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @range	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
						INNER JOIN	@ipDataFrom	X	ON	R.[RangeIpDataFrom]	LIKE X.[IpDataFrom]
					)	R	ON	X.[Id]	= R.[RangeId]
					WHERE R.[RangeId] IS NULL;
				ELSE
					DELETE X FROM @range	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
						LEFT JOIN	@ipDataFrom	X	ON	R.[RangeIpDataFrom]	LIKE X.[IpDataFrom]
						WHERE X.[IpDataFrom] IS NULL
					)	R	ON	X.[Id]	= R.[RangeId]
					WHERE R.[RangeId] IS NULL;
		SET @isFiltered = 1;
	END
  
--	Filter by IP data to
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/IpDataFrom')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @ipDataTo TABLE ([IpDataTo] NVARCHAR(MAX));
		INSERT @ipDataTo SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @range SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
					INNER JOIN	@ipDataTo	X	ON	R.[RangeIpDataTo]	LIKE X.[IpDataTo];
				ELSE 
					INSERT @range SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
					LEFT JOIN	@ipDataTo	X	ON	R.[RangeIpDataTo]	LIKE X.[IpDataTo]
					WHERE X.[IpDataTo] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @range	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
						INNER JOIN	@ipDataTo	X	ON	R.[RangeIpDataTo]	LIKE X.[IpDataTo]
					)	R	ON	X.[Id]	= R.[RangeId]
					WHERE R.[RangeId] IS NULL;
				ELSE
					DELETE X FROM @range	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
						LEFT JOIN	@ipDataTo	X	ON	R.[RangeIpDataTo]	LIKE X.[IpDataTo]
						WHERE X.[IpDataTo] IS NULL
					)	R	ON	X.[Id]	= R.[RangeId]
					WHERE R.[RangeId] IS NULL;
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
					INSERT @range SELECT R.[RangeId] FROM [Owner].[Range] R
					WHERE R.[RangeLockedOn] BETWEEN ISNULL(@dateFrom, R.[RangeLockedOn]) AND ISNULL(@dateTo, R.[RangeLockedOn]);
				ELSE 
					INSERT @range SELECT R.[RangeId] FROM [Owner].[Range] R
					WHERE R.[RangeLockedOn] NOT BETWEEN ISNULL(@dateFrom, R.[RangeLockedOn]) AND ISNULL(@dateTo, R.[RangeLockedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @range	X
					LEFT JOIN
					(
						SELECT R.[RangeId] FROM [Owner].[Range] R
						WHERE R.[RangeLockedOn] BETWEEN ISNULL(@dateFrom, R.[RangeLockedOn]) AND ISNULL(@dateTo, R.[RangeLockedOn])
					)	R	ON	X.[Id]	= R.[RangeId]
					WHERE R.[RangeId] IS NULL;
				ELSE
					DELETE X FROM @range	X
					LEFT JOIN
					(
						SELECT R.[RangeId] FROM [Owner].[Range] R
						WHERE R.[RangeLockedOn] NOT BETWEEN ISNULL(@dateFrom, R.[RangeLockedOn]) AND ISNULL(@dateTo, R.[RangeLockedOn])
					)	R	ON	X.[Id]	= R.[RangeId]
					WHERE R.[RangeId] IS NULL;
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Codes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @descriptions TABLE ([Description] NVARCHAR(MAX));
		INSERT @descriptions SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @range SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
					INNER JOIN	@descriptions	X	ON	R.[RangeDescription]	LIKE X.[Description];
				ELSE 
					INSERT @range SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
					LEFT JOIN	@descriptions	X	ON	R.[RangeDescription]	LIKE X.[Description]
					WHERE X.[Description] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @range	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
						INNER JOIN	@descriptions	X	ON	R.[RangeDescription]	LIKE X.[Description]
					)	R	ON	X.[Id]	= R.[RangeId]
					WHERE R.[RangeId] IS NULL;
				ELSE
					DELETE X FROM @range	X
					LEFT JOIN
					(
						SELECT DISTINCT R.[RangeId] FROM [Owner].[Range] R
						LEFT JOIN	@descriptions	X	ON	R.[RangeDescription]	LIKE X.[Description]
						WHERE X.[Description] IS NULL
					)	R	ON	X.[Id]	= R.[RangeId]
					WHERE R.[RangeId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @range SELECT R.[RangeId] FROM [Owner].[Range] R
			INNER JOIN	[Owner].[Branch]		B	ON	R.[RangeBranchId]			= B.[BranchId]
			INNER JOIN	[Owner].[Organisation]	O	ON	B.[BranchOrganisationId]	= O.[OrganisationId]
			WHERE O.[OrganisationEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @range	X
			LEFT JOIN
			(
				SELECT R.[RangeId] FROM [Owner].[Range] R
				INNER JOIN	[Owner].[Branch]			B	ON	R.[RangeBranchId]			= B.[BranchId]
				INNER JOIN	[Owner].[Organisation]		O	ON	B.[BranchOrganisationId]	= O.[OrganisationId]
				WHERE O.[OrganisationEmplacementId] = @emplacementId
			)	R	ON	X.[Id]	= R.[RangeId]
			WHERE R.[RangeId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @range X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Owner].[Range] R;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @range X;
		ELSE
			IF (@branches IS NOT NULL)
				SELECT @number = COUNT(*) FROM [Owner].[Range] R
				INNER JOIN	[Owner].[Branch]		B	ON	R.[RangeBranchId]			= B.[BranchId]
				INNER JOIN	[Owner].[Organisation]	O	ON	B.[BranchOrganisationId]	= O.[OrganisationId]
				INNER JOIN	@branchIds				XB	ON	R.[RangeBranchId]			= XB.[Id]
				LEFT JOIN	@range					X	ON	R.[RangeId]					= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE
				IF (@organisations IS NULL)
					SELECT @number = COUNT(*) FROM [Owner].[Range] R
					INNER JOIN	[Owner].[Branch]		B	ON	R.[RangeBranchId]			= B.[BranchId]
					INNER JOIN	[Owner].[Organisation]	O	ON	B.[BranchOrganisationId]	= O.[OrganisationId]
					LEFT JOIN	@range					X	ON	R.[RangeId]					= X.[Id]
					WHERE 
						O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
						X.[Id] IS NULL;
				ELSE                  
					SELECT @number = COUNT(*) FROM [Owner].[Range] R
					INNER JOIN	[Owner].[Branch]		B	ON	R.[RangeBranchId]			= B.[BranchId]
					INNER JOIN	[Owner].[Organisation]	O	ON	B.[BranchOrganisationId]	= O.[OrganisationId]
					INNER JOIN	@organisationIds		XO	ON	O.[OrganisationId]			= XO.[Id]
					LEFT JOIN	@range					X	ON	R.[RangeId]					= X.[Id]
					WHERE 
						O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
						X.[Id] IS NULL;

END
GO
