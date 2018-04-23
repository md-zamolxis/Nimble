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
			O.[name]	= 'Subscriber.Filter'))
	DROP PROCEDURE [Notification].[Subscriber.Filter];
GO

CREATE PROCEDURE [Notification].[Subscriber.Filter]
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

	DECLARE @subscriber TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
	DECLARE 
		@criteria			XML,
		@criteriaExist		BIT,
		@criteriaIsNull		BIT,
		@criteriaValue		XML,
		@criteriaValueExist	BIT,
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Subscribers')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Subscriber');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Notification].[Subscriber.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @subscriber SELECT * FROM @entities;
				ELSE
					INSERT @subscriber SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
					WHERE S.[SubscriberId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @subscriber X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @subscriber X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

--	Filter by publisher predicate
	DECLARE 
		@publisherPredicate		XML,
		@publisherIsCountable	BIT,
		@publisherGuids			XML,
		@publisherIsFiltered	BIT,
		@publisherNumber		INT;
	SELECT 
		@publisherPredicate		= X.[Criteria],
		@publisherIsCountable	= 0,
		@criteriaExist			= X.[CriteriaExist],
		@isExcluded				= X.[CriteriaIsExcluded],
		@criteriaIsNull			= X.[CriteriaIsNull],
		@criteriaValue			= X.[CriteriaValue],
		@criteriaValueExist		= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/PublisherPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @publisher TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Notification].[Publisher.Filter]
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
			@predicate		= @publisherPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @publisherIsCountable,
			@guids			= @publisherGuids		OUTPUT,
			@isExcluded		= @isExcluded			OUTPUT,
			@isFiltered		= @publisherIsFiltered	OUTPUT,
			@number			= @publisherNumber		OUTPUT;
		INSERT @publisher SELECT * FROM [Common].[Guid.Entities](@publisherGuids);
		IF (@publisherIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @subscriber SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
					INNER JOIN	@publisher	X	ON	S.[SubscriberPublisherId]	= X.[Id];
				ELSE
					INSERT @subscriber SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
					LEFT JOIN	@publisher	X	ON	S.[SubscriberPublisherId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @subscriber	X
					LEFT JOIN
					(
						SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
						INNER JOIN	@publisher	X	ON	S.[SubscriberPublisherId]	= X.[Id]
					)	S	ON	X.[Id]	= S.[SubscriberId]
					WHERE S.[SubscriberId] IS NULL;
				ELSE
					DELETE X FROM @subscriber	X
					LEFT JOIN
					(
						SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
						LEFT JOIN	@publisher	X	ON	S.[SubscriberPublisherId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	S	ON	X.[Id]	= S.[SubscriberId]
					WHERE S.[SubscriberId] IS NULL;
			SET @isFiltered = 1;
		END
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
					INSERT @subscriber SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
					INNER JOIN	@person	X	ON	S.[SubscriberPersonId]	= X.[Id];
				ELSE
					INSERT @subscriber SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
					LEFT JOIN	@person	X	ON	S.[SubscriberPersonId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @subscriber	X
					LEFT JOIN
					(
						SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
						INNER JOIN	@person	X	ON	S.[SubscriberPersonId]	= X.[Id]
					)	S	ON	X.[Id]	= S.[SubscriberId]
					WHERE S.[SubscriberId] IS NULL;
				ELSE
					DELETE X FROM @subscriber	X
					LEFT JOIN
					(
						SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
						LEFT JOIN	@person	X	ON	S.[SubscriberPersonId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	S	ON	X.[Id]	= S.[SubscriberId]
					WHERE S.[SubscriberId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@organisations IS NOT NULL) BEGIN
		INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
		IF (@isFiltered = 0)
			INSERT @subscriber SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
			INNER JOIN	[Notification].[Publisher]	P	ON	S.[SubscriberPublisherId]	= P.[PublisherId]
			LEFT JOIN	@organisationIds			XO	ON	P.[PublisherOrganisationId]	= XO.[Id]
			WHERE XO.[Id] IS NOT NULL OR S.[SubscriberPersonId] = @personId;
		ELSE
			DELETE X FROM @subscriber				X
			INNER JOIN	[Notification].[Subscriber]	S	ON	X.[Id]						= S.[SubscriberId]
			INNER JOIN	[Notification].[Publisher]	P	ON	S.[SubscriberPublisherId]	= P.[PublisherId]
			LEFT JOIN	@organisationIds			XO	ON	P.[PublisherOrganisationId]	= XO.[Id]
			WHERE XO.[Id] IS NULL AND S.[SubscriberPersonId] <> @personId;
		SET @isFiltered = 1;
	END

--	Filter by subscriber notification type
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
					INSERT @subscriber SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
					WHERE [Common].[Flags.LineIsEqual](S.[SubscriberNotificationType], @flagsLine, @flagsIsExact) = 1;
				ELSE 
					INSERT @subscriber SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
					WHERE [Common].[Flags.LineIsEqual](S.[SubscriberNotificationType], @flagsLine, @flagsIsExact) = 0;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @subscriber	X
					LEFT JOIN
					(
						SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
						WHERE [Common].[Flags.LineIsEqual](S.[SubscriberNotificationType], @flagsLine, @flagsIsExact) = 1
					)	S	ON	X.[Id]	= S.[SubscriberId]
					WHERE S.[SubscriberId] IS NULL;
				ELSE
					DELETE X FROM @subscriber	X
					LEFT JOIN
					(
						SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
						WHERE [Common].[Flags.LineIsEqual](S.[SubscriberNotificationType], @flagsLine, @flagsIsExact) = 0
					)	S	ON	X.[Id]	= S.[SubscriberId]
					WHERE S.[SubscriberId] IS NULL;
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
					INSERT @subscriber SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
					WHERE S.[SubscriberCreatedOn] BETWEEN ISNULL(@dateFrom, S.[SubscriberCreatedOn]) AND ISNULL(@dateTo, S.[SubscriberCreatedOn]);
				ELSE 
					INSERT @subscriber SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
					WHERE S.[SubscriberCreatedOn] NOT BETWEEN ISNULL(@dateFrom, S.[SubscriberCreatedOn]) AND ISNULL(@dateTo, S.[SubscriberCreatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @subscriber	X
					LEFT JOIN
					(
						SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
						WHERE S.[SubscriberCreatedOn] BETWEEN ISNULL(@dateFrom, S.[SubscriberCreatedOn]) AND ISNULL(@dateTo, S.[SubscriberCreatedOn])
					)	S	ON	X.[Id]	= S.[SubscriberId]
					WHERE S.[SubscriberId] IS NULL;
				ELSE
					DELETE X FROM @subscriber	X
					LEFT JOIN
					(
						SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
						WHERE S.[SubscriberCreatedOn] NOT BETWEEN ISNULL(@dateFrom, S.[SubscriberCreatedOn]) AND ISNULL(@dateTo, S.[SubscriberCreatedOn])
					)	S	ON	X.[Id]	= S.[SubscriberId]
					WHERE S.[SubscriberId] IS NULL;
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
					INSERT @subscriber SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
					WHERE S.[SubscriberLockedOn] BETWEEN ISNULL(@dateFrom, S.[SubscriberLockedOn]) AND ISNULL(@dateTo, S.[SubscriberLockedOn]);
				ELSE 
					INSERT @subscriber SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
					WHERE S.[SubscriberLockedOn] NOT BETWEEN ISNULL(@dateFrom, S.[SubscriberLockedOn]) AND ISNULL(@dateTo, S.[SubscriberLockedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @subscriber	X
					LEFT JOIN
					(
						SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
						WHERE S.[SubscriberLockedOn] BETWEEN ISNULL(@dateFrom, S.[SubscriberLockedOn]) AND ISNULL(@dateTo, S.[SubscriberLockedOn])
					)	S	ON	X.[Id]	= S.[SubscriberId]
					WHERE S.[SubscriberId] IS NULL;
				ELSE
					DELETE X FROM @subscriber	X
					LEFT JOIN
					(
						SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
						WHERE S.[SubscriberLockedOn] NOT BETWEEN ISNULL(@dateFrom, S.[SubscriberLockedOn]) AND ISNULL(@dateTo, S.[SubscriberLockedOn])
					)	S	ON	X.[Id]	= S.[SubscriberId]
					WHERE S.[SubscriberId] IS NULL;
		ELSE IF (@criteriaIsNull = 1)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @subscriber SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
					WHERE S.[SubscriberLockedOn] IS NULL;
				ELSE 
					INSERT @subscriber SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
					WHERE S.[SubscriberLockedOn] IS NOT NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @subscriber	X
					LEFT JOIN
					(
						SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
						WHERE S.[SubscriberLockedOn] IS NULL
					)	S	ON	X.[Id]	= S.[SubscriberId]
					WHERE S.[SubscriberId] IS NULL;
				ELSE
					DELETE X FROM @subscriber	X
					LEFT JOIN
					(
						SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
						WHERE S.[SubscriberLockedOn] IS NOT NULL
					)	S	ON	X.[Id]	= S.[SubscriberId]
					WHERE S.[SubscriberId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @subscriber SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
			INNER JOIN	[Owner].[Person]	P	ON	S.[SubscriberPersonId]	= P.[PersonId]
			WHERE P.[PersonEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @subscriber	X
			LEFT JOIN	(
				SELECT S.[SubscriberId] FROM [Notification].[Subscriber] S
				INNER JOIN	[Owner].[Person]	P	ON	S.[SubscriberPersonId]	= P.[PersonId]
				WHERE P.[PersonEmplacementId] = @emplacementId
			)	S	ON	X.[Id]	= S.[SubscriberId]
			WHERE S.[SubscriberId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @subscriber X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Notification].[Subscriber] S;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @subscriber X;
		ELSE
			IF (@organisations IS NULL)
				SELECT @number = COUNT(*) FROM [Notification].[Subscriber] S
				INNER JOIN	[Notification].[Publisher]	P	ON	S.[SubscriberPublisherId]	= P.[PublisherId]
				INNER JOIN	[Owner].[Organisation]		O	ON	P.[PublisherOrganisationId]	= O.[OrganisationId]
				LEFT JOIN	@subscriber					X	ON	S.[SubscriberId]			= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId]	= ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE
				SELECT @number = COUNT(*) FROM [Notification].[Subscriber] S
				INNER JOIN	[Notification].[Publisher]	P	ON	S.[SubscriberPublisherId]	= P.[PublisherId]
				INNER JOIN	[Owner].[Organisation]		O	ON	P.[PublisherOrganisationId]	= O.[OrganisationId]
				LEFT JOIN	@organisationIds			XO	ON	O.[OrganisationId]			= XO.[Id]
				LEFT JOIN	@subscriber					X	ON	S.[SubscriberId]			= X.[Id]
				WHERE 
					(XO.[Id] IS NOT NULL OR S.[SubscriberPersonId] = @personId)								AND
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;

END
GO
