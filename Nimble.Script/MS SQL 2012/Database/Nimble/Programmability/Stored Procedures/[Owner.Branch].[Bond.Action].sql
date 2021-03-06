SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Branch'	AND
			O.[type]	= 'P'				AND
			O.[name]	= 'Bond.Action'))
	DROP PROCEDURE [Owner.Branch].[Bond.Action];
GO

CREATE PROCEDURE [Owner.Branch].[Bond.Action]
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
	
	DECLARE 
		@branchBonds	XML					= @predicate.query('/*/BranchBonds/Value/BranchBond'),
		@organisationId	UNIQUEIDENTIFIER,
		@splitId		UNIQUEIDENTIFIER,
		@groupId		UNIQUEIDENTIFIER;

	SELECT * INTO [#input] FROM [Owner.Branch].[Bond.Entity](@entity) X;
	
	IF (@permissionType = 'BranchBondRead') BEGIN
		SELECT B.* FROM [Owner.Branch].[Entity.Bond]	B
		INNER JOIN	[#input]							X	ON	B.[BranchId]	= X.[BranchId]	AND
																B.[GroupId]		= X.[GroupId];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'BranchBondSearch') BEGIN
		CREATE TABLE [#bond] 
		(
			[BranchId]	UNIQUEIDENTIFIER,
			[GroupId]	UNIQUEIDENTIFIER,
			PRIMARY KEY CLUSTERED 
			(
				[BranchId],
				[GroupId]
			)
		);
		EXEC sp_executesql 
			N'EXEC [Owner.Branch].[Bond.Filter]
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
			LTRIM(X.[Entity].value('(BranchId/text())[1]',	'UNIQUEIDENTIFIER')) [BranchId],
			LTRIM(X.[Entity].value('(GroupId/text())[1]',	'UNIQUEIDENTIFIER')) [GroupId]
		FROM @guids.nodes('/*/guid') X ([Entity]);
		SET @order = ISNULL(@order, ' ORDER BY B.[BranchId] ASC, B.[GroupId] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT B.* FROM [Owner.Branch].[Entity.Bond]			B
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT B.* FROM [#bond]								X
				INNER JOIN	[Owner.Branch].[Entity.Bond]			B	ON	X.[BranchId]		= B.[BranchId]	AND
																			X.[GroupId]			= B.[GroupId]
				';
			ELSE
				IF (@organisations IS NULL)
					SET @command = '
					SELECT B.* FROM [Owner.Branch].[Entity.Bond]	B
					LEFT JOIN	[#bond]								X	ON	B.[BranchId]		= X.[BranchId]	AND
																			B.[GroupId]			= X.[GroupId]
					WHERE 
						' + ISNULL('B.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						(X.[BranchId] IS NULL OR X.[GroupId] IS NULL)
					';
				ELSE
					SET @command = '
					SELECT B.* FROM [Owner.Branch].[Entity.Bond]	B
					INNER JOIN	[#organisations]					XO	ON	B.[OrganisationId]	= XO.[Id]
					LEFT JOIN	[#bond]								X	ON	B.[BranchId]		= X.[BranchId]	AND
																			B.[GroupId]			= X.[GroupId]
					WHERE 
						' + ISNULL('B.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						(X.[BranchId] IS NULL OR X.[GroupId] IS NULL)
					';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
