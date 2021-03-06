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
			O.[name]	= 'Emplacement.Action'))
	DROP PROCEDURE [Security].[Emplacement.Action];
GO

CREATE PROCEDURE [Security].[Emplacement.Action]
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
	
	IF (@permissionType = 'EmplacementCreate') BEGIN
		INSERT [Security].[Emplacement] 
		(
			[EmplacementCode],
			[EmplacementDescription],
			[EmplacementIsAdministrative]
		)
		OUTPUT INSERTED.[EmplacementId] INTO @output ([Id])
		SELECT
			X.[Code],
			X.[Description],
			X.[IsAdministrative]
		FROM [Security].[Emplacement.Entity](@entity) X;
		SELECT E.* FROM [Security].[Emplacement]	E
		INNER JOIN	@output							X	ON	E.[EmplacementId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'EmplacementRead') BEGIN
		SELECT E.* FROM [Security].[Emplacement]				E
		INNER JOIN	[Security].[Emplacement.Entity](@entity)	X	ON	E.[EmplacementId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'EmplacementUpdate') BEGIN
		UPDATE E SET 
			E.[EmplacementCode]				= X.[Code],
			E.[EmplacementDescription]		= X.[Description],
			E.[EmplacementIsAdministrative]	= X.[IsAdministrative]
		OUTPUT INSERTED.[EmplacementId] INTO @output ([Id])
		FROM [Security].[Emplacement]							E
		INNER JOIN	[Security].[Emplacement.Entity](@entity)	X	ON	E.[EmplacementId]		= X.[Id]	AND
																		E.[EmplacementVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT E.* FROM [Security].[Emplacement]	E
		INNER JOIN	@output							X	ON	E.[EmplacementId]	= X.[Id];
	END

	IF (@permissionType = 'EmplacementDelete') BEGIN
		DELETE E FROM [Security].[Emplacement]					E
		INNER JOIN	[Security].[Emplacement.Entity](@entity)	X	ON	E.[EmplacementId]		= X.[Id]	AND
																		E.[EmplacementVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
	END
	
	IF (@permissionType = 'EmplacementSearch') BEGIN
		CREATE TABLE [#emplacement] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Security].[Emplacement.Filter]
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
		INSERT [#emplacement] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [EmplacementCode] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT E.* FROM [Security].[Emplacement]		E
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT E.* FROM [#emplacement]				X
				INNER JOIN	[Security].[Emplacement]		E	ON	X.[Id]				= E.[EmplacementId]
				';
			ELSE
				SET @command = '
				SELECT E.* FROM [Security].[Emplacement]	E
				LEFT JOIN	[#emplacement]					X	ON	E.[EmplacementId]	= X.[Id]
				WHERE 
					' + ISNULL('E.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
					X.[Id] IS NULL
				';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
