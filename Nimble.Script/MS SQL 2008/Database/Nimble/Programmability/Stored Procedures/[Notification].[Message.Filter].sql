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
			O.[name]	= 'Message.Filter'))
	DROP PROCEDURE [Notification].[Message.Filter];
GO

CREATE PROCEDURE [Notification].[Message.Filter]
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
	
	DECLARE @message TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	
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
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Messages')) X;
	IF (@criteriaValueExist = 1) BEGIN
		SET @criteriaValue = @criteriaValue.query('/*/Message');
		DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
		INSERT @entities SELECT * FROM 
		(
			SELECT DISTINCT E.[Id]
			FROM [Common].[Generic.Entities](@criteriaValue) X
			CROSS APPLY [Notification].[Message.Entity](X.[Entity]) E
		) E
		WHERE E.[Id] IS NOT NULL;
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @message SELECT * FROM @entities;
				ELSE
					INSERT @message SELECT M.[MessageId] FROM [Notification].[Message] M
					WHERE M.[MessageId] NOT IN (SELECT * FROM @entities);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @message X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
				ELSE
					DELETE X FROM @message X WHERE X.[Id] IN (SELECT * FROM @entities);
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
	IF (@criteriaExist = 1) BEGIN	
		DECLARE @entityIds TABLE ([EntityId] UNIQUEIDENTIFIER);
		INSERT @entityIds SELECT DISTINCT * FROM [Common].[Guid.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @message SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
					INNER JOIN	@entityIds	X	ON	M.[MessageEntityId]	= X.[EntityId];
				ELSE 
					INSERT @message SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
					LEFT JOIN	@entityIds	X	ON	M.[MessageEntityId]	= X.[EntityId]
					WHERE X.[EntityId] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
						INNER JOIN	@entityIds	X	ON	M.[MessageEntityId]	= X.[EntityId]
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
				ELSE
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
						LEFT JOIN	@entityIds	X	ON	M.[MessageEntityId]	= X.[EntityId]
						WHERE X.[EntityId] IS NULL
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
		ELSE IF (@criteriaIsNull = 1)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @message SELECT M.[MessageId] FROM [Notification].[Message] M
					WHERE M.[MessageEntityId] IS NULL;
				ELSE 
					INSERT @message SELECT M.[MessageId] FROM [Notification].[Message] M
					WHERE M.[MessageEntityId] IS NOT NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT M.[MessageId] FROM [Notification].[Message] M
						WHERE M.[MessageEntityId] IS NULL
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
				ELSE
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT M.[MessageId] FROM [Notification].[Message] M
						WHERE M.[MessageEntityId] IS NOT NULL
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by message action types
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/MessageActionTypes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @messageActionTypes TABLE ([MessageActionType] NVARCHAR(MAX));
		INSERT @messageActionTypes SELECT DISTINCT * FROM [Common].[Enum.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @message SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
					INNER JOIN	@messageActionTypes		X	ON	M.[MessageActionType]	LIKE X.[MessageActionType];
				ELSE 
					INSERT @message SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
					LEFT JOIN	@messageActionTypes		X	ON	M.[MessageActionType]	LIKE X.[MessageActionType]
					WHERE X.[MessageActionType] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
						INNER JOIN	@messageActionTypes		X	ON	M.[MessageActionType]	LIKE X.[MessageActionType]
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
				ELSE
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
						LEFT JOIN	@messageActionTypes		X	ON	M.[MessageActionType]	LIKE X.[MessageActionType]
						WHERE X.[MessageActionType] IS NULL
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
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
					INSERT @message SELECT M.[MessageId] FROM [Notification].[Message] M
					INNER JOIN	@publisher	X	ON	M.[MessagePublisherId]	= X.[Id];
				ELSE
					INSERT @message SELECT M.[MessageId] FROM [Notification].[Message] M
					LEFT JOIN	@publisher	X	ON	M.[MessagePublisherId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT M.[MessageId] FROM [Notification].[Message] M
						INNER JOIN	@publisher	X	ON	M.[MessagePublisherId]	= X.[Id]
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
				ELSE
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT M.[MessageId] FROM [Notification].[Message] M
						LEFT JOIN	@publisher	X	ON	M.[MessagePublisherId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by organisations
	DECLARE @organisationIds TABLE ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	IF (@organisations IS NOT NULL) BEGIN
		INSERT @organisationIds SELECT * FROM [Common].[Guid.Entities](@organisations);
		IF (@isFiltered = 0)
			INSERT @message SELECT M.[MessageId] FROM [Notification].[Message]	M
			INNER JOIN	[Notification].[Publisher]	P	ON	M.[MessagePublisherId]		= P.[PublisherId]
			INNER JOIN	@organisationIds			XO	ON	P.[PublisherOrganisationId]	= XO.[Id];
		ELSE
			DELETE X FROM @message					X
			INNER JOIN	[Notification].[Message]	M	ON	X.[Id]						= M.[MessageId]
			INNER JOIN	[Notification].[Publisher]	P	ON	M.[MessagePublisherId]		= P.[PublisherId]
			LEFT JOIN	@organisationIds			XO	ON	P.[PublisherOrganisationId]	= XO.[Id]
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
					INSERT @message SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
					INNER JOIN	@codes	X	ON	M.[MessageCode]	LIKE X.[Code];
				ELSE 
					INSERT @message SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
					LEFT JOIN	@codes	X	ON	M.[MessageCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
						INNER JOIN	@codes	X	ON	M.[MessageCode]	LIKE X.[Code]
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
				ELSE
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
						LEFT JOIN	@codes	X	ON	M.[MessageCode]	LIKE X.[Code]
						WHERE X.[Code] IS NULL
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by message notification type
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
					INSERT @message SELECT M.[MessageId] FROM [Notification].[Message] M
					WHERE [Common].[Flags.LineIsEqual](M.[MessageNotificationType], @flagsLine, @flagsIsExact) = 1;
				ELSE 
					INSERT @message SELECT M.[MessageId] FROM [Notification].[Message] M
					WHERE [Common].[Flags.LineIsEqual](M.[MessageNotificationType], @flagsLine, @flagsIsExact) = 0;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT M.[MessageId] FROM [Notification].[Message] M
						WHERE [Common].[Flags.LineIsEqual](M.[MessageNotificationType], @flagsLine, @flagsIsExact) = 1
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
				ELSE
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT M.[MessageId] FROM [Notification].[Message] M
						WHERE [Common].[Flags.LineIsEqual](M.[MessageNotificationType], @flagsLine, @flagsIsExact) = 0
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
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
					INSERT @message SELECT M.[MessageId] FROM [Notification].[Message] M
					WHERE M.[MessageCreatedOn] BETWEEN ISNULL(@dateFrom, M.[MessageCreatedOn]) AND ISNULL(@dateTo, M.[MessageCreatedOn]);
				ELSE 
					INSERT @message SELECT M.[MessageId] FROM [Notification].[Message] M
					WHERE M.[MessageCreatedOn] NOT BETWEEN ISNULL(@dateFrom, M.[MessageCreatedOn]) AND ISNULL(@dateTo, M.[MessageCreatedOn]);
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT M.[MessageId] FROM [Notification].[Message] M
						WHERE M.[MessageCreatedOn] BETWEEN ISNULL(@dateFrom, M.[MessageCreatedOn]) AND ISNULL(@dateTo, M.[MessageCreatedOn])
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
				ELSE
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT M.[MessageId] FROM [Notification].[Message] M
						WHERE M.[MessageCreatedOn] NOT BETWEEN ISNULL(@dateFrom, M.[MessageCreatedOn]) AND ISNULL(@dateTo, M.[MessageCreatedOn])
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by titles
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Titles')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @titles TABLE ([Title] NVARCHAR(MAX));
		INSERT @titles SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @message SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
					INNER JOIN	@titles	X	ON	M.[MessageTitle]	LIKE X.[Title];
				ELSE 
					INSERT @message SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
					LEFT JOIN	@titles	X	ON	M.[MessageTitle]	LIKE X.[Title]
					WHERE X.[Title] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
						INNER JOIN	@titles	X	ON	M.[MessageTitle]	LIKE X.[Title]
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
				ELSE
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
						LEFT JOIN	@titles	X	ON	M.[MessageTitle]	LIKE X.[Title]
						WHERE X.[Title] IS NULL
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by bodies
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Bodies')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @bodies TABLE ([Body] NVARCHAR(MAX));
		INSERT @bodies SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @message SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
					INNER JOIN	@bodies	X	ON	M.[MessageBody]	LIKE X.[Body];
				ELSE 
					INSERT @message SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
					LEFT JOIN	@bodies	X	ON	M.[MessageBody]	LIKE X.[Body]
					WHERE X.[Body] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
						INNER JOIN	@bodies	X	ON	M.[MessageBody]	LIKE X.[Body]
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
				ELSE
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
						LEFT JOIN	@bodies	X	ON	M.[MessageBody]	LIKE X.[Body]
						WHERE X.[Body] IS NULL
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by sounds
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Sounds')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @sounds TABLE ([Sound] NVARCHAR(MAX));
		INSERT @sounds SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @message SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
					INNER JOIN	@sounds	X	ON	M.[MessageSound]	LIKE X.[Sound];
				ELSE 
					INSERT @message SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
					LEFT JOIN	@sounds	X	ON	M.[MessageSound]	LIKE X.[Sound]
					WHERE X.[Sound] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
						INNER JOIN	@sounds	X	ON	M.[MessageSound]	LIKE X.[Sound]
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
				ELSE
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
						LEFT JOIN	@sounds	X	ON	M.[MessageSound]	LIKE X.[Sound]
						WHERE X.[Sound] IS NULL
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by icons
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/Icons')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @icons TABLE ([Icon] NVARCHAR(MAX));
		INSERT @icons SELECT DISTINCT * FROM [Common].[String.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @message SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
					INNER JOIN	@icons	X	ON	M.[MessageIcon]	LIKE X.[Icon];
				ELSE 
					INSERT @message SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
					LEFT JOIN	@icons	X	ON	M.[MessageIcon]	LIKE X.[Icon]
					WHERE X.[Icon] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
						INNER JOIN	@icons	X	ON	M.[MessageIcon]	LIKE X.[Icon]
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
				ELSE
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
						LEFT JOIN	@icons	X	ON	M.[MessageIcon]	LIKE X.[Icon]
						WHERE X.[Icon] IS NULL
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by message entity types
	SELECT 
		@criteria			= X.[Criteria],
		@criteriaExist		= X.[CriteriaExist],
		@isExcluded			= X.[CriteriaIsExcluded],
		@criteriaIsNull		= X.[CriteriaIsNull],
		@criteriaValue		= X.[CriteriaValue],
		@criteriaValueExist	= X.[CriteriaValueExist]
	FROM [Common].[Criteria.Entity](@predicate.query('/*/MessageEntityTypes')) X;
	IF (@criteriaValueExist = 1) BEGIN
		DECLARE @messageEntityTypes TABLE ([MessageEntityType] NVARCHAR(MAX));
		INSERT @messageEntityTypes SELECT DISTINCT * FROM [Common].[Enum.Entities](@criteriaValue);
		IF (@@ROWCOUNT > 0)
			IF (@isFiltered = 0)
				IF (@isExcluded = 0)
					INSERT @message SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
					INNER JOIN	@messageEntityTypes		X	ON	M.[MessageEntityType]	LIKE X.[MessageEntityType];
				ELSE 
					INSERT @message SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
					LEFT JOIN	@messageEntityTypes		X	ON	M.[MessageEntityType]	LIKE X.[MessageEntityType]
					WHERE X.[MessageEntityType] IS NULL;
			ELSE
				IF (@isExcluded = 0)
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
						INNER JOIN	@messageEntityTypes		X	ON	M.[MessageEntityType]	LIKE X.[MessageEntityType]
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
				ELSE
					DELETE X FROM @message	X
					LEFT JOIN
					(
						SELECT DISTINCT M.[MessageId] FROM [Notification].[Message] M
						LEFT JOIN	@messageEntityTypes		X	ON	M.[MessageEntityType]	LIKE X.[MessageEntityType]
						WHERE X.[MessageEntityType] IS NULL
					)	M	ON	X.[Id]	= M.[MessageId]
					WHERE M.[MessageId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT @message SELECT M.[MessageId] FROM [Notification].[Message]	M
			INNER JOIN	[Notification].[Publisher]	P	ON	M.[MessagePublisherId]		= P.[PublisherId]
			INNER JOIN	[Owner].[Organisation]		O	ON	P.[PublisherOrganisationId] = O.[OrganisationId]
			WHERE O.[OrganisationEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM @message	X
			LEFT JOIN	(
				SELECT M.[MessageId] FROM [Notification].[Message]	M
				INNER JOIN	[Notification].[Publisher]	P	ON	M.[MessagePublisherId]		= P.[PublisherId]
				INNER JOIN	[Owner].[Organisation]		O	ON	P.[PublisherOrganisationId] = O.[OrganisationId]
				WHERE O.[OrganisationEmplacementId] = @emplacementId
			)	M	ON	X.[Id]	= M.[MessageId]
			WHERE M.[MessageId] IS NULL;
		SET @isFiltered = 1;
	END

	SELECT @isExcluded = X.[CriteriaIsExcluded] FROM [Common].[Criteria.Entity](@predicate) X;

	SET @guids = (SELECT X.[Id] [guid] FROM @message X FOR XML PATH(''), ROOT('Guids'));

	IF (@isCountable = 0) RETURN;

--	Apply filters
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Notification].[Message] M;
	ELSE
		IF (@isExcluded = 0)
			SELECT @number = COUNT(*) FROM @message X;
		ELSE
			IF (@organisations IS NULL)      
				SELECT @number = COUNT(*) FROM [Notification].[Message]	M
				INNER JOIN	[Notification].[Publisher]	P	ON	M.[MessagePublisherId]		= P.[PublisherId]
				INNER JOIN	[Owner].[Organisation]		O	ON	P.[PublisherOrganisationId]	= O.[OrganisationId]
				LEFT JOIN	@message					X	ON	M.[MessageId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId]	= ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;
			ELSE
				SELECT @number = COUNT(*) FROM [Notification].[Message]	M
				INNER JOIN	[Notification].[Publisher]	P	ON	M.[MessagePublisherId]		= P.[PublisherId]
				INNER JOIN	[Owner].[Organisation]		O	ON	P.[PublisherOrganisationId]	= O.[OrganisationId]
				INNER JOIN	@organisationIds			XO	ON	O.[OrganisationId]			= XO.[Id]
				LEFT JOIN	@message					X	ON	M.[MessageId]				= X.[Id]
				WHERE 
					O.[OrganisationEmplacementId]	= ISNULL(@emplacementId, O.[OrganisationEmplacementId])	AND
					X.[Id] IS NULL;

END
GO
