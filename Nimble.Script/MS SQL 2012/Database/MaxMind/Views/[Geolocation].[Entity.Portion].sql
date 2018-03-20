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
			O.[name]	= 'Entity.Portion'))
	DROP VIEW [Geolocation].[Entity.Portion];
GO

CREATE VIEW [Geolocation].[Entity.Portion]
AS
SELECT
	P.[PortionId],
	P.[PortionCode],
	P.[PortionEntriesLoaded],
	P.[PortionEntriesImported],
	P.[PortionVersion],
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
FROM [Geolocation].[Portion]		P
INNER JOIN	[Geolocation].[Source]	S	ON	P.[PortionSourceId]	= S.[SourceId]
GO
