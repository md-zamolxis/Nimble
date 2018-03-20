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
			O.[name]	= 'Trace.Filter'))
	DROP PROCEDURE [Notification].[Trace.Filter];
GO

CREATE PROCEDURE [Notification].[Trace.Filter]
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

	DECLARE @trace TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
	DECLARE 
		@criteria			XML,
		@criteriaExist		BIT,
		@criteriaIsNull		BIT,
		@criteriaValue		XML,
		@criteriaValueExist	BIT,
		@amountFrom			DECIMAL(28, 9),
		@amountTo			DECIMAL(28, 9),
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Traces')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Trace');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Notification].[Trace.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @trace SELECT * FROM @entities;
				ELSE
					INSERT @trace SELECT T.[TraceId] FROM [Notification].[Trace] T
					WHERE T.[TraceId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @trace X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @trace X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

--	Filter by read datetime offset
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/ReadOn')) X;
	IF (@criteriaExist = 1) BEGIN
		SELECT @dateFrom = NULL, @dateTo = NULL;
		SELECT 
			@dateFrom	= X.[DateFrom], 
			@dateTo		= X.[DateTo] 
		FROM [Common].[DateInterval.Entity](@criteriaValue) X;
		IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @trace SELECT P.[TraceId] FROM [Notification].[Trace] P
					WHERE P.[TraceReadOn] BETWEEN ISNULL(@dateFrom, P.[TraceReadOn]) AND ISNULL(@dateTo, P.[TraceReadOn]);
				ELSE 
					INSERT @trace SELECT P.[TraceId] FROM [Notification].[Trace] P
					WHERE P.[TraceReadOn] NOT BETWEEN ISNULL(@dateFrom, P.[TraceReadOn]) AND ISNULL(@dateTo, P.[TraceReadOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @trace	X
					LEFT JOIN
					(
						SELECT P.[TraceId] FROM [Notification].[Trace] P
						WHERE P.[TraceReadOn] BETWEEN ISNULL(@dateFrom, P.[TraceReadOn]) AND ISNULL(@dateTo, P.[TraceReadOn])
					)	P	ON	X.[Id]	= P.[TraceId]
					WHERE P.[TraceId] IS NULL;
				ELSE
					DELETE X FROM @trace	X
					LEFT JOIN
					(
						SELECT P.[TraceId] FROM [Notification].[Trace] P
						WHERE P.[TraceReadOn] NOT BETWEEN ISNULL(@dateFrom, P.[TraceReadOn]) AND ISNULL(@dateTo, P.[TraceReadOn])
					)	P	ON	X.[Id]	= P.[TraceId]
					WHERE P.[TraceId] IS NULL;
		ELSE IF (@criteriaIsNull = 1)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @trace SELECT P.[TraceId] FROM [Notification].[Trace] P
					WHERE P.[TraceReadOn] IS NULL;
				ELSE 
					INSERT @trace SELECT P.[TraceId] FROM [Notification].[Trace] P
					WHERE P.[TraceReadOn] IS NOT NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @trace	X
					LEFT JOIN
					(
						SELECT P.[TraceId] FROM [Notification].[Trace] P
						WHERE P.[TraceReadOn] IS NULL
					)	P	ON	X.[Id]	= P.[TraceId]
					WHERE P.[TraceId] IS NULL;
				ELSE
					DELETE X FROM @trace	X
					LEFT JOIN
					(
						SELECT P.[TraceId] FROM [Notification].[Trace] P
						WHERE P.[TraceReadOn] IS NOT NULL
					)	P	ON	X.[Id]	= P.[TraceId]
					WHERE P.[TraceId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by message predicate
	DECLARE 
		@messagePredicate	XML,
		@messageIsCountable	BIT,
		@messageGuids		XML,
		@messageIsFiltered	BIT,
		@messageNumber		INT;
	SELECT 
		@messagePredicate	= X.[Criteria],
		@messageIsCountable	= 0,
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/MessagePredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @message TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Notification].[Message.Filter]
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
			@predicate		= @messagePredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@organisations	= NULL,
			@isCountable	= @messageIsCountable,
			@guids			= @messageGuids			OUTPUT,
			@isExcluded		= @isExcluded			OUTPUT,
			@isFiltered		= @messageIsFiltered	OUTPUT,
			@number			= @messageNumber		OUTPUT;
		INSERT @message SELECT * FROM [Common].[Guid.Entities](@messageGuids);
		IF (@messageIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @trace SELECT T.[TraceId] FROM [Notification].[Trace] T
					INNER JOIN	@message	X	ON	T.[TraceMessageId]	= X.[Id];
				ELSE
					INSERT @trace SELECT T.[TraceId] FROM [Notification].[Trace] T
					LEFT JOIN	@message	X	ON	T.[TraceMessageId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @trace	X
					LEFT JOIN
					(
						SELECT T.[TraceId] FROM [Notification].[Trace] T
						INNER JOIN	@message	X	ON	T.[TraceMessageId]	= X.[Id]
					)	T	ON	X.[Id]	= T.[TraceId]
					WHERE T.[TraceId] IS NULL;
				ELSE
					DELETE X FROM @trace	X
					LEFT JOIN
					(
						SELECT T.[TraceId] FROM [Notification].[Trace] T
						LEFT JOIN	@message	X	ON	T.[TraceMessageId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	T	ON	X.[Id]	= T.[TraceId]
					WHERE T.[TraceId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by subscriber predicate
	DECLARE 
		@subscriberPredicate	XML,
		@subscriberIsCountable	BIT,
		@subscriberGuids		XML,
		@subscriberIsFiltered	BIT,
		@subscriberNumber		INT;
	SELECT 
		@subscriberPredicate	= X.[Criteria],
		@subscriberIsCountable	= 0,
		@criteriaExist			= X.[CriteriaExist],
		@isExcluded				= X.[CriteriaIsExcluded],
		@criteriaIsNull			= X.[CriteriaIsNull],
		@criteriaValue			= X.[CriteriaValue],
		@criteriaValueExist		= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/SubscriberPredicate')) X;
	IF (@criteriaExist = 1) BEGIN
		DECLARE @subscriber TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Notification].[Subscriber.Filter]
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
			@predicate		= @subscriberPredicate,
			@emplacementId	= NULL,
			@applicationId	= NULL,
			@personId		= NULL,
			@organisations	= NULL,
			@isCountable	= @subscriberIsCountable,
			@guids			= @subscriberGuids		OUTPUT,
			@isExcluded		= @isExcluded			OUTPUT,
			@isFiltered		= @subscriberIsFiltered	OUTPUT,
			@number			= @subscriberNumber		OUTPUT;
		INSERT @subscriber SELECT * FROM [Common].[Guid.Entities](@subscriberGuids);
		IF (@subscriberIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @trace SELECT T.[TraceId] FROM [Notification].[Trace] T
					INNER JOIN	@subscriber	X	ON	T.[TraceSubscriberId]	= X.[Id];
				ELSE
					INSERT @trace SELECT T.[TraceId] FROM [Notification].[Trace] T
					LEFT JOIN	@subscriber	X	ON	T.[TraceSubscriberId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @trace	X
					LEFT JOIN
					(
						SELECT T.[TraceId] FROM [Notification].[Trace] T
						INNER JOIN	@subscriber	X	ON	T.[TraceSubscriberId]	= X.[Id]
					)	T	ON	X.[Id]	= T.[TraceId]
					WHERE T.[TraceId] IS NULL;
				ELSE
					DELETE X FROM @trace	X
					LEFT JOIN
					(
						SELECT T.[TraceId] FROM [Notification].[Trace] T
						LEFT JOIN	@subscriber	X	ON	T.[TraceSubscriberId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	T	ON	X.[Id]	= T.[TraceId]
					WHERE T.[TraceId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@organisations IS NOT NULL) BEGIN
		INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
		IF (@isFiltered = 0)
			INSERT @trace SELECT T.[TraceId] FROM [Notification].[Trace] T
			INNER JOIN	[Notification].[Message]	M	ON	T.[TraceMessageId]			= M.[MessageId]
			INNER JOIN	[Notification].[Publisher]	P	ON	M.[MessagePublisherId]		= P.[PublisherId]
			INNER JOIN	[Notification].[Subscriber]	S	ON	T.[TraceSubscriberId]		= S.[SubscriberId]
			LEFT JOIN	@organisationIds			XO	ON	P.[PublisherOrganisationId]	= XO.[Id]
			WHERE XO.[Id] IS NOT NULL OR S.[SubscriberPersonId] = @personId;
		ELSE
			DELETE X FROM @trace					X 
			INNER JOIN	[Notification].[Trace]		T	ON	X.[Id]						= T.[TraceId]
			INNER JOIN	[Notification].[Message]	M	ON	T.[TraceMessageId]			= M.[MessageId]
			INNER JOIN	[Notification].[Publisher]	P	ON	M.[MessagePublisherId]		= P.[PublisherId]
			INNER JOIN	[Notification].[Subscriber]	S	ON	T.[TraceSubscriberId]		= S.[SubscriberId]
			LEFT JOIN	@organisationIds			XO	ON	P.[PublisherOrganisationId]	= XO.[Id]
			WHERE XO.[Id] IS NULL AND S.[SubscriberPersonId] <> @personId;
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
					INSERT @trace SELECT T.[TraceId] FROM [Notification].[Trace] T
					WHERE T.[TraceCreatedOn] BETWEEN ISNULL(@dateFrom, T.[TraceCreatedOn]) AND ISNULL(@dateTo, T.[TraceCreatedOn]);
				ELSE 
					INSERT @trace SELECT T.[TraceId] FROM [Notification].[Trace] T
					WHERE T.[TraceCreatedOn] NOT BETWEEN ISNULL(@dateFrom, T.[TraceCreatedOn]) AND ISNULL(@dateTo, T.[TraceCreatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @trace	X
					LEFT JOIN
					(
						SELECT T.[TraceId] FROM [Notification].[Trace] T
						WHERE T.[TraceCreatedOn] BETWEEN ISNULL(@dateFrom, T.[TraceCreatedOn]) AND ISNULL(@dateTo, T.[TraceCreatedOn])
					)	T	ON	X.[Id]	= T.[TraceId]
					WHERE T.[TraceId] IS NULL;
				ELSE
					DELETE X FROM @trace	X
					LEFT JOIN
					(
						SELECT T.[TraceId] FROM [Notification].[Trace] T
						WHERE T.[TraceCreatedOn] NOT BETWEEN ISNULL(@dateFrom, T.[TraceCreatedOn]) AND ISNULL(@dateTo, T.[TraceCreatedOn])
					)	T	ON	X.[Id]	= T.[TraceId]
					WHERE T.[TraceId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @trace SELECT T.[TraceId] FROM [Notification].[Trace] T
			INNER JOIN	[Notification].[Message]	M	ON	T.[TraceMessageId]			= M.[MessageId]
			INNER JOIN	[Notification].[Publisher]	P	ON	M.[MessagePublisherId]		= P.[PublisherId]
			INNER JOIN	[Owner].[Organisation]		O	ON	P.[PublisherOrganisationId]	= O.[OrganisationId]
			WHERE O.[OrganisationEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @trace	X
			LEFT JOIN	(
				SELECT T.[TraceId] FROM [Notification].[Trace]	T
				INNER JOIN	[Notification].[Message]	M	ON	T.[TraceMessageId]			= M.[MessageId]
				INNER JOIN	[Notification].[Publisher]	P	ON	M.[MessagePublisherId]		= P.[PublisherId]
				INNER JOIN	[Owner].[Organisation]		O	ON	P.[PublisherOrganisationId]	= O.[OrganisationId]
				WHERE O.[OrganisationEmplacementId] = @emplacementId
			)	T	ON	X.[Id]	= T.[TraceId]
			WHERE T.[TraceId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @trace X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Notification].[Trace] T;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @trace X;
		ELSE
			IF (@organisations IS NULL)
				SELECT @number = COUNT(*) FROM [Notification].[Trace]	T
				INNER JOIN	[Notification].[Message]	M	ON	T.[TraceMessageId]			= M.[MessageId]
				INNER JOIN	[Notification].[Publisher]	P	ON	M.[MessagePublisherId]		= P.[PublisherId]
				INNER JOIN	[Owner].[Organisation]		O	ON	P.[PublisherOrganisationId]	= O.[OrganisationId]
				LEFT JOIN	@trace						X	ON	T.[TraceId]					= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId]	= ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE
				SELECT @number = COUNT(*) FROM [Notification].[Trace]	T
				INNER JOIN	[Notification].[Message]	M	ON	T.[TraceMessageId]			= M.[MessageId]
				INNER JOIN	[Notification].[Publisher]	P	ON	M.[MessagePublisherId]		= P.[PublisherId]
				INNER JOIN	[Owner].[Organisation]		O	ON	P.[PublisherOrganisationId]	= O.[OrganisationId]
				INNER JOIN	[Notification].[Subscriber]	S	ON	T.[TraceSubscriberId]		= S.[SubscriberId]
				LEFT JOIN	@organisationIds			XO	ON	O.[OrganisationId]			= XO.[Id]
				LEFT JOIN	@trace						X	ON	T.[TraceId]					= X.[Id]
				WHERE 
					(XO.[Id] IS NOT NULL OR S.[SubscriberPersonId] = @personId)								AND
					O.[OrganisationEmplacementId] = ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;

END
GO
