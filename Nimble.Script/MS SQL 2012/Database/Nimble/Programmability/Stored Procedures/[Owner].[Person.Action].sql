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
			O.[name]	= 'Person.Action'))
	DROP PROCEDURE [Owner].[Person.Action];
GO

CREATE PROCEDURE [Owner].[Person.Action]
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
		@emplacementId	= @emplacementId	OUTPUT,
		@applicationId	= @applicationId	OUTPUT,
		@personId		= @personId			OUTPUT,
		@organisations	= @organisations	OUTPUT;
	
	IF (@permissionType = 'PersonCreate') BEGIN
		INSERT [Owner].[Person] 
		(
			[PersonEmplacementId],
			[PersonUserId],
			[PersonCode],
			[PersonIDNP],
			[PersonFirstName],
			[PersonLastName],
			[PersonPatronymic],
			[PersonBornOn],
			[PersonSexType],
			[PersonEmail],
			[PersonLockedOn],
			[PersonSettings]
		)
		OUTPUT INSERTED.[PersonId] INTO @output ([Id])
		SELECT
			X.[EmplacementId],
			X.[UserId],
			X.[Code],
			X.[IDNP],
			X.[FirstName],
			X.[LastName],
			X.[Patronymic],
			X.[BornOn],
			X.[PersonSexType],
			X.[Email],
			X.[LockedOn],
			X.[Settings]
		FROM [Owner].[Person.Entity](@entity) X;
		SELECT P.* FROM [Owner].[Entity.Person]	P
		INNER JOIN	@output						X	ON	P.[PersonId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'PersonRead') BEGIN
		SELECT P.* FROM [Owner].[Entity.Person]			P
		INNER JOIN	[Owner].[Person.Entity](@entity)	X	ON	P.[PersonId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'PersonUpdate') BEGIN
		UPDATE P SET 
			P.[PersonUserId]		= X.[UserId],
			P.[PersonCode]			= X.[Code],
			P.[PersonIDNP]			= X.[IDNP],
			P.[PersonFirstName]		= X.[FirstName],
			P.[PersonLastName]		= X.[LastName],
			P.[PersonPatronymic]	= X.[Patronymic],
			P.[PersonBornOn]		= X.[BornOn],
			P.[PersonSexType]		= X.[PersonSexType],
			P.[PersonEmail]			= X.[Email],
			P.[PersonLockedOn]		= X.[LockedOn],
			P.[PersonSettings]		= X.[Settings]
		OUTPUT INSERTED.[PersonId] INTO @output ([Id])
		FROM [Owner].[Person]							P
		INNER JOIN	[Owner].[Person.Entity](@entity)	X	ON	P.[PersonId]		= X.[Id]	AND
																P.[PersonVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT P.* FROM [Owner].[Entity.Person]	P
		INNER JOIN	@output						X	ON	P.[PersonId]	= X.[Id];
	END

	IF (@permissionType = 'PersonDelete') BEGIN
		DELETE P FROM [Owner].[Person]					P
		INNER JOIN	[Owner].[Person.Entity](@entity)	X	ON	P.[PersonId]		= X.[Id]	AND
																P.[PersonVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
	END
	
	IF (@permissionType = 'PersonSearch') BEGIN
		CREATE TABLE [#person] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
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
		INSERT [#person] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [PersonEmplacementId] ASC, [PersonCode] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT P.* FROM [Owner].[Entity.Person]		P
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT P.* FROM [#person]				X
				INNER JOIN	[Owner].[Entity.Person]		P	ON	X.[Id]			= P.[PersonId]
				';
			ELSE
				SET @command = '
				SELECT P.* FROM [Owner].[Entity.Person]	P
				LEFT JOIN	[#person]					X	ON	P.[PersonId]	= X.[Id]
				WHERE 
					' + ISNULL('P.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
					' + ISNULL('P.[PersonId] = ''' + CAST(@personId AS NVARCHAR(MAX)) + ''' AND', '') + '
					X.[Id] IS NULL
				';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
