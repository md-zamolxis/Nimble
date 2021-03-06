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
			O.[name]	= 'Mark.Action'))
	DROP PROCEDURE [Owner].[Mark.Action];
GO

CREATE PROCEDURE [Owner].[Mark.Action]
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
		@index			INT,
		@size			INT,
		@startNumber	INT,
		@endNumber		INT,
		@order			NVARCHAR(MAX),
		@groupTop		NVARCHAR(MAX),
		@groupBottom	NVARCHAR(MAX),
		@group			NVARCHAR(MAX),
		@emplacementId	UNIQUEIDENTIFIER,
		@applicationId	UNIQUEIDENTIFIER,
		@personId		UNIQUEIDENTIFIER,
		@organisations	XML,
		@isCountable	BIT,
		@guids			XML,
		@isExcluded		BIT,
		@isFiltered		BIT,
		@command		NVARCHAR(MAX);
	
	DECLARE @output TABLE ([Id] UNIQUEIDENTIFIER);
	
	EXEC [Common].[GenericInput.Action] 
		@genericInput	= @genericInput,
		@permissionType = @permissionType	OUTPUT,
		@entity			= @entity			OUTPUT,
		@predicate		= @predicate		OUTPUT,
		@index			= @index			OUTPUT,
		@size			= @size				OUTPUT,
		@startNumber	= @startNumber		OUTPUT,
		@endNumber		= @endNumber		OUTPUT,
		@order			= @order			OUTPUT,
		@groupTop		= @groupTop			OUTPUT,
		@groupBottom	= @groupBottom		OUTPUT,
		@emplacementId	= @emplacementId	OUTPUT,
		@applicationId	= @applicationId	OUTPUT,
		@personId		= @personId			OUTPUT,
		@organisations	= @organisations	OUTPUT;

	IF (@permissionType = 'MarkCreate') BEGIN
		INSERT [Owner].[Mark] 
		(
			[MarkPersonId],
			[MarkEntityType],
			[MarkEntityId],
			[MarkCreatedOn],
			[MarkActionType],
			[MarkComment],
			[MarkSettings]
		)
		OUTPUT INSERTED.[MarkId] INTO @output ([Id])
		SELECT
			X.[PersonId],
			X.[MarkEntityType],
			X.[EntityId],
			X.[CreatedOn],
			X.[MarkActionType],
			X.[Comment],
			X.[Settings]
		FROM [Owner].[Mark.Entity](@entity) X;
		SELECT M.* FROM [Owner].[Entity.Mark]		M
		INNER JOIN	@output							X	ON	M.[MarkId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'MarkRead') BEGIN
		SELECT M.* FROM [Owner].[Entity.Mark]		M
		INNER JOIN	[Owner].[Mark.Entity](@entity)	X	ON	M.[MarkId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'MarkUpdate') BEGIN
		UPDATE M SET 
			M.[MarkUpdatedOn]	= X.[UpdatedOn],
			M.[MarkActionType]	= X.[MarkActionType],
			M.[MarkComment]		= X.[Comment],
			M.[MarkSettings]	= X.[Settings]
		OUTPUT INSERTED.[MarkId] INTO @output ([Id])
		FROM [Owner].[Mark]							M
		INNER JOIN	[Owner].[Mark.Entity](@entity)	X	ON	M.[MarkId]	= X.[Id];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT M.* FROM [Owner].[Entity.Mark]		M
		INNER JOIN	@output							X	ON	M.[MarkId]	= X.[Id];
	END

	IF (@permissionType = 'MarkDelete') BEGIN
		DELETE	M	FROM [Owner].[Mark]				M
		INNER JOIN	[Owner].[Mark.Entity](@entity)	X	ON	M.[MarkId]	= X.[Id];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
	END

	IF ([Common].[Xml.IsEmpty](@predicate) <> 1) BEGIN
		CREATE TABLE [#mark] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner].[Mark.Filter]
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
			@predicate		= @predicate,
			@emplacementId	= @emplacementId,
			@applicationId	= @applicationId,
			@personId		= @personId,
			@organisations	= @organisations,
			@isCountable	= @isCountable,
			@guids			= @guids		OUTPUT,
			@isExcluded		= @isExcluded	OUTPUT,
			@isFiltered		= @isFiltered	OUTPUT,
			@number			= @number		OUTPUT;
		INSERT [#mark] SELECT * FROM [Common].[Guid.Entities](@guids);
	END
	
	IF (@permissionType = 'MarkSearch') BEGIN
		SET @order = ISNULL(@order, ' ORDER BY [MarkPersonId] ASC, [MarkCreatedOn] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT M.* FROM [Owner].[Entity.Mark]		M
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT M.* FROM [#mark]					X
				INNER JOIN	[Owner].[Entity.Mark]		M	ON	X.[Id]		= M.[MarkId]
				';
			ELSE
				SET @command = '
				SELECT M.* FROM [Owner].[Entity.Mark]	M	
				LEFT JOIN	[#mark]						X	ON	M.[MarkId]	= X.[Id]
				WHERE 
					' + ISNULL('M.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
					' + ISNULL('M.[PersonId] = ''' + CAST(@personId AS NVARCHAR(MAX)) + ''' AND', '') + '
					X.[Id] IS NULL
				';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END
  
	IF (@permissionType = 'MarkResumeSearch') BEGIN
		SET @order = ISNULL(@order, ' ORDER BY [CreatedOn] ASC ');
		SELECT @group = 'DATEPART(' + X.[Entity].value('(DatePart/text())[1]', 'NVARCHAR(MAX)') + ', [MarkCreatedOn])' FROM @predicate.nodes('/*') X ([Entity]);
		SET @command = 
		'
			SELECT * FROM
			(
				SELECT 
					*,
					ROW_NUMBER() OVER(' + @order + ') [Number]
				FROM 
				(
					SELECT
						' + ISNULL(@groupTop + ',', '') + '
						' + ISNULL(@group, 'NULL') + '		[CreatedOn],
						COUNT(*)							[MarkCount]
					FROM [#mark]				X
					INNER JOIN	[Owner].[Mark]	M	ON	X.[Id]	= M.[MarkId]
					GROUP BY 
						LEN(M.[MarkId])
						' + ISNULL(',' + @groupBottom, '') + '
						' + ISNULL(',' + @group, '') + '
				)										X
				LEFT JOIN	[Owner].[Person]			P	ON	X.[MarkPersonId]		= P.[PersonId]
				LEFT JOIN	[Security].[Emplacement]	E	ON	P.[PersonEmplacementId]	= E.[EmplacementId]
				LEFT JOIN	[Security].[User]			U	ON	P.[PersonUserId]		= U.[UserId]
			) M
		';
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
		SET @number = @@ROWCOUNT;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL) BEGIN
			SET @command = 
			'
				SELECT @number = COUNT(*) FROM
				(
					SELECT
						' + ISNULL(@groupTop + ',', '') + '
						' + ISNULL(@group, 'NULL') + '		[CreatedOn],
						COUNT(*)							[MarkCount]
					FROM [#mark]				X
					INNER JOIN	[Owner].[Mark]	M	ON	X.[Id]	= M.[MarkId]
					GROUP BY 
						LEN(M.[MarkId])
						' + ISNULL(',' + @groupBottom, '') + '
						' + ISNULL(',' + @group, '') + '
				) X
			';
			EXEC sp_executesql @command, N'@number INT OUTPUT', @number = @number OUTPUT;
		END
	END  

END
GO
