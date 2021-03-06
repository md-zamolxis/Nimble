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
	@permissionType NVARCHAR(MAX)	OUTPUT,
	@entity			XML				OUTPUT,
	@predicate		XML				OUTPUT,
	@startNumber	INT				OUTPUT,
	@endNumber		INT				OUTPUT,
	@order			NVARCHAR(MAX)	OUTPUT
)
AS
BEGIN
	
	SELECT 
		@permissionType = X.[Entity].value('(PermissionType/text())[1]',	'NVARCHAR(MAX)'),
		@entity			= @genericInput.query('/*/Entity'),
		@predicate		= @genericInput.query('/*/Predicate')
	FROM @genericInput.nodes('/*') X ([Entity]);
	
	SELECT 
		@startNumber	= X.[StartNumber], 
		@endNumber		= X.[EndNumber] 
	FROM [Common].[Pager.Entity](@predicate.query('/*/Pager')) X;
	
	SELECT @order = X.[Entity].value('(Order/text())[1]', 'NVARCHAR(MAX)') FROM @predicate.nodes('/*') X ([Entity]);

END
GO
