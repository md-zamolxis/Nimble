SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Post'	AND
			O.[type]	= 'P'			AND
			O.[name]	= 'Bond.Action'))
	DROP PROCEDURE [Owner.Post].[Bond.Action];
GO

CREATE PROCEDURE [Owner.Post].[Bond.Action]
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
	
	CREATE TABLE [#organisations] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
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
	INSERT [#organisations] SELECT * FROM [Common].[Guid.Entities](@organisations);
	
	DECLARE @postBonds XML = @predicate.query('/*/PostBonds/Value/PostBond');

	SELECT * INTO [#input] FROM [Owner.Post].[Bond.Entity](@entity) X;
	
	IF (@permissionType = 'PostBondRead') BEGIN
		SELECT B.* FROM [Owner.Post].[Entity.Bond]	B
		INNER JOIN	[#input]						X	ON	B.[PostId]	= X.[PostId]	AND
															B.[GroupId]	= X.[GroupId];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'PostBondSearch') BEGIN
		CREATE TABLE [#bond] 
		(
			[PostId]	UNIQUEIDENTIFIER,
			[GroupId]	UNIQUEIDENTIFIER,
			PRIMARY KEY CLUSTERED 
			(
				[PostId],
				[GroupId]
			)
		);
		EXEC sp_executesql 
			N'EXEC [Owner.Post].[Bond.Filter]
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
		INSERT [#bond]
		SELECT 
			LTRIM(X.[Entity].value('(PostId/text())[1]',	'UNIQUEIDENTIFIER')) [PostId],
			LTRIM(X.[Entity].value('(GroupId/text())[1]',	'UNIQUEIDENTIFIER')) [GroupId]
		FROM @guids.nodes('/*/guid') X ([Entity]);
		SET @order = ISNULL(@order, ' ORDER BY B.[PostId] ASC, B.[GroupId] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT B.* FROM [Owner.Post].[Entity.Bond]			B
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT B.* FROM [#bond]							X
				INNER JOIN	[Owner.Post].[Entity.Bond]			B	ON	X.[PostId]			= B.[PostId]	AND
																		X.[GroupId]			= B.[GroupId]
				';
			ELSE
				IF (@organisations IS NULL)
					SET @command = '
					SELECT B.* FROM [Owner.Post].[Entity.Bond]	B
					LEFT JOIN	[#bond]							X	ON	B.[PostId]			= X.[PostId]	AND
																		B.[GroupId]			= X.[GroupId]
					WHERE 
						' + ISNULL('B.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						(X.[PostId] IS NULL OR X.[GroupId] IS NULL)
					';
				ELSE
					SET @command = '
					SELECT B.* FROM [Owner.Post].[Entity.Bond]	B
					INNER JOIN	[#organisations]				XO	ON	B.[OrganisationId]	= XO.[Id]
					LEFT JOIN	[#bond]							X	ON	B.[PostId]			= X.[PostId]	AND
																		B.[GroupId]			= X.[GroupId]
					WHERE 
						' + ISNULL('B.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						(X.[PostId] IS NULL OR X.[GroupId] IS NULL)
					';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
