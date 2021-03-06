SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Security'	AND
			O.[type]	= 'P'			AND
			O.[name]	= 'Application.Action'))
	DROP PROCEDURE [Security].[Application.Action];
GO

CREATE PROCEDURE [Security].[Application.Action]
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
		@emplacementId	UNIQUEIDENTIFIER,
		@applicationId	UNIQUEIDENTIFIER,
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
		@emplacementId	= @emplacementId	OUTPUT,
		@applicationId	= @applicationId	OUTPUT,
		@organisations	= @organisations	OUTPUT;
	
	IF (@permissionType = 'ApplicationCreate') BEGIN
		INSERT [Security].[Application] 
		(
			[ApplicationCode],
			[ApplicationDescription],
			[ApplicationIsAdministrative]
		)
		OUTPUT INSERTED.[ApplicationId] INTO @output ([Id])
		SELECT
			X.[Code],
			X.[Description],
			X.[IsAdministrative]
		FROM [Security].[Application.Entity](@entity) X;
		SELECT A.* FROM [Security].[Application]	A
		INNER JOIN	@output							X	ON	A.[ApplicationId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'ApplicationRead') BEGIN
		SELECT A.* FROM [Security].[Application]				A
		INNER JOIN	[Security].[Application.Entity](@entity)	X	ON	A.[ApplicationId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'ApplicationUpdate') BEGIN
		UPDATE A SET 
			A.[ApplicationCode]				= X.[Code],
			A.[ApplicationDescription]		= X.[Description],
			A.[ApplicationIsAdministrative]	= X.[IsAdministrative]
		OUTPUT INSERTED.[ApplicationId] INTO @output ([Id])
		FROM [Security].[Application]							A
		INNER JOIN	[Security].[Application.Entity](@entity)	X	ON	A.[ApplicationId]		= X.[Id]	AND
																		A.[ApplicationVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT A.* FROM [Security].[Application]				A
		INNER JOIN	@output										X	ON	A.[ApplicationId]		= X.[Id];
	END

	IF (@permissionType = 'ApplicationDelete') BEGIN
		DELETE A FROM [Security].[Application]					A
		INNER JOIN	[Security].[Application.Entity](@entity)	X	ON	A.[ApplicationId]		= X.[Id]	AND
																		A.[ApplicationVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
	END
	
	IF (@permissionType = 'ApplicationSearch') BEGIN
		CREATE TABLE [#application] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Security].[Application.Filter]
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
		INSERT [#application] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [ApplicationCode] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT A.* FROM [Security].[Application]		A
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT A.* FROM [#application]				X
				INNER JOIN	[Security].[Application]		A	ON	X.[Id]				= A.[ApplicationId]
				';
			ELSE
				SET @command = '
				SELECT A.* FROM [Security].[Application]	A
				LEFT JOIN	[#application]					X	ON	A.[ApplicationId]	= X.[Id]
				WHERE 
					' + ISNULL('A.[ApplicationId] = ''' + CAST(@applicationId AS NVARCHAR(MAX)) + ''' AND', '') + '
					X.[Id] IS NULL
				';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
