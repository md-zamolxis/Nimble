SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Geolocation'	AND
			O.[type]	= 'P'			AND
			O.[name]	= 'Portion.Action'))
	DROP PROCEDURE [Geolocation].[Portion.Action];
GO

CREATE PROCEDURE [Geolocation].[Portion.Action]
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
		@order			= @order			OUTPUT;
	
	IF (@permissionType = 'PortionCreate') BEGIN
		INSERT [Geolocation].[Portion] 
		(
			[PortionSourceId],
			[PortionCode],
			[PortionEntries],
			[PortionEntriesLoaded],
			[PortionEntriesImported]
		)
		OUTPUT INSERTED.[PortionId] INTO @output ([Id])
		SELECT
			X.[SourceId],
			CONVERT(NVARCHAR(MAX), SYSDATETIMEOFFSET(), 121),
			X.[Entries],
			X.[EntriesLoaded],
			X.[EntriesImported]
		FROM [Geolocation].[Portion.Entity](@entity) X;
		SELECT P.* FROM [Geolocation].[Entity.Portion]	P
		INNER JOIN	@output								X	ON	P.[PortionId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'PortionRead') BEGIN
		SELECT P.* FROM [Geolocation].[Entity.Portion]		P
		INNER JOIN	[Geolocation].[Portion.Entity](@entity)	X	ON	P.[PortionId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'PortionUpdate') BEGIN
		UPDATE P SET 
			P.[PortionEntriesLoaded]	= X.[EntriesLoaded],
			P.[PortionEntriesImported]	= X.[EntriesImported]
		OUTPUT INSERTED.[PortionId] INTO @output ([Id])
		FROM [Geolocation].[Portion]						P
		INNER JOIN	[Geolocation].[Portion.Entity](@entity)	X	ON	P.[PortionId]		= X.[Id]	AND
																	P.[PortionVersion]	= X.[Version];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
		SELECT P.* FROM [Geolocation].[Entity.Portion]	P
		INNER JOIN	@output								X	ON	P.[PortionId]	= X.[Id];
	END

END
GO
