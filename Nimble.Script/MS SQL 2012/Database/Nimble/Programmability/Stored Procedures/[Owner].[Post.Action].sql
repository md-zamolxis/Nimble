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
			O.[name]	= 'Post.Action'))
	DROP PROCEDURE [Owner].[Post.Action];
GO

CREATE PROCEDURE [Owner].[Post.Action]
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

	SELECT * INTO [#input] FROM [Owner].[Post.Entity](@entity) X;
	
	DECLARE 
		@exist		BIT	= @entity.exist('/*/PostGroups'),
		@postGroups	XML	= @entity.query('/*/PostGroups/PostGroup');

	IF (@permissionType = 'PostCreate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY;
			WITH XC AS
			(
				SELECT ISNULL(MAX(CAST(P.[PostCode] AS INT)), 0) + 1	[Code]
				FROM [#input]				X
				INNER JOIN	[Owner].[Post]	P	ON	X.[OrganisationId]	= P.[PostOrganisationId]
				WHERE [Common].[Code.IsNumeric](P.[PostCode]) = 1
			)
			INSERT [Owner].[Post] 
			(
				[PostOrganisationId],
				[PostCode],
				[PostDate],
				[PostTitle],
				[PostTitles],
				[PostSubject],
				[PostSubjects],
				[PostBody],
				[PostBodies],
				[PostUrls],
				[PostCreatedOn],
				[PostUpdatedOn],
				[PostDeletedOn],
				[PostActionType],
				[PostSettings]
			)
			OUTPUT INSERTED.[PostId] INTO @output ([Id])
			SELECT
				X.[OrganisationId],
				ISNULL(X.[Code], XC.[Code]),
				X.[Date],
				X.[Title],
				X.[Titles],
				X.[Subject],
				X.[Subjects],
				X.[Body],
				X.[Bodies],
				X.[Urls],
				X.[CreatedOn],
				X.[UpdatedOn],
				X.[DeletedOn],
				X.[PostActionType],
				X.[Settings]
			FROM [#input] X OUTER APPLY XC;
			IF (@exist = 1)
				INSERT [Owner.Post].[Bond]
				SELECT DISTINCT
					X.[Id]	[PostId],
					E.[Id]	[GroupId]
				FROM @output X, 
				[Common].[Generic.Entities](@postGroups) I
				CROSS APPLY [Owner.Post].[Group.Entity](I.[Entity]) E;
			INSERT [Owner.Post].[Bond]
			SELECT 
				P.[PostId],
				G.[GroupId]
			FROM @output						X
			INNER JOIN	[Owner].[Post]			P	ON	X.[Id]					= P.[PostId]
			INNER JOIN	[Owner.Post].[Split]	S	ON	P.[PostOrganisationId]	= S.[SplitOrganisationId]
			INNER JOIN	[Owner.Post].[Group]	G	ON	S.[SplitId]				= G.[GroupSplitId]	AND
														G.[GroupIsDefault]		= 1
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
		SELECT P.* FROM [Owner].[Entity.Post]	P
		INNER JOIN	@output						X	ON	P.[PostId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'PostRead') BEGIN
		SELECT P.* FROM [Owner].[Entity.Post]	P
		INNER JOIN	[#input]					X	ON	P.[PostId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'PostUpdate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			UPDATE P SET 
				P.[PostCode]		= X.[Code],
				P.[PostDate]		= X.[Date],
				P.[PostTitle]		= X.[Title],
				P.[PostTitles]		= X.[Titles],
				P.[PostSubject]		= X.[Subject],
				P.[PostSubjects]	= X.[Subjects],
				P.[PostBody]		= X.[Body],
				P.[PostBodies]		= X.[Bodies],
				P.[PostUrls]		= X.[Urls],
				P.[PostUpdatedOn]	= X.[UpdatedOn],
				P.[PostDeletedOn]	= X.[DeletedOn],
				P.[PostActionType]	= X.[PostActionType],
				P.[PostSettings]	= X.[Settings]
			OUTPUT INSERTED.[PostId] INTO @output ([Id])
			FROM [Owner].[Post]						P
			INNER JOIN	[#input]					X	ON	P.[PostId]		= X.[Id]		AND
															P.[PostVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			IF (@exist = 1) BEGIN
				DELETE B FROM [Owner.Post].[Bond]	B
				INNER JOIN	@output					X	ON	B.[BondPostId]	= X.[Id];
				INSERT [Owner.Post].[Bond]
				SELECT DISTINCT
					X.[Id]	[PostId],
					E.[Id]	[GroupId]
				FROM @output X, 
				[Common].[Generic.Entities](@postGroups) I
				CROSS APPLY [Owner.Post].[Group.Entity](I.[Entity]) E;
			END
			INSERT [Owner.Post].[Bond]
			SELECT 
				P.[PostId],
				G.[GroupId]
			FROM @output						X
			INNER JOIN	[Owner].[Post]			P	ON	X.[Id]					= P.[PostId]
			INNER JOIN	[Owner.Post].[Split]	S	ON	P.[PostOrganisationId]	= S.[SplitOrganisationId]
			INNER JOIN	[Owner.Post].[Group]	G	ON	S.[SplitId]				= G.[GroupSplitId]	AND
														G.[GroupIsDefault]		= 1
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
		SELECT P.* FROM [Owner].[Entity.Post]	P
		INNER JOIN	@output						X	ON	P.[PostId]	= X.[Id];
	END

	IF (@permissionType = 'PostDelete') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			DELETE B FROM [Owner.Post].[Bond]	B
			INNER JOIN	[#input]				X	ON	B.[BondPostId]	= X.[Id];
			DELETE	P	FROM [Owner].[Post]		P
			INNER JOIN	[#input]				X	ON	P.[PostId]		= X.[Id]	AND
														P.[PostVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END
	
	IF (@permissionType = 'PostSearch') BEGIN
		CREATE TABLE [#post] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Owner].[Post.Filter]
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
		INSERT [#post] SELECT * FROM [Common].[Guid.Entities](@guids);
		SET @order = ISNULL(@order, ' ORDER BY [PostOrganisationId] ASC, [PostCode] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT P.* FROM [Owner].[Entity.Post]			P
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT P.* FROM [#post]						X
				INNER JOIN	[Owner].[Entity.Post]			P	ON	X.[Id]				= P.[PostId]
				';
			ELSE
				IF (@organisations IS NULL)
					SET @command = '
					SELECT P.* FROM [Owner].[Entity.Post]	P	
					LEFT JOIN	[#post]						X	ON	P.[PostId]			= X.[Id]
					WHERE 
						' + ISNULL('P.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						X.[Id] IS NULL
					';
				ELSE
					SET @command = '
					SELECT P.* FROM [Owner].[Entity.Post]	P	
					INNER JOIN	[#organisations]			XO	ON	P.[OrganisationId]	= XO.[Id]
					LEFT JOIN	[#post]						X	ON	P.[PostId]			= X.[Id]
					WHERE 
						' + ISNULL('P.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						X.[Id] IS NULL
					';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
