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
			O.[name]	= 'Split.Action'))
	DROP PROCEDURE [Owner.Branch].[Split.Action];
GO

CREATE PROCEDURE [Owner.Branch].[Split.Action]
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

	SELECT * INTO [#input] FROM [Owner.Branch].[Split.Entity](@entity) X;
	
	IF (@permissionType = 'BranchSplitCreate') BEGIN
		WITH XC AS
		(
			SELECT ISNULL(MAX(CAST(S.[SplitCode] AS INT)), 0) + 1	[Code]
			FROM [#input]						X
			INNER JOIN	[Owner.Branch].[Split]	S	ON	X.[OrganisationId]	= S.[SplitOrganisationId]
			WHERE [Common].[Code.IsNumeric](S.[SplitCode]) = 1
		)
		INSERT [Owner.Branch].[Split]
		(
			[SplitOrganisationId],
			[SplitCode],
			[SplitBranchType],
			[SplitName],
			[SplitNames],
			[SplitIsSystem],
			[SplitIsExclusive],
			[SplitSettings]
		)
		OUTPUT INSERTED.[SplitId] INTO @output ([Id])
		SELECT
			X.[OrganisationId],
			ISNULL(X.[Code], XC.[Code]),
			X.[SplitBranchType],
			X.[Name],
			X.[Names],
			X.[IsSystem],
			X.[IsExclusive],
			X.[Settings]
		FROM [#input] X OUTER APPLY XC;
		SELECT S.* FROM [Owner.Branch].[Entity.Split]	S
		INNER JOIN	@output								X	ON	S.[SplitId]			= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'BranchSplitRead') BEGIN
		SELECT S.* FROM [Owner.Branch].[Entity.Split]	S
		INNER JOIN	[#input]							X	ON	S.[SplitId]			= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'BranchSplitUpdate') BEGIN
		UPDATE S SET 
			S.[SplitCode]		= X.[Code],
			S.[SplitName]		= X.[Name],
			S.[SplitNames]		= X.[Names],
			S.[SplitIsSystem]	= X.[IsSystem],
			S.[SplitSettings]	= X.[Settings]
		OUTPUT INSERTED.[SplitId] INTO @output ([Id])
		FROM [Owner.Branch].[Split]						S
		INNER JOIN	[#input]							X	ON	S.[SplitId]			= X.[Id]	AND
																S.[SplitVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT S.* FROM [Owner.Branch].[Entity.Split]	S
		INNER JOIN	@output								X	ON	S.[SplitId]			= X.[Id];
	END

	IF (@permissionType = 'BranchSplitDelete') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			DELETE B FROM [Owner.Branch].[Bond]			B
			INNER JOIN	[Owner.Branch].[Group]			G	ON	B.[BondGroupId]		= G.[GroupId]
			INNER JOIN	[#input]						X	ON	G.[GroupSplitId]	= X.[Id];
			DELETE	G	FROM [Owner.Branch].[Group]	G
			INNER JOIN	[#input]						X	ON	G.[GroupSplitId]	= X.[Id];
			DELETE S FROM [Owner.Branch].[Split]		S
			INNER JOIN	[#input]						X	ON	S.[SplitId]			= X.[Id]	AND
																S.[SplitVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END
	
	IF (@permissionType = 'BranchSplitSearch') BEGIN
		CREATE TABLE [#split] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner.Branch].[Split.Filter]
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
		INSERT [#split] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [SplitOrganisationId] ASC, [SplitCode] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT S.* FROM [Owner.Branch].[Entity.Split]			S
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT S.* FROM [#split]							X
				INNER JOIN	[Owner.Branch].[Entity.Split]			S	ON	X.[Id]				= S.[SplitId]
				';
			ELSE
				IF (@organisations IS NULL)
					SET @command = '
					SELECT S.* FROM [Owner.Branch].[Entity.Split]	S
					LEFT JOIN	[#split]							X	ON	S.[SplitId]			= X.[Id]
					WHERE 
						' + ISNULL('S.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						X.[Id] IS NULL
					';
				ELSE
					SET @command = '
					SELECT S.* FROM [Owner.Branch].[Entity.Split]	S
					INNER JOIN	[#organisations]					XO	ON	S.[OrganisationId]	= XO.[Id]
					LEFT JOIN	[#split]							X	ON	S.[SplitId]			= X.[Id]
					WHERE 
						' + ISNULL('S.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						X.[Id] IS NULL
					';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
