SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Notification'	AND
			O.[type]	= 'P'				AND
			O.[name]	= 'Publisher.Filter'))
	DROP PROCEDURE [Notification].[Publisher.Filter];
GO

CREATE PROCEDURE [Notification].[Publisher.Filter]
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

	DECLARE @publisher TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
	DECLARE 
		@criteria			XML,
		@criteriaExist		BIT,
		@criteriaIsNull		BIT,
		@criteriaValue		XML,
		@criteriaValueExist	BIT,
		@amountFrom			DECIMAL(28, 9),
		@amountTo			DECIMAL(28, 9),
		@dateFrom			DATETIMEOFFSET,
		@dateTo				DATETIMEOFFSET,
		@flagsLine			NVARCHAR(MAX),
		@flagsIsExact		BIT;
	
	SET @isFiltered = 0;

--	Filter by entities
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Publishers')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Publisher');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Notification].[Publisher.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @publisher SELECT * FROM @entities;
				ELSE
					INSERT @publisher SELECT P.[PublisherId] FROM [Notification].[Publisher] P
					WHERE P.[PublisherId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @publisher X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @publisher X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
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
					INSERT @publisher SELECT P.[PublisherId] FROM [Notification].[Publisher] P
					INNER JOIN	@organisation	X	ON	P.[PublisherOrganisationId]	= X.[Id];
				ELSE
					INSERT @publisher SELECT P.[PublisherId] FROM [Notification].[Publisher] P
					LEFT JOIN	@organisation	X	ON	P.[PublisherOrganisationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @publisher	X
					LEFT JOIN
					(
						SELECT P.[PublisherId] FROM [Notification].[Publisher] P
						INNER JOIN	@organisation	X	ON	P.[PublisherOrganisationId]	= X.[Id]
					)	P	ON	X.[Id]	= P.[PublisherId]
					WHERE P.[PublisherId] IS NULL;
				ELSE
					DELETE X FROM @publisher	X
					LEFT JOIN
					(
						SELECT P.[PublisherId] FROM [Notification].[Publisher] P
						LEFT JOIN	@organisation	X	ON	P.[PublisherOrganisationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	P	ON	X.[Id]	= P.[PublisherId]
					WHERE P.[PublisherId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@organisations IS NOT NULL) BEGIN
		INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
		IF (@isFiltered = 0)
			INSERT @publisher SELECT P.[PublisherId] FROM [Notification].[Publisher] P
			INNER JOIN	@organisationIds	XO	ON	P.[PublisherOrganisationId]	= XO.[Id];
		ELSE
			DELETE X FROM @publisher				X 
			INNER JOIN	[Notification].[Publisher]	P	ON	X.[Id]						= P.[PublisherId]
			LEFT JOIN	@organisationIds			XO	ON	P.[PublisherOrganisationId]	= XO.[Id]
			WHERE XO.[Id] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by publisher notification type
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/NotificationType')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SELECT @flagsLine = NULL, @flagsIsExact = NULL;
		SELECT 
			@flagsLine		= X.[Line], 
			@flagsIsExact	= X.[IsExact] 
		FROM [Common].[Flags.Entity](@criteriaValue) X;
		IF (LEN(@flagsLine) > 0 OR @flagsIsExact = 1)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @publisher SELECT P.[PublisherId] FROM [Notification].[Publisher] P
					WHERE [Common].[Flags.LineIsEqual](P.[PublisherNotificationType], @flagsLine, @flagsIsExact) = 1;
				ELSE 
					INSERT @publisher SELECT P.[PublisherId] FROM [Notification].[Publisher] P
					WHERE [Common].[Flags.LineIsEqual](P.[PublisherNotificationType], @flagsLine, @flagsIsExact) = 0;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @publisher	X
					LEFT JOIN
					(
						SELECT P.[PublisherId] FROM [Notification].[Publisher] P
						WHERE [Common].[Flags.LineIsEqual](P.[PublisherNotificationType], @flagsLine, @flagsIsExact) = 1
					)	P	ON	X.[Id]	= P.[PublisherId]
					WHERE P.[PublisherId] IS NULL;
				ELSE
					DELETE X FROM @publisher	X
					LEFT JOIN
					(
						SELECT P.[PublisherId] FROM [Notification].[Publisher] P
						WHERE [Common].[Flags.LineIsEqual](P.[PublisherNotificationType], @flagsLine, @flagsIsExact) = 0
					)	P	ON	X.[Id]	= P.[PublisherId]
					WHERE P.[PublisherId] IS NULL;
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
					INSERT @publisher SELECT P.[PublisherId] FROM [Notification].[Publisher] P
					WHERE P.[PublisherCreatedOn] BETWEEN ISNULL(@dateFrom, P.[PublisherCreatedOn]) AND ISNULL(@dateTo, P.[PublisherCreatedOn]);
				ELSE 
					INSERT @publisher SELECT P.[PublisherId] FROM [Notification].[Publisher] P
					WHERE P.[PublisherCreatedOn] NOT BETWEEN ISNULL(@dateFrom, P.[PublisherCreatedOn]) AND ISNULL(@dateTo, P.[PublisherCreatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @publisher	X
					LEFT JOIN
					(
						SELECT P.[PublisherId] FROM [Notification].[Publisher] P
						WHERE P.[PublisherCreatedOn] BETWEEN ISNULL(@dateFrom, P.[PublisherCreatedOn]) AND ISNULL(@dateTo, P.[PublisherCreatedOn])
					)	P	ON	X.[Id]	= P.[PublisherId]
					WHERE P.[PublisherId] IS NULL;
				ELSE
					DELETE X FROM @publisher	X
					LEFT JOIN
					(
						SELECT P.[PublisherId] FROM [Notification].[Publisher] P
						WHERE P.[PublisherCreatedOn] NOT BETWEEN ISNULL(@dateFrom, P.[PublisherCreatedOn]) AND ISNULL(@dateTo, P.[PublisherCreatedOn])
					)	P	ON	X.[Id]	= P.[PublisherId]
					WHERE P.[PublisherId] IS NULL;
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
					INSERT @publisher SELECT P.[PublisherId] FROM [Notification].[Publisher] P
					WHERE P.[PublisherLockedOn] BETWEEN ISNULL(@dateFrom, P.[PublisherLockedOn]) AND ISNULL(@dateTo, P.[PublisherLockedOn]);
				ELSE 
					INSERT @publisher SELECT P.[PublisherId] FROM [Notification].[Publisher] P
					WHERE P.[PublisherLockedOn] NOT BETWEEN ISNULL(@dateFrom, P.[PublisherLockedOn]) AND ISNULL(@dateTo, P.[PublisherLockedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @publisher	X
					LEFT JOIN
					(
						SELECT P.[PublisherId] FROM [Notification].[Publisher] P
						WHERE P.[PublisherLockedOn] BETWEEN ISNULL(@dateFrom, P.[PublisherLockedOn]) AND ISNULL(@dateTo, P.[PublisherLockedOn])
					)	P	ON	X.[Id]	= P.[PublisherId]
					WHERE P.[PublisherId] IS NULL;
				ELSE
					DELETE X FROM @publisher	X
					LEFT JOIN
					(
						SELECT P.[PublisherId] FROM [Notification].[Publisher] P
						WHERE P.[PublisherLockedOn] NOT BETWEEN ISNULL(@dateFrom, P.[PublisherLockedOn]) AND ISNULL(@dateTo, P.[PublisherLockedOn])
					)	P	ON	X.[Id]	= P.[PublisherId]
					WHERE P.[PublisherId] IS NULL;
		ELSE IF (@criteriaIsNull = 1)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @publisher SELECT P.[PublisherId] FROM [Notification].[Publisher] P
					WHERE P.[PublisherLockedOn] IS NULL;
				ELSE 
					INSERT @publisher SELECT P.[PublisherId] FROM [Notification].[Publisher] P
					WHERE P.[PublisherLockedOn] IS NOT NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @publisher	X
					LEFT JOIN
					(
						SELECT P.[PublisherId] FROM [Notification].[Publisher] P
						WHERE P.[PublisherLockedOn] IS NULL
					)	P	ON	X.[Id]	= P.[PublisherId]
					WHERE P.[PublisherId] IS NULL;
				ELSE
					DELETE X FROM @publisher	X
					LEFT JOIN
					(
						SELECT P.[PublisherId] FROM [Notification].[Publisher] P
						WHERE P.[PublisherLockedOn] IS NOT NULL
					)	P	ON	X.[Id]	= P.[PublisherId]
					WHERE P.[PublisherId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @publisher SELECT P.[PublisherId] FROM [Notification].[Publisher] P
			INNER JOIN	[Owner].[Organisation]	O	ON	P.[PublisherOrganisationId]	= O.[OrganisationId]
			WHERE O.[OrganisationEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @publisher	X
			LEFT JOIN
			(
				SELECT P.[PublisherId] FROM [Notification].[Publisher]	P
				INNER JOIN	[Owner].[Organisation]	O	ON	P.[PublisherOrganisationId]	= O.[OrganisationId]
				WHERE O.[OrganisationEmplacementId] = @emplacementId
			)	P	ON	X.[Id]	= P.[PublisherId]
			WHERE P.[PublisherId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @publisher X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Notification].[Publisher] P;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @publisher X;
		ELSE
			IF (@organisations IS NULL)
				SELECT @number = COUNT(*) FROM [Notification].[Publisher] P
				INNER JOIN	[Owner].[Organisation]	O	ON	P.[PublisherOrganisationId]	= O.[OrganisationId]
				LEFT JOIN	@publisher				X	ON	P.[PublisherId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE
				SELECT @number = COUNT(*) FROM [Notification].[Publisher] P
				INNER JOIN	[Owner].[Organisation]	O	ON	P.[PublisherOrganisationId]	= O.[OrganisationId]
				INNER JOIN	@organisationIds		XO	ON	O.[OrganisationId]			= XO.[Id]
				LEFT JOIN	@publisher				X	ON	P.[PublisherId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;

END
GO
