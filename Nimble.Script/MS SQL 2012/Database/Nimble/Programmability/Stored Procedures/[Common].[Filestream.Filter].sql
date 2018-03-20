SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	F
		INNER JOIN	[sys].[objects]		O	ON	F.[schema_id]	= O.[schema_id]
		WHERE 
			F.[name]	= 'Common'	AND
			O.[type]	= 'P'		AND
			O.[name]	= 'Filestream.Filter'))
	DROP PROCEDURE [Common].[Filestream.Filter];
GO

CREATE PROCEDURE [Common].[Filestream.Filter]
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

	DECLARE @filestream TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Filestreams')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Filestream');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Common].[Filestream.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT * FROM @entities;
				ELSE
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					WHERE F.[FilestreamId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @filestream X WHERE X.[Id] IN (SELECT * FROM @entities);
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
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@entityIds	X	ON	F.[FilestreamEntityId]	= X.[EntityId];
				ELSE 
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@entityIds	X	ON	F.[FilestreamEntityId]	= X.[EntityId]
					WHERE X.[EntityId] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@entityIds	X	ON	F.[FilestreamEntityId]	= X.[EntityId]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@entityIds	X	ON	F.[FilestreamEntityId]	= X.[EntityId]
						WHERE X.[EntityId] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by referenceIds
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/ReferenceIds')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @referenceIds TABLE ([ReferenceId] NVARCHAR(MAX));
		INSERT @referenceIds SELECT DISTINCT * FROM [Common].[Guid.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@referenceIds	X	ON	F.[FilestreamReferenceId]	LIKE X.[ReferenceId];
				ELSE 
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@referenceIds	X	ON	F.[FilestreamReferenceId]	LIKE X.[ReferenceId]
					WHERE X.[ReferenceId] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@referenceIds	X	ON	F.[FilestreamReferenceId]	LIKE X.[ReferenceId]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@referenceIds	X	ON	F.[FilestreamReferenceId]	LIKE X.[ReferenceId]
						WHERE X.[ReferenceId] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by organisations/person
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@organisations IS NOT NULL) BEGIN
		INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
		IF (@isFiltered = 0)
			INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
			LEFT JOIN	@organisationIds	XO	ON	F.[FilestreamOrganisationId]	= XO.[Id]
			WHERE 
				F.[FilestreamPersonId] = @personId OR
				XO.[Id] IS NOT NULL;
		ELSE
			DELETE X FROM @filestream			X
			INNER JOIN	[Common].[Filestream]	F	ON	X.[Id]							= F.[FilestreamId]
			LEFT JOIN	@organisationIds		XO	ON	F.[FilestreamOrganisationId]	= XO.[Id]
			WHERE 
				F.[FilestreamPersonId] <> @personId AND
				XO.[Id] IS NULL;
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
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@codes	X	ON	F.[FilestreamCode]	LIKE X.[Code];
				ELSE 
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@codes	X	ON	F.[FilestreamCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@codes	X	ON	F.[FilestreamCode]	LIKE X.[Code]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@codes	X	ON	F.[FilestreamCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
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
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					WHERE F.[FilestreamCreatedOn] BETWEEN ISNULL(@dateFrom, F.[FilestreamCreatedOn]) AND ISNULL(@dateTo, F.[FilestreamCreatedOn]);
				ELSE 
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					WHERE F.[FilestreamCreatedOn] NOT BETWEEN ISNULL(@dateFrom, F.[FilestreamCreatedOn]) AND ISNULL(@dateTo, F.[FilestreamCreatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						WHERE F.[FilestreamCreatedOn] BETWEEN ISNULL(@dateFrom, F.[FilestreamCreatedOn]) AND ISNULL(@dateTo, F.[FilestreamCreatedOn])
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						WHERE F.[FilestreamCreatedOn] NOT BETWEEN ISNULL(@dateFrom, F.[FilestreamCreatedOn]) AND ISNULL(@dateTo, F.[FilestreamCreatedOn])
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by names
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Names')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @names TABLE ([Name] NVARCHAR(MAX));
		INSERT @names SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@names	X	ON	F.[FilestreamName]	LIKE X.[Name];
				ELSE 
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@names	X	ON	F.[FilestreamName]	LIKE X.[Name]
					WHERE X.[Name] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@names	X	ON	F.[FilestreamName]	LIKE X.[Name]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@names	X	ON	F.[FilestreamName]	LIKE X.[Name]
						WHERE X.[Name] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
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
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@descriptions	X	ON	F.[FilestreamDescription]	LIKE X.[Description];
				ELSE 
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@descriptions	X	ON	F.[FilestreamDescription]	LIKE X.[Description]
					WHERE X.[Description] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@descriptions	X	ON	F.[FilestreamDescription]	LIKE X.[Description]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@descriptions	X	ON	F.[FilestreamDescription]	LIKE X.[Description]
						WHERE X.[Description] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by extensions
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Extensions')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @extensions TABLE ([Extension] NVARCHAR(MAX));
		INSERT @extensions SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@extensions	X	ON	F.[FilestreamExtension]	LIKE X.[Extension];
				ELSE 
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@extensions	X	ON	F.[FilestreamExtension]	LIKE X.[Extension]
					WHERE X.[Extension] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@extensions	X	ON	F.[FilestreamExtension]	LIKE X.[Extension]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@extensions	X	ON	F.[FilestreamExtension]	LIKE X.[Extension]
						WHERE X.[Extension] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by default status
	DECLARE @isDefault BIT;
	SET @isDefault = [Common].[Bool.Entity](@predicate.query('/*/IsDefault'));
	IF (@isDefault IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
			WHERE F.[FilestreamIsDefault] = @isDefault;
		ELSE
			DELETE X FROM @filestream	X
			LEFT JOIN
			(
				SELECT F.[FilestreamId] FROM [Common].[Filestream] F
				WHERE F.[FilestreamIsDefault] = @isDefault
			)	F	ON	X.[Id]	= F.[FilestreamId]
			WHERE F.[FilestreamId]	IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by urls
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Urls')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @urls TABLE ([Url] NVARCHAR(MAX));
		INSERT @urls SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@urls	X	ON	F.[FilestreamUrl]	LIKE X.[Url];
				ELSE 
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@urls	X	ON	F.[FilestreamUrl]	LIKE X.[Url]
					WHERE X.[Url] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@urls	X	ON	F.[FilestreamUrl]	LIKE X.[Url]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@urls	X	ON	F.[FilestreamUrl]	LIKE X.[Url]
						WHERE X.[Url] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by thumbnailIds
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/ThumbnailIds')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @thumbnailIds TABLE ([ThumbnailId] NVARCHAR(MAX));
		INSERT @thumbnailIds SELECT DISTINCT * FROM [Common].[Guid.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@thumbnailIds	X	ON	F.[FilestreamThumbnailId]	LIKE X.[ThumbnailId];
				ELSE 
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@thumbnailIds	X	ON	F.[FilestreamThumbnailId]	LIKE X.[ThumbnailId]
					WHERE X.[ThumbnailId] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@thumbnailIds	X	ON	F.[FilestreamThumbnailId]	LIKE X.[ThumbnailId]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@thumbnailIds	X	ON	F.[FilestreamThumbnailId]	LIKE X.[ThumbnailId]
						WHERE X.[ThumbnailId] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by thumbnail width
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/ThumbnailWidth')) X;
	IF (@criteriaExist = 1) BEGIN
		SELECT @amountFrom = NULL, @amountTo = NULL;
		SELECT 
			@amountFrom	= X.[AmountFrom], 
			@amountTo	= X.[AmountTo] 
		FROM [Common].[AmountInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@amountFrom, @amountTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					WHERE F.[FilestreamThumbnailWidth] BETWEEN ISNULL(@amountFrom, F.[FilestreamThumbnailWidth]) AND ISNULL(@amountTo, F.[FilestreamThumbnailWidth]);
				ELSE 
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					WHERE F.[FilestreamThumbnailWidth] NOT BETWEEN ISNULL(@amountFrom, F.[FilestreamThumbnailWidth]) AND ISNULL(@amountTo, F.[FilestreamThumbnailWidth]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						WHERE F.[FilestreamThumbnailWidth] BETWEEN ISNULL(@amountFrom, F.[FilestreamThumbnailWidth]) AND ISNULL(@amountTo, F.[FilestreamThumbnailWidth])
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						WHERE F.[FilestreamThumbnailWidth] NOT BETWEEN ISNULL(@amountFrom, F.[FilestreamThumbnailWidth]) AND ISNULL(@amountTo, F.[FilestreamThumbnailWidth])
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
		ELSE
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					WHERE F.[FilestreamThumbnailWidth] IS NULL;
				ELSE 
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					WHERE F.[FilestreamThumbnailWidth] IS NOT NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						WHERE F.[FilestreamThumbnailWidth] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						WHERE F.[FilestreamThumbnailWidth] IS NOT NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by thumbnail height
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/ThumbnailHeight')) X;
	IF (@criteriaExist = 1) BEGIN
		SELECT @amountFrom = NULL, @amountTo = NULL;
		SELECT 
			@amountFrom	= X.[AmountFrom], 
			@amountTo	= X.[AmountTo] 
		FROM [Common].[AmountInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@amountFrom, @amountTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					WHERE F.[FilestreamThumbnailHeight] BETWEEN ISNULL(@amountFrom, F.[FilestreamThumbnailHeight]) AND ISNULL(@amountTo, F.[FilestreamThumbnailHeight]);
				ELSE 
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					WHERE F.[FilestreamThumbnailHeight] NOT BETWEEN ISNULL(@amountFrom, F.[FilestreamThumbnailHeight]) AND ISNULL(@amountTo, F.[FilestreamThumbnailHeight]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						WHERE F.[FilestreamThumbnailHeight] BETWEEN ISNULL(@amountFrom, F.[FilestreamThumbnailHeight]) AND ISNULL(@amountTo, F.[FilestreamThumbnailHeight])
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						WHERE F.[FilestreamThumbnailHeight] NOT BETWEEN ISNULL(@amountFrom, F.[FilestreamThumbnailHeight]) AND ISNULL(@amountTo, F.[FilestreamThumbnailHeight])
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
		ELSE
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					WHERE F.[FilestreamThumbnailHeight] IS NULL;
				ELSE 
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					WHERE F.[FilestreamThumbnailHeight] IS NOT NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						WHERE F.[FilestreamThumbnailHeight] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						WHERE F.[FilestreamThumbnailHeight] IS NOT NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by thumbnail extensions
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/ThumbnailExtensions')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @thumbnailExtensions TABLE ([ThumbnailExtension] NVARCHAR(MAX));
		INSERT @thumbnailExtensions SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@thumbnailExtensions	X	ON	F.[FilestreamThumbnailExtension]	LIKE X.[ThumbnailExtension];
				ELSE 
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@thumbnailExtensions	X	ON	F.[FilestreamThumbnailExtension]	LIKE X.[ThumbnailExtension]
					WHERE X.[ThumbnailExtension] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@thumbnailExtensions	X	ON	F.[FilestreamThumbnailExtension]	LIKE X.[ThumbnailExtension]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@thumbnailExtensions	X	ON	F.[FilestreamThumbnailExtension]	LIKE X.[ThumbnailExtension]
						WHERE X.[ThumbnailExtension] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by thumbnail urls
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/ThumbnailUrls')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @thumbnailUrls TABLE ([ThumbnailUrl] NVARCHAR(MAX));
		INSERT @thumbnailUrls SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@thumbnailUrls	X	ON	F.[FilestreamThumbnailUrl]	LIKE X.[ThumbnailUrl];
				ELSE 
					INSERT @filestream SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@thumbnailUrls	X	ON	F.[FilestreamThumbnailUrl]	LIKE X.[ThumbnailUrl]
					WHERE X.[ThumbnailUrl] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@thumbnailUrls	X	ON	F.[FilestreamThumbnailUrl]	LIKE X.[ThumbnailUrl]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT DISTINCT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@thumbnailUrls	X	ON	F.[FilestreamThumbnailUrl]	LIKE X.[ThumbnailUrl]
						WHERE X.[ThumbnailUrl] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
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
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@person	X	ON	F.[FilestreamEntityId]	= X.[Id];
				ELSE
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@person	X	ON	F.[FilestreamEntityId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@person	X	ON	F.[FilestreamEntityId]	= X.[Id]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@person	X	ON	F.[FilestreamEntityId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisation predicate
	DECLARE 
		@organisationPredicate		XML,
		@organisationIsCountable	BIT,
		@organisationGuids			XML,
		@organisationIsFiltered		BIT,
		@organisationNumber			INT;
	SELECT 
		@organisationPredicate		= X.[Criteria],
		@organisationIsCountable	= 0,
		@criteriaExist				= X.[CriteriaExist],
		@isExcluded					= X.[CriteriaIsExcluded],
		@criteriaIsNull				= X.[CriteriaIsNull],
		@criteriaValue				= X.[CriteriaValue],
		@criteriaValueExist			= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/OrganisationPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @organisation TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner].[Organisation.Filter]
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
			@predicate		= @organisationPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @organisationIsCountable,
			@guids			= @organisationGuids		OUTPUT,
			@isExcluded		= @isExcluded				OUTPUT,
			@isFiltered		= @organisationIsFiltered	OUTPUT,
			@number			= @organisationNumber		OUTPUT;
		INSERT @organisation SELECT * FROM [Common].[Guid.Entities](@organisationGuids);
		IF (@organisationIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@organisation	X	ON	F.[FilestreamEntityId]	= X.[Id];
				ELSE
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@organisation	X	ON	F.[FilestreamEntityId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@organisation	X	ON	F.[FilestreamEntityId]	= X.[Id]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@organisation	X	ON	F.[FilestreamEntityId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by employee predicate
	DECLARE 
		@employeePredicate		XML,
		@employeeIsCountable	BIT,
		@employeeGuids			XML,
		@employeeIsFiltered		BIT,
		@employeeNumber			INT;
	SELECT 
		@employeePredicate		= X.[Criteria],
		@employeeIsCountable	= 0,
		@criteriaExist			= X.[CriteriaExist],
		@isExcluded				= X.[CriteriaIsExcluded],
		@criteriaIsNull			= X.[CriteriaIsNull],
		@criteriaValue			= X.[CriteriaValue],
		@criteriaValueExist		= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/EmployeePredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @employee TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner].[Employee.Filter]
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
			@predicate		= @employeePredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @employeeIsCountable,
			@guids			= @employeeGuids			OUTPUT,
			@isExcluded		= @isExcluded			OUTPUT,
			@isFiltered		= @employeeIsFiltered	OUTPUT,
			@number			= @employeeNumber		OUTPUT;
		INSERT @employee SELECT * FROM [Common].[Guid.Entities](@employeeGuids);
		IF (@employeeIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@employee	X	ON	F.[FilestreamEntityId]	= X.[Id];
				ELSE
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@employee	X	ON	F.[FilestreamEntityId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@employee	X	ON	F.[FilestreamEntityId]	= X.[Id]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@employee	X	ON	F.[FilestreamEntityId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
			SET @isFiltered = 1;
		END
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
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@branch	X	ON	F.[FilestreamEntityId]	= X.[Id];
				ELSE
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@branch	X	ON	F.[FilestreamEntityId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@branch	X	ON	F.[FilestreamEntityId]	= X.[Id]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@branch	X	ON	F.[FilestreamEntityId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by branch group predicate
	DECLARE 
		@branchGroupPredicate	XML,
		@branchGroupIsCountable	BIT,
		@branchGroupGuids		XML,
		@branchGroupIsFiltered	BIT,
		@branchGroupNumber		INT;
	SELECT 
		@branchGroupPredicate	= X.[Criteria],
		@branchGroupIsCountable	= 0,
		@criteriaExist			= X.[CriteriaExist],
		@isExcluded				= X.[CriteriaIsExcluded],
		@criteriaIsNull			= X.[CriteriaIsNull],
		@criteriaValue			= X.[CriteriaValue],
		@criteriaValueExist		= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/BranchGroupPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @branchGroup TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner.Branch].[Group.Filter]
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
			@predicate		= @branchGroupPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @branchGroupIsCountable,
			@guids			= @branchGroupGuids			OUTPUT,
			@isExcluded		= @isExcluded				OUTPUT,
			@isFiltered		= @branchGroupIsFiltered	OUTPUT,
			@number			= @branchGroupNumber		OUTPUT;
		INSERT @branchGroup SELECT * FROM [Common].[Guid.Entities](@branchGroupGuids);
		IF (@branchGroupIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@branchGroup	X	ON	F.[FilestreamEntityId]	= X.[Id];
				ELSE
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@branchGroup	X	ON	F.[FilestreamEntityId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@branchGroup	X	ON	F.[FilestreamEntityId]	= X.[Id]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@branchGroup	X	ON	F.[FilestreamEntityId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by post predicate
	DECLARE 
		@postPredicate		XML,
		@postIsCountable	BIT,
		@postGuids			XML,
		@postIsFiltered		BIT,
		@postNumber			INT;
	SELECT 
		@postPredicate		= X.[Criteria],
		@postIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/PostPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @post TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner].[Post.Filter]
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
			@predicate		= @postPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @postIsCountable,
			@guids			= @postGuids		OUTPUT,
			@isExcluded		= @isExcluded		OUTPUT,
			@isFiltered		= @postIsFiltered	OUTPUT,
			@number			= @postNumber		OUTPUT;
		INSERT @post SELECT * FROM [Common].[Guid.Entities](@postGuids);
		IF (@postIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@post	X	ON	F.[FilestreamEntityId]	= X.[Id];
				ELSE
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@post	X	ON	F.[FilestreamEntityId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@post	X	ON	F.[FilestreamEntityId]	= X.[Id]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@post	X	ON	F.[FilestreamEntityId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by post group predicate
	DECLARE 
		@postGroupPredicate		XML,
		@postGroupIsCountable	BIT,
		@postGroupGuids			XML,
		@postGroupIsFiltered	BIT,
		@postGroupNumber		INT;
	SELECT 
		@postGroupPredicate		= X.[Criteria],
		@postGroupIsCountable	= 0,
		@criteriaExist			= X.[CriteriaExist],
		@isExcluded				= X.[CriteriaIsExcluded],
		@criteriaIsNull			= X.[CriteriaIsNull],
		@criteriaValue			= X.[CriteriaValue],
		@criteriaValueExist		= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/PostGroupPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @postGroup TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner.Post].[Group.Filter]
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
			@predicate		= @postGroupPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @postGroupIsCountable,
			@guids			= @postGroupGuids		OUTPUT,
			@isExcluded		= @isExcluded			OUTPUT,
			@isFiltered		= @postGroupIsFiltered	OUTPUT,
			@number			= @postGroupNumber		OUTPUT;
		INSERT @postGroup SELECT * FROM [Common].[Guid.Entities](@postGroupGuids);
		IF (@postGroupIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					INNER JOIN	@postGroup	X	ON	F.[FilestreamEntityId]	= X.[Id];
				ELSE
					INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
					LEFT JOIN	@postGroup	X	ON	F.[FilestreamEntityId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						INNER JOIN	@postGroup	X	ON	F.[FilestreamEntityId]	= X.[Id]
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
				ELSE
					DELETE X FROM @filestream	X
					LEFT JOIN
					(
						SELECT F.[FilestreamId] FROM [Common].[Filestream] F
						LEFT JOIN	@postGroup	X	ON	F.[FilestreamEntityId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	F	ON	X.[Id]	= F.[FilestreamId]
					WHERE F.[FilestreamId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @filestream SELECT F.[FilestreamId] FROM [Common].[Filestream] F
			WHERE F.[FilestreamEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @filestream	X
			LEFT JOIN	(
				SELECT F.[FilestreamId] FROM [Common].[Filestream] F
				WHERE F.[FilestreamEmplacementId] = @emplacementId
			)	F	ON	X.[Id]	= F.[FilestreamId]
			WHERE F.[FilestreamId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @filestream X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Common].[Filestream] F;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @filestream X;
		ELSE
			IF (@organisations IS NULL)
				SELECT @number = COUNT(*) FROM [Common].[Filestream]	F
				LEFT JOIN	@filestream	X	ON	F.[FilestreamId]	= X.[Id]
				WHERE 
					F.[FilestreamEmplacementId] = ISNULL(@emplacementId, F.[FilestreamEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE
				SELECT @number = COUNT(*) FROM [Common].[Filestream]	F
				LEFT JOIN	@organisationIds	XO	ON	F.[FilestreamOrganisationId]	= XO.[Id]
				LEFT JOIN	@filestream			X	ON	F.[FilestreamId]				= X.[Id]
				WHERE 
					F.[FilestreamEmplacementId] = ISNULL(@emplacementId, F.[FilestreamEmplacementId])	AND
					(
						F.[FilestreamPersonId] = @personId OR
						XO.[Id] IS NOT NULL
					)																					AND
					X.[Id] IS NULL;

END
GO
