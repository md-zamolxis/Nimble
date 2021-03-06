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
			O.[name]	= 'Organisation.Action'))
	DROP PROCEDURE [Owner].[Organisation.Action];
GO

CREATE PROCEDURE [Owner].[Organisation.Action]
(
	@genericInput	XML,
	@number			INT	OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE 
		@permissionType	NVARCHAR(MAX),
		@entity			XML,
		@predicate		XML,
		@startNumber	INT,
		@endNumber		INT,
		@order			NVARCHAR(MAX),
		@emplacementId	UNIQUEIDENTIFIER,
		@applicationId	UNIQUEIDENTIFIER,
		@organisations	XML,
		@isCountable	BIT,
		@guids			XML,
		@isExcluded		BIT,
		@isFiltered		BIT,
		@command		NVARCHAR(MAX);
	
	DECLARE @output TABLE ([Id] UNIQUEIDENTIFIER);
	
	CREATE TABLE [#organisations] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	EXEC [Common].[GenericInput.Action] 
		@genericInput	= @genericInput,
		@permissionType = @permissionType	OUTPUT,
		@entity			= @entity			OUTPUT,
		@predicate		= @predicate		OUTPUT,
		@startNumber	= @startNumber		OUTPUT,
		@endNumber		= @endNumber		OUTPUT,
		@order			= @order			OUTPUT,
		@emplacementId	= @emplacementId	OUTPUT,
		@applicationId	= @applicationId	OUTPUT,
		@organisations	= @organisations	OUTPUT;
	INSERT [#organisations] SELECT * FROM [Common].[Guid.Entities](@organisations);
	
	IF (@permissionType = 'OrganisationCreate') BEGIN
		INSERT [Owner].[Organisation] 
		(
			[OrganisationEmplacementId],
			[OrganisationCode],
			[OrganisationIDNO],
			[OrganisationName],
			[OrganisationCreatedOn],
			[OrganisationRegisteredOn],
			[OrganisationActionType],
			[OrganisationLockedOn],
			[OrganisationLockedReason],
			[OrganisationSettings]
		)
		OUTPUT INSERTED.[OrganisationId] INTO @output ([Id])
		SELECT
			X.[EmplacementId],
			X.[Code],
			X.[IDNO],
			X.[Name],
			X.[CreatedOn],
			X.[RegisteredOn],
			X.[OrganisationActionType],
			X.[LockedOn],
			X.[LockedReason],
			X.[Settings]
		FROM [Owner].[Organisation.Entity](@entity) X;
		SELECT O.* FROM [Owner].[Entity.Organisation]	O
		INNER JOIN	@output								X	ON	O.[OrganisationId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'OrganisationRead') BEGIN
		SELECT O.* FROM [Owner].[Entity.Organisation]		O
		INNER JOIN	[Owner].[Organisation.Entity](@entity)	X	ON	O.[OrganisationId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'OrganisationUpdate') BEGIN
		UPDATE O SET 
			O.[OrganisationCode]			= X.[Code],
			O.[OrganisationIDNO]			= X.[IDNO],
			O.[OrganisationName]			= X.[Name],
			O.[OrganisationActionType]		= X.[OrganisationActionType],
			O.[OrganisationLockedOn]		= X.[LockedOn],
			O.[OrganisationLockedReason]	= X.[LockedReason],
			O.[OrganisationSettings]		= X.[Settings]
		OUTPUT INSERTED.[OrganisationId] INTO @output ([Id])
		FROM [Owner].[Organisation]							O
		INNER JOIN	[Owner].[Organisation.Entity](@entity)	X	ON	O.[OrganisationId]		= X.[Id]	AND
																	O.[OrganisationVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT O.* FROM [Owner].[Entity.Organisation]	O
		INNER JOIN	@output								X	ON	O.[OrganisationId]	= X.[Id];
	END

	IF (@permissionType = 'OrganisationDelete') BEGIN
		DELETE O FROM [Owner].[Organisation]				O
		INNER JOIN	[Owner].[Organisation.Entity](@entity)	X	ON	O.[OrganisationId]		= X.[Id]	AND
																	O.[OrganisationVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
	END
	
	IF (@permissionType = 'OrganisationSearch') BEGIN
		CREATE TABLE [#organisation] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
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
			@predicate		= @predicate,
			@emplacementId	= @emplacementId,
			@applicationId	= @applicationId,
			@organisations	= @organisations,
			@isCountable	= @isCountable,
			@guids			= @guids		OUTPUT,
			@isExcluded		= @isExcluded	OUTPUT,
			@isFiltered		= @isFiltered	OUTPUT,
			@number			= @number		OUTPUT;
		INSERT [#organisation] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [OrganisationEmplacementId] ASC, [OrganisationCode] ASC ');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT O.* FROM [Owner].[Entity.Organisation]			O
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT O.* FROM [#organisation]						X
					INNER JOIN	[Owner].[Entity.Organisation]			O	ON	X.[Id]				= O.[OrganisationId]
					';
				ELSE
					IF (@organisations IS NULL)
						SET @command = '
						SELECT O.* FROM [Owner].[Entity.Organisation]	O
						LEFT JOIN	[#organisation]						X	ON	O.[OrganisationId]	= X.[Id]
						WHERE 
							' + ISNULL('O.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
							X.[Id] IS NULL
						';
					ELSE
						SET @command = '
						SELECT O.* FROM [Owner].[Entity.Organisation]	O
						INNER JOIN	[#organisations]					XO	ON	O.[OrganisationId]	= XO.[Id]
						LEFT JOIN	[#organisation]						X	ON	O.[OrganisationId]	= X.[Id]
						WHERE 
							' + ISNULL('O.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
							X.[Id] IS NULL
						';
			SET @command = @command + @order;
		END
		ELSE BEGIN
			IF (@isFiltered = 0)
				SET @command = '
				SELECT * FROM
				(
					SELECT 
						O.*, 
						ROW_NUMBER() OVER(' + @order + ') [Number]
					FROM [Owner].[Entity.Organisation]					O
				)	O
				WHERE O.[Number] BETWEEN
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							O.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [#organisation]							X
						INNER JOIN	[Owner].[Entity.Organisation]		O	ON	X.[Id]				= O.[OrganisationId]
					)	O
					WHERE O.[Number] BETWEEN
					';
				ELSE
					IF (@organisations IS NULL)
						SET @command = '
						SELECT * FROM
						(
							SELECT 
								O.*, 
								ROW_NUMBER() OVER(' + @order + ') [Number]
							FROM [Owner].[Entity.Organisation]			O
							LEFT JOIN	[#organisation]					X	ON	O.[OrganisationId]	= X.[Id]
							WHERE 
								' + ISNULL('O.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
								X.[Id] IS NULL
						)	O
						WHERE O.[Number] BETWEEN
						';
					ELSE
						SET @command = '
						SELECT * FROM
						(
							SELECT 
								O.*, 
								ROW_NUMBER() OVER(' + @order + ') [Number]
							FROM [Owner].[Entity.Organisation]			O
							INNER JOIN	[#organisations]				XO	ON	O.[OrganisationId]	= XO.[Id]
							LEFT JOIN	[#organisation]					X	ON	O.[OrganisationId]	= X.[Id]
							WHERE 
								' + ISNULL('O.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
								X.[Id] IS NULL
						)	O
						WHERE O.[Number] BETWEEN
						';
			SET @command = @command + CAST(@startNumber AS NVARCHAR(MAX)) + ' AND ' + CAST(@endNumber AS NVARCHAR(MAX));
		END
		EXEC sp_executesql @command;
	END

END
GO
