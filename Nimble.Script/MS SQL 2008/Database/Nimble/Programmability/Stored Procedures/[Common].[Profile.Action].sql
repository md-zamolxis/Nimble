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
			O.[name]	= 'Profile.Action'))
	DROP PROCEDURE [Common].[Profile.Action];
GO

CREATE PROCEDURE [Common].[Profile.Action]
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
		@isFiltered		BIT,
		@command		NVARCHAR(MAX);
	
	DECLARE @input TABLE ([Id] UNIQUEIDENTIFIER);
	
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
		
	INSERT @input SELECT DISTINCT X.[Id] FROM [Common].[Profile.Entity](@entity) X;
	
	IF (@permissionType = 'ProfileRead') BEGIN
		SELECT * FROM [Common].[Profile]	P
		INNER JOIN	@input					X	ON	P.[ProfileId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'ProfileUpdate') BEGIN
		MERGE [Common].[Profile] P
		USING 
		(
			SELECT * FROM [Common].[Profile.Entity](@entity)
		)	X	ON	P.[ProfileId]	= X.[Id]	AND
					P.[ProfileCode]	= X.[Code]
		WHEN MATCHED THEN UPDATE SET
			P.[ProfileValue]	= X.[Value]
		WHEN NOT MATCHED BY TARGET THEN INSERT 
		(
			[ProfileId],
			[ProfileCode],
			[ProfileValue]
		)
		VALUES
		(
			X.[Id],
			X.[Code],
			X.[Value]
		);
		SELECT * FROM [Common].[Profile]	P
		INNER JOIN	@input					X	ON	P.[ProfileId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END

	IF (@permissionType = 'ProfileDelete') BEGIN
		DELETE P FROM [Common].[Profile]	P
		INNER JOIN	@input					X	ON	P.[ProfileId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END

END
GO
