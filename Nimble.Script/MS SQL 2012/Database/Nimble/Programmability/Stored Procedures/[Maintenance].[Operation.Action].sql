SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Maintenance'	AND
			O.[type]	= 'P'			AND
			O.[name]	= 'Operation.Action'))
	DROP PROCEDURE [Maintenance].[Operation.Action];
GO

CREATE PROCEDURE [Maintenance].[Operation.Action]
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
	
	IF (@permissionType = 'OperationSearch') BEGIN
		CREATE TABLE [#operation] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Maintenance].[Operation.Filter]
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
		INSERT [#operation] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [OperationBatchId] ASC, [OperationCode] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT O.* FROM [Maintenance].[Entity.Operation]		O
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT O.* FROM [#operation]						X
				INNER JOIN	[Maintenance].[Entity.Operation]		O	ON	X.[Id]			= O.[OperationId]
				';
			ELSE
				SET @command = '
				SELECT O.* FROM [Maintenance].[Entity.Operation]	O
				LEFT JOIN	[#operation]							X	ON	O.[OperationId]	= X.[Id]
				WHERE X.[Id] IS NULL
				';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
