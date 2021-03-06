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
			O.[name]	= 'GenericInput.Action'))
	DROP PROCEDURE [Common].[GenericInput.Action];
GO

CREATE PROCEDURE [Common].[GenericInput.Action] 
(
	@genericInput	XML,
	@permissionType NVARCHAR(MAX)				OUTPUT,
	@entity			XML							OUTPUT,
	@predicate		XML							OUTPUT,
	@index			INT							OUTPUT,
	@size			INT							OUTPUT,
	@startNumber	INT							OUTPUT,
	@endNumber		INT							OUTPUT,
	@order			NVARCHAR(MAX)				OUTPUT,
	@groupTop		NVARCHAR(MAX)		= NULL	OUTPUT,
	@groupBottom	NVARCHAR(MAX)		= NULL	OUTPUT,
	@emplacementId	UNIQUEIDENTIFIER			OUTPUT,
	@applicationId	UNIQUEIDENTIFIER			OUTPUT,
	@personId		UNIQUEIDENTIFIER	= NULL	OUTPUT,
	@organisations	XML							OUTPUT,
	@branches		XML					= NULL	OUTPUT,
	@latitude		FLOAT				= NULL	OUTPUT,
	@longitude		FLOAT				= NULL	OUTPUT
)
AS
BEGIN
	
	DECLARE 
		@emplacement	XML,
		@application	XML,
		@person			XML,
		@organisation	BIT;

	SELECT 
		@permissionType = X.[Entity].value('(PermissionType/text())[1]',	'NVARCHAR(MAX)'),
		@entity			= @genericInput.query('/*/Entity'),
		@predicate		= @genericInput.query('/*/Predicate'),
		@emplacement	= @genericInput.query('/*/Emplacement'),
		@application	= @genericInput.query('/*/Application'),
		@person			= @genericInput.query('/*/Person'),
		@organisation	= @genericInput.exist('/*/Organisations'),
		@latitude		= X.[Entity].value('(Latitude/text())[1]',			'FLOAT'),
		@longitude		= X.[Entity].value('(Longitude/text())[1]',			'FLOAT')
	FROM @genericInput.nodes('/*') X ([Entity]);

	SELECT 
		@index			= X.[Index],
		@size			= X.[Size],
		@startNumber	= X.[StartNumber], 
		@endNumber		= X.[EndNumber] 
	FROM [Common].[Pager.Entity](@predicate.query('/*/Pager')) X;

	SELECT 
		@order			= X.[Entity].value('(Order/text())[1]',			'NVARCHAR(MAX)'),
		@groupTop		= X.[Entity].value('(GroupTop/text())[1]',		'NVARCHAR(MAX)'),
		@groupBottom	= X.[Entity].value('(GroupBottom/text())[1]',	'NVARCHAR(MAX)')
	FROM @predicate.nodes('/*') X ([Entity]);

	SELECT @emplacementId = X.[Id] FROM [Security].[Emplacement.Entity](@emplacement) X;
	SELECT @applicationId = X.[Id] FROM [Security].[Application.Entity](@application) X;
	SELECT @personId = X.[Id] FROM [Owner].[Person.Entity](@person) X;

	SET @organisations = (
		SELECT DISTINCT E.[Id] [guid] 
		FROM [Common].[Generic.Entities](@genericInput.query('/*/Organisations/Organisation')) X
		CROSS APPLY [Owner].[Organisation.Entity](X.[Entity]) E 
		WHERE E.[Id] IS NOT NULL
		FOR XML PATH(''), ROOT('Guids')
	);

	IF (@organisations IS NULL AND
		@organisation = 1)
		SET @organisations = '<Guids/>';
			
	SET @branches = (
		SELECT DISTINCT E.[Id] [guid] 
		FROM [Common].[Generic.Entities](@genericInput.query('/*/Branches/Branch')) X
		CROSS APPLY [Owner].[Branch.Entity](X.[Entity]) E 
		WHERE E.[Id] IS NOT NULL
		FOR XML PATH(''), ROOT('Guids')
	);

END
GO
