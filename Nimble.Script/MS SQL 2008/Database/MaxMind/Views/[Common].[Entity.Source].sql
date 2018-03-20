SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Geolocation'	AND
			O.[type]	= 'V'			AND
			O.[name]	= 'Entity.Source'))
	DROP VIEW [Geolocation].[Entity.Source];
GO

CREATE VIEW [Geolocation].[Entity.Source]
AS
SELECT
	S.[SourceId],
	S.[SourceCode],
	S.[SourceInputType],
	S.[SourceDescription],
	S.[SourceCreatedOn],
	S.[SourceApprovedOn],
	S.[SourceInputLength],
	S.[SourceEntriesLoaded],
	S.[SourceErrorsLoaded],
	S.[SourceVersion]
FROM [Geolocation].[Source] S
GO
