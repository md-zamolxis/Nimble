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
			O.[name]	= 'Group.Action'))
	DROP PROCEDURE [Owner.Post].[Group.Action];
GO

CREATE PROCEDURE [Owner.Post].[Group.Action]
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
	
	CREATE TABLE [#organisations] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
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
	INSERT [#organisations] SELECT * FROM [Common].[Guid.Entities](@organisations);

	DECLARE 
		@exist	BIT	= @entity.exist('/*/Posts'),
		@posts	XML	= @entity.query('/*/Posts/Post');

	SELECT * INTO [#input] FROM [Owner.Post].[Group.Entity](@entity) X;
	
	IF (@permissionType = 'PostGroupCreate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			IF (EXISTS(SELECT * FROM [#input] X WHERE X.[IsDefault] = 1))
				UPDATE G SET G.[GroupIsDefault] = 0
				FROM [Owner.Post].[Group]	G
				INNER JOIN	[#input]		X	ON	G.[GroupSplitId]	= X.[SplitId]	AND
													G.[GroupIsDefault]	= 1;
			WITH XC AS
			(
				SELECT ISNULL(MAX(CAST(G.[GroupCode] AS INT)), 0) + 1	[Code]
				FROM [#input]						X
				INNER JOIN	[Owner.Post].[Group]	G	ON	X.[SplitId]	= G.[GroupSplitId]
				WHERE [Common].[Code.IsNumeric](G.[GroupCode]) = 1
			)
			INSERT [Owner.Post].[Group]
			(
				[GroupSplitId],
				[GroupCode],
				[GroupName],
				[GroupNames],
				[GroupDescription],
				[GroupDescriptions],
				[GroupIsDefault],
				[GroupCreatedOn],
				[GroupUpdatedOn],
				[GroupDeletedOn],
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
				X.[CreatedOn],
				X.[UpdatedOn],
				X.[DeletedOn],
				X.[Settings]
			FROM [#input] X OUTER APPLY XC;
			IF (@exist = 1)
				INSERT [Owner.Post].[Bond]
				SELECT DISTINCT
					E.[Id]	[PostId],
					X.[Id]	[GroupId]
				FROM @output X, 
				[Common].[Generic.Entities](@posts) I
				CROSS APPLY [Owner].[Post.Entity](I.[Entity]) E;
			INSERT [Owner.Post].[Bond]
			SELECT 
				P.[PostId],
				G.[GroupId]
			FROM @output						X
			INNER JOIN	[Owner.Post].[Group]	G	ON	X.[Id]					= G.[GroupId]	AND
														G.[GroupIsDefault]		= 1
			INNER JOIN	[Owner.Post].[Split]	S	ON	G.[GroupSplitId]		= S.[SplitId]
			INNER JOIN	[Owner].[Post]			P	ON	S.[SplitOrganisationId]	= P.[PostOrganisationId]
			LEFT JOIN
			(
				SELECT * FROM [Owner.Post].[Bond]	B
				INNER JOIN	[Owner.Post].[Group]	G	ON	B.[BondGroupId]		= G.[GroupId]
			)										B	ON	P.[PostId]			= B.[BondPostId]	AND
															G.[GroupSplitId]	= B.[GroupSplitId]
			WHERE COALESCE(B.[BondPostId], B.[GroupSplitId]) IS NULL;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT G.* FROM [Owner.Post].[Entity.Group]	G
		INNER JOIN	@output							X	ON	G.[GroupId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'PostGroupRead') BEGIN
		SELECT G.* FROM [Owner.Post].[Entity.Group]	G
		INNER JOIN	[#input]						X	ON	G.[GroupId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'PostGroupUpdate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			IF (EXISTS(SELECT * FROM [#input] X WHERE X.[IsDefault] = 1))
				UPDATE G SET G.[GroupIsDefault] = 0
				FROM [Owner.Post].[Group]	G
				INNER JOIN	[#input]		X	ON	G.[GroupId]			<>	X.[Id]		AND
													G.[GroupSplitId]	=	X.[SplitId]	AND
													G.[GroupIsDefault]	=	1;
			UPDATE G SET 
				G.[GroupCode]			= X.[Code],
				G.[GroupName]			= X.[Name],
				G.[GroupNames]			= X.[Names],
				G.[GroupDescription]	= X.[Description],
				G.[GroupDescriptions]	= X.[Descriptions],
				G.[GroupIsDefault]		= X.[IsDefault],
				G.[GroupUpdatedOn]		= X.[UpdatedOn],
				G.[GroupDeletedOn]		= X.[DeletedOn],
				G.[GroupSettings]		= X.[Settings]
			OUTPUT INSERTED.[GroupId] INTO @output ([Id])
			FROM [Owner.Post].[Group]	G
			INNER JOIN	[#input]		X	ON	G.[GroupId]			= X.[Id]	AND
												G.[GroupVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			IF (@exist = 1) BEGIN
				DELETE B FROM [Owner.Post].[Bond]	B
				INNER JOIN	@output					X	ON	B.[BondGroupId]	= X.[Id];
				INSERT [Owner.Post].[Bond]
				SELECT DISTINCT
					E.[Id]	[PostId],
					X.[Id]	[GroupId]
				FROM @output X, 
				[Common].[Generic.Entities](@posts) I
				CROSS APPLY [Owner].[Post.Entity](I.[Entity]) E;
			END
			INSERT [Owner.Post].[Bond]
			SELECT 
				P.[PostId],
				G.[GroupId]
			FROM @output						X
			INNER JOIN	[Owner.Post].[Group]	G	ON	X.[Id]					= G.[GroupId]	AND
														G.[GroupIsDefault]		= 1
			INNER JOIN	[Owner.Post].[Split]	S	ON	G.[GroupSplitId]		= S.[SplitId]
			INNER JOIN	[Owner].[Post]			P	ON	S.[SplitOrganisationId]	= P.[PostOrganisationId]
			LEFT JOIN
			(
				SELECT * FROM [Owner.Post].[Bond]	B
				INNER JOIN	[Owner.Post].[Group]	G	ON	B.[BondGroupId]		= G.[GroupId]
			)										B	ON	P.[PostId]			= B.[BondPostId]	AND
															G.[GroupSplitId]	= B.[GroupSplitId]
			WHERE COALESCE(B.[BondPostId], B.[GroupSplitId]) IS NULL;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT G.* FROM [Owner.Post].[Entity.Group]		G
		INNER JOIN	@output								X	ON	G.[GroupId]	= X.[Id];
	END

	IF (@permissionType = 'PostGroupDelete') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			DELETE B FROM [Owner.Post].[Bond]	B
			INNER JOIN	[#input]				X	ON	B.[BondGroupId]		= X.[Id];
			DELETE G FROM [Owner.Post].[Group]	G
			INNER JOIN	[#input]				X	ON	G.[GroupId]			= X.[Id]	AND
														G.[GroupVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END

	IF (@permissionType = 'PostGroupSearch') BEGIN
		CREATE TABLE [#group] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner.Post].[Group.Filter]
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
				SELECT G.* FROM [Owner.Post].[Entity.Group]			G
				';
			ELSE
				IF (@isExcluded = 0)
					SET @command = '
					SELECT G.* FROM [#group]						X
					INNER JOIN	[Owner.Post].[Entity.Group]			G	ON	X.[Id]				= G.[GroupId]
					';
				ELSE
					IF (@organisations IS NULL)
						SET @command = '
						SELECT G.* FROM [Owner.Post].[Entity.Group]	G
						LEFT JOIN	[#group]						X	ON	G.[GroupId]			= X.[Id]
						WHERE 
							' + ISNULL('G.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
							X.[Id] IS NULL
						';
					ELSE
						SET @command = '
						SELECT G.* FROM [Owner.Post].[Entity.Group]	G
						INNER JOIN	[#organisations]				XO	ON	G.[OrganisationId]	= XO.[Id]
						LEFT JOIN	[#group]						X	ON	G.[GroupId]			= X.[Id]
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
					FROM [Owner.Post].[Entity.Group]				G
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
						FROM [#group]								X
						INNER JOIN	[Owner.Post].[Entity.Group]		G	ON	X.[Id]				= G.[GroupId]
					)	G
					WHERE G.[Number] BETWEEN
					';
				ELSE
					IF (@organisations IS NULL)
						SET @command = '
						SELECT * FROM
						(
							SELECT 
								G.*, 
								ROW_NUMBER() OVER(' + @order + ') [Number]
							FROM [Owner.Post].[Entity.Group]		G
							LEFT JOIN	[#group]					X	ON	G.[GroupId]			= X.[Id]
							WHERE 
								' + ISNULL('G.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
								X.[Id] IS NULL
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
							FROM [Owner.Post].[Entity.Group]		G
							INNER JOIN	[#organisations]			XO	ON	G.[OrganisationId]	= XO.[Id]
							LEFT JOIN	[#group]					X	ON	G.[GroupId]			= X.[Id]
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
