SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	F
		INNER JOIN	[sys].[objects]		O	ON	F.[schema_id]	= O.[schema_id]
		WHERE 
			F.[name]	= 'Common'	AND
			O.[type]	= 'P'		AND
			O.[name]	= 'Filestream.Action'))
	DROP PROCEDURE [Common].[Filestream.Action];
GO

CREATE PROCEDURE [Common].[Filestream.Action]
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
		@personId		= @personId			OUTPUT,
		@organisations	= @organisations	OUTPUT;
	INSERT [#organisations] SELECT * FROM [Common].[Guid.Entities](@organisations);

	DECLARE 
		@filestreams	XML = @predicate.query('/*/Filestreams/Value/Filestream'),
		@loadData		BIT	= [Common].[Bool.Entity](@predicate.query('/*/LoadData'));
	
	IF (@permissionType = 'FilestreamRead') BEGIN
		SELECT F.* FROM [Common].[Entity.Filestream]		F
		INNER JOIN	[Common].[Filestream.Entity](@entity)	X	ON	F.[FilestreamId]= X.[Id];
		SET @number = @@ROWCOUNT;
	END

	IF (@permissionType = 'FilestreamSearch' OR
		@permissionType = 'FilestreamRemove') 
	BEGIN
		CREATE TABLE [#filestream] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC sp_executesql 
			N'EXEC [Common].[Filestream.Filter]
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
		INSERT [#filestream] SELECT * FROM [Common].[Guid.Entities](@guids);
	END

	IF (@permissionType = 'FilestreamSync') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			SELECT * INTO [#input] FROM [Common].[Filestream.Entity](@filestreams);
			UPDATE F SET F.[FilestreamIsDefault] = 0
			FROM [#input]						X
			INNER JOIN	[Common].[Filestream]	F	ON	X.[IsDefault]	= 1							AND
														X.[EntityId]	= F.[FilestreamEntityId]	AND
														X.[IsDefault]	= F.[FilestreamIsDefault];
			INSERT [Common].[Filestream]
			(
				[FilestreamEmplacementId],
				[FilestreamPersonId],
				[FilestreamOrganisationId],
				[FilestreamEntityId],
				[FilestreamCode],
				[FilestreamReferenceId],
				[FilestreamCreatedOn],
				[FilestreamName],
				[FilestreamDescription],
				[FilestreamExtension],
				[FilestreamData],
				[FilestreamIsDefault],
				[FilestreamUrl],
				[FilestreamThumbnailId],
				[FilestreamThumbnailWidth],
				[FilestreamThumbnailHeight],
				[FilestreamThumbnailExtension],
				[FilestreamThumbnailUrl]
			)
			OUTPUT INSERTED.[FilestreamEntityId] INTO @output ([Id])
			SELECT
				X.[EmplacementId],
				X.[PersonId],
				X.[OrganisationId],
				X.[EntityId],
				ISNULL(X.[Code], X.[ReferenceId]),
				X.[ReferenceId],
				X.[CreatedOn],
				ISNULL(X.[Name], X.[ReferenceId]),
				X.[Description],
				X.[Extension],
				X.[Data],
				X.[IsDefault],
				X.[Url],
				X.[ThumbnailId],
				X.[ThumbnailWidth],
				X.[ThumbnailHeight],
				X.[ThumbnailExtension],
				X.[ThumbnailUrl]
			FROM [#input] X 
			WHERE X.[EntityActionType] = 'Create';
			UPDATE F SET 
				F.[FilestreamCode]					= X.[Code],
				F.[FilestreamReferenceId]			= X.[ReferenceId],
				F.[FilestreamName]					= X.[Name],
				F.[FilestreamDescription]			= X.[Description],
				F.[FilestreamExtension]				= X.[Extension],
				F.[FilestreamData]					= X.[Data],
				F.[FilestreamIsDefault]				= X.[IsDefault],
				F.[FilestreamUrl]					= X.[Url],
				F.[FilestreamThumbnailId]			= X.[ThumbnailId],
				F.[FilestreamThumbnailWidth]		= X.[ThumbnailWidth],
				F.[FilestreamThumbnailHeight]		= X.[ThumbnailHeight],
				F.[FilestreamThumbnailExtension]	= X.[ThumbnailExtension],
				F.[FilestreamThumbnailUrl]			= X.[ThumbnailUrl]
			OUTPUT INSERTED.[FilestreamEntityId] INTO @output ([Id])
			FROM [Common].[Filestream]	F
			INNER JOIN	[#input]		X	ON	F.[FilestreamId]	= X.[Id]
			WHERE X.[EntityActionType] = 'Update';
			UPDATE F SET 
				F.[FilestreamCode]			= X.[Code],
				F.[FilestreamName]			= X.[Name],
				F.[FilestreamDescription]	= X.[Description],
				F.[FilestreamIsDefault]		= X.[IsDefault],
				F.[FilestreamUrl]			= X.[Url],
				F.[FilestreamThumbnailUrl]	= X.[ThumbnailUrl]
			OUTPUT INSERTED.[FilestreamEntityId] INTO @output ([Id])
			FROM [Common].[Filestream]	F
			INNER JOIN	[#input]		X	ON	F.[FilestreamId]	= X.[Id]
			WHERE X.[EntityActionType] = 'Save';
			DELETE F OUTPUT DELETED.[FilestreamEntityId] INTO @output ([Id])
			FROM [Common].[Filestream]	F
			INNER JOIN	[#input]		X	ON	F.[FilestreamId]	= X.[Id]
			WHERE X.[EntityActionType] = 'Delete';
			UPDATE F SET F.[FilestreamIsDefault] = 1
			FROM [Common].[Filestream]	F
			INNER JOIN 
			(
				SELECT 
					CAST(MAX(CAST(F.[FilestreamId] AS NVARCHAR(MAX))) AS UNIQUEIDENTIFIER)	[Id],
					F.[FilestreamEntityId]													[EntityId],
					SUM(CAST(F.[FilestreamIsDefault] AS INT))								[IsDefault]	
				FROM [Common].[Filestream]	F
				INNER JOIN	@output			X	ON	F.[FilestreamEntityId]	= X.[Id]
				GROUP BY F.[FilestreamEntityId]
			)							X	ON	F.[FilestreamId]	= X.[Id]
			WHERE X.[IsDefault] = 0;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END  

	IF (@permissionType = 'FilestreamRemove') BEGIN
		DELETE F FROM [Common].[Filestream]	F
		INNER JOIN	 [#filestream]			X	ON	F.[FilestreamId]	= X.[Id];
	END
	
	IF (@permissionType = 'FilestreamSearch') BEGIN
		IF (@loadData = 1) SET @command = '[Common].[Filestream]' ELSE SET @command = '[Common].[Entity.Filestream]';
		SET @order = ISNULL(@order, ' ORDER BY [FilestreamEntityId] ASC, [FilestreamCode] ASC ');
		IF (@isFiltered = 0)
			SET @command = '
			SELECT F.* FROM ' + @command + '			F
			';
		ELSE
			IF (@isExcluded = 0)
				SET @command = '
				SELECT F.* FROM [#filestream]			X
				INNER JOIN	' + @command + '			F	ON	X.[Id]							= F.[FilestreamId]
				';
			ELSE
				IF (@organisations IS NULL)
					SET @command = '
					SELECT F.* FROM ' + @command + '	F
					LEFT JOIN	[#filestream]			X	ON	F.[FilestreamId]				= X.[Id]
					WHERE 
						' + ISNULL('F.[FilestreamEmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						X.[Id] IS NULL
					';
				ELSE
					SET @command = '
					SELECT F.* FROM ' + @command + '	F
					LEFT JOIN	[#organisations]		I	ON	F.[FilestreamOrganisationId]	= I.[Id]
					LEFT JOIN	[#filestream]			X	ON	F.[FilestreamId]				= X.[Id]
					WHERE 
						' + ISNULL('F.[FilestreamEmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						(
							F.[FilestreamPersonId] = ''' + CAST(@personId AS NVARCHAR(MAX)) + ''' OR
							XO.[Id] IS NOT NULL
						)	AND
						X.[Id] IS NULL
					';
		SET @command = @command + @order;
		IF (@startNumber IS NOT NULL AND @size IS NOT NULL)
			SET @command = @command + ' OFFSET ' + CAST(@startNumber AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@size AS NVARCHAR(MAX)) + ' ROWS ONLY ';
		EXEC sp_executesql @command;
	END

END
GO
