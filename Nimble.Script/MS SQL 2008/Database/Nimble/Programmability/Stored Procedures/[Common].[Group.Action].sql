SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	G
		INNER JOIN	[sys].[objects]		O	ON	G.[schema_id]	= O.[schema_id]
		WHERE 
			G.[name]	= 'Common'	AND
			O.[type]	= 'P'		AND
			O.[name]	= 'Group.Action'))
	DROP PROCEDURE [Common].[Group.Action];
GO

CREATE PROCEDURE [Common].[Group.Action]
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

	DECLARE 
		@exist		BIT	= @entity.exist('/*/Entities'),
		@entities	XML	= @entity.query('/*/Entities');

	SELECT * INTO [#input] FROM [Common].[Group.Entity](@entity) X;
	
	IF (@permissionType = 'GroupCreate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			IF (EXISTS(SELECT * FROM [#input] X WHERE X.[IsDefault] = 1))
				UPDATE G SET G.[GroupIsDefault] = 0
				FROM [Common].[Group]	G
				INNER JOIN	[#input]	X	ON	G.[GroupSplitId]	=	X.[SplitId]	AND
												G.[GroupIsDefault]	=	1;
			WITH XC AS
			(
				SELECT ISNULL(MAX(CAST(G.[GroupCode] AS INT)), 0) + 1	[Code]
				FROM [#input]					X
				INNER JOIN	[Common].[Group]	G	ON	X.[SplitId]	= G.[GroupSplitId]
				WHERE [Common].[Code.IsNumeric](G.[GroupCode]) = 1
			)
			INSERT [Common].[Group]
			(
				[GroupSplitId],
				[GroupCode],
				[GroupName],
				[GroupNames],
				[GroupDescription],
				[GroupDescriptions],
				[GroupIsDefault],
				[GroupSettings]
			)
			OUTPUT INSERTED.[GroupId] INTO @output ([Id])
			SELECT
				X.[SplitId],
				ISNULL(X.[Code], XC.[Code]),
				X.[Name],
				X.[Names],
				X.[Description],
				X.[Descriptions],
				X.[IsDefault],
				X.[Settings]
			FROM [#input] X OUTER APPLY XC;
			IF (@exist = 1)
				INSERT [Common].[Bond]
				SELECT DISTINCT
					E.[Guid]	[EntityId],
					X.[Id]		[GroupId]
				FROM @output X, 
				[Common].[Guid.Entities](@entities) E;
			INSERT [Common].[Bond]
			SELECT 
				E.[EntityId],
				G.[GroupId]
			FROM @output					X
			INNER JOIN	[Common].[Group]	G	ON	X.[Id]					= G.[GroupId]	AND
													G.[GroupIsDefault]		= 1
			INNER JOIN	[Common].[Split]	S	ON	G.[GroupSplitId]		= S.[SplitId]
			INNER JOIN (
				SELECT 
					B.[BranchId]					[EntityId],
					'Branch'						[SplitEntityType],
					O.[OrganisationEmplacementId]	[EmplacementId]
				FROM [Owner].[Branch]				B
				INNER JOIN	[Owner].[Organisation]	O	ON	B.[BranchOrganisationId]	= O.[OrganisationId]
			)								E	ON	S.[SplitEntityType]		= E.[SplitEntityType]	AND
													S.[SplitEmplacementId]	= E.[EmplacementId]
			LEFT JOIN
			(
				SELECT * FROM [Common].[Bond]	B
				INNER JOIN	[Common].[Group]	G	ON	B.[BondGroupId]	= G.[GroupId]
			)								B	ON	E.[EntityId]			= B.[BondEntityId]	AND
													G.[GroupSplitId]		= B.[GroupSplitId]
			WHERE COALESCE(B.[BondEntityId], B.[GroupSplitId]) IS NULL;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT G.* FROM [Common].[Entity.Group]	G
		INNER JOIN	@output						X	ON	G.[GroupId]			= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'GroupRead') BEGIN
		SELECT G.* FROM [Common].[Entity.Group]	G
		INNER JOIN	[#input]					X	ON	G.[GroupId]			= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'GroupUpdate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			IF (EXISTS(SELECT * FROM [#input] X WHERE X.[IsDefault] = 1))
				UPDATE G SET G.[GroupIsDefault] = 0
				FROM [Common].[Group]	G
				INNER JOIN	[#input]	X	ON	G.[GroupId]			<>	X.[Id]		AND
												G.[GroupSplitId]	=	X.[SplitId]	AND
												G.[GroupIsDefault]	=	1;
			UPDATE G SET 
				G.[GroupCode]			= X.[Code],
				G.[GroupName]			= X.[Name],
				G.[GroupNames]			= X.[Names],
				G.[GroupDescription]	= X.[Description],
				G.[GroupDescriptions]	= X.[Descriptions],
				G.[GroupIsDefault]		= X.[IsDefault],
				G.[GroupSettings]		= X.[Settings]
			OUTPUT INSERTED.[GroupId] INTO @output ([Id])
			FROM [Common].[Group]	G
			INNER JOIN	[#input]	X	ON	G.[GroupId]			= X.[Id]	AND
											G.[GroupVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			IF (@exist = 1) BEGIN
				DELETE B FROM [Common].[Bond]	B
				INNER JOIN	@output				X	ON	B.[BondGroupId]	= X.[Id];
				INSERT [Common].[Bond]
				SELECT DISTINCT
					E.[Guid]	[EntityId],
					X.[Id]		[GroupId]
				FROM @output X, 
				[Common].[Guid.Entities](@entities) E;
			END
			INSERT [Common].[Bond]
			SELECT 
				E.[EntityId],
				G.[GroupId]
			FROM @output					X
			INNER JOIN	[Common].[Group]	G	ON	X.[Id]					= G.[GroupId]	AND
													G.[GroupIsDefault]		= 1
			INNER JOIN	[Common].[Split]	S	ON	G.[GroupSplitId]		= S.[SplitId]
			INNER JOIN (
				SELECT 
					B.[BranchId]					[EntityId],
					'Branch'						[SplitEntityType],
					O.[OrganisationEmplacementId]	[EmplacementId]
				FROM [Owner].[Branch]				B
				INNER JOIN	[Owner].[Organisation]	O	ON	B.[BranchOrganisationId]	= O.[OrganisationId]
			)								E	ON	S.[SplitEntityType]		= E.[SplitEntityType]	AND
													S.[SplitEmplacementId]	= E.[EmplacementId]
			LEFT JOIN
			(
				SELECT * FROM [Common].[Bond]	B
				INNER JOIN	[Common].[Group]	G	ON	B.[BondGroupId]	= G.[GroupId]
			)								B	ON	E.[EntityId]			= B.[BondEntityId]	AND
													G.[GroupSplitId]		= B.[GroupSplitId]
			WHERE COALESCE(B.[BondEntityId], B.[GroupSplitId]) IS NULL;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT G.* FROM [Common].[Entity.Group]	G
		INNER JOIN	@output						X	ON	G.[GroupId]			= X.[Id];
	END

	IF (@permissionType = 'GroupDelete') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			DELETE B FROM [Common].[Bond]	B
			INNER JOIN	[#input]			X	ON	B.[BondGroupId]			= X.[Id];
			DELETE G FROM [Common].[Group]	G
			INNER JOIN	[#input]			X	ON	G.[GroupId]				= X.[Id]	AND
													G.[GroupVersion]		= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END
	IF (@permissionType = 'GroupSearch') BEGIN
		CREATE TABLE [#group] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Common].[Group.Filter]
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
		INSERT [#group] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [GroupSplitId] ASC, [GroupCode] ASC ');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT G.* FROM [Common].[Entity.Group]		G
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT G.* FROM [#group]				X
					INNER JOIN	[Common].[Entity.Group]		G	ON	X.[Id]		= G.[GroupId]
					';
				ELSE
					SET @command = '
					SELECT G.* FROM [Common].[Entity.Group]	G
					LEFT JOIN	[#group]					X	ON	G.[GroupId]	= X.[Id]
					WHERE 
						' + ISNULL('G.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
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
						G.*, 
						ROW_NUMBER() OVER(' + @order + ') [Number]
					FROM [Common].[Entity.Group]			G
				)	G
				WHERE G.[Number] BETWEEN
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							G.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [#group]						X
						INNER JOIN	[Common].[Entity.Group]	G	ON	X.[Id]		= G.[GroupId]
					)	G
					WHERE G.[Number] BETWEEN
					';
				ELSE
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							G.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [Common].[Entity.Group]		G
						LEFT JOIN	[#group]				X	ON	G.[GroupId]	= X.[Id]
						WHERE 
							' + ISNULL('G.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
							X.[Id] IS NULL
					)	G
					WHERE G.[Number] BETWEEN
					';
			SET @command = @command + CAST(@startNumber AS NVARCHAR(MAX)) + ' AND ' + CAST(@endNumber AS NVARCHAR(MAX));
		END
		EXEC sp_executesql @command;
	END

END
GO
