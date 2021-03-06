SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'P'		AND
			O.[name]	= 'Bond.Action'))
	DROP PROCEDURE [Common].[Bond.Action];
GO

CREATE PROCEDURE [Common].[Bond.Action]
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
	
	DECLARE 
		@bonds			XML					= @predicate.query('/*/Bonds/Value/Bond'),
		@organisationId	UNIQUEIDENTIFIER,
		@splitId		UNIQUEIDENTIFIER,
		@groupId		UNIQUEIDENTIFIER;

	SELECT * INTO [#input] FROM [Common].[Bond.Entity](@entity) X;
	
	IF (@permissionType = 'BondRead') BEGIN
		SELECT B.* FROM [Common].[Entity.Bond]	B
		INNER JOIN	[#input]					X	ON	B.[BondEntityId]	= X.[EntityId]	AND
														B.[BondGroupId]		= X.[GroupId];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'BondSearch') BEGIN
		CREATE TABLE [#bond] 
		(
			[EntityId]	UNIQUEIDENTIFIER,
			[GroupId]	UNIQUEIDENTIFIER,
			PRIMARY KEY CLUSTERED 
			(
				[EntityId],
				[GroupId]
			)
		);
		EXEC sp_executesql 
			N'EXEC [Common].[Bond.Filter]
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
			LTRIM(X.[Entity].value('(EntityId/text())[1]',	'UNIQUEIDENTIFIER')) [EntityId],
			LTRIM(X.[Entity].value('(GroupId/text())[1]',	'UNIQUEIDENTIFIER')) [GroupId]
		FROM @guids.nodes('/*/guid') X ([Entity]);
		SET @order = ISNULL(@order, ' ORDER BY B.[BondEntityId] ASC, B.[BondGroupId] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT B.* FROM [Common].[Entity.Bond]		B
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT B.* FROM [#bond]					X
				INNER JOIN	[Common].[Entity.Bond]		B	ON	X.[EntityId]		= B.[BondEntityId]	AND
																X.[GroupId]			= B.[BondGroupId]
				';
			ELSE
				SET @command = '
				SELECT B.* FROM [Common].[Entity.Bond]	B
				LEFT JOIN	[#bond]						X	ON	B.[BondEntityId]	= X.[EntityId]	AND
																B.[BondGroupId]		= X.[GroupId]
				WHERE 
					' + ISNULL('B.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
					(X.[EntityId] IS NULL OR X.[GroupId] IS NULL)
				';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
