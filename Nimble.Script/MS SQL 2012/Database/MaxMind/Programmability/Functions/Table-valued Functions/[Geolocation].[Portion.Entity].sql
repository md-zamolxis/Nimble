SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Geolocation'	AND
			O.[type]	= 'IF'			AND
			O.[name]	= 'Portion.Entity'))
	DROP FUNCTION [Geolocation].[Portion.Entity];
GO

CREATE FUNCTION [Geolocation].[Portion.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[PortionId], XEC.[PortionId])	[Id],
		X.[SourceId],
		X.[Code],
		X.[Entries],
		X.[EntriesLoaded],
		X.[EntriesImported],
		X.[Version]
	FROM 
	(
		SELECT
			X.[Entity].value('(Id/text())[1]',				'UNIQUEIDENTIFIER')	[Id],
			X.[Entity].value('(Source/Id/text())[1]',		'UNIQUEIDENTIFIER')	[SourceId],
			X.[Entity].value('(Code/text())[1]',			'NVARCHAR(MAX)')	[Code],
			X.[Entity].value('(Entries/text())[1]',			'NVARCHAR(MAX)')	[Entries],
			X.[Entity].value('(EntriesLoaded/text())[1]',	'BIGINT')			[EntriesLoaded],
			X.[Entity].value('(EntriesImported/text())[1]',	'BIGINT')			[EntriesImported],
			X.[Entity].value('(Version/text())[1]',			'VARBINARY(MAX)')	[Version]
		FROM @entity.nodes('/*') X ([Entity])
	)									X
	LEFT JOIN	[Geolocation].[Portion]	XI	ON	X.[Id]			= XI.[PortionId]
	LEFT JOIN	[Geolocation].[Portion]	XEC	ON	X.[SourceId]	= XEC.[PortionSourceId]	AND
												X.[Code]		= XEC.[PortionCode]
)
GO
