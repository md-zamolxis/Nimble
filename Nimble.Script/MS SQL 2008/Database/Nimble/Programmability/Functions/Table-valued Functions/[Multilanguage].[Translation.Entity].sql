SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multilanguage'	AND
			O.[type]	= 'IF'				AND
			O.[name]	= 'Translation.Entity'))
	DROP FUNCTION [Multilanguage].[Translation.Entity];
GO

CREATE FUNCTION [Multilanguage].[Translation.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[TranslationId], XRC.[TranslationId])	[Id],
		X.[ResourceId],
		X.[CultureId],
		X.[Sense],
		X.[Version]
	FROM
	(
		SELECT TOP 1
			X.[Id],
			R.[Id]	[ResourceId],
			C.[Id]	[CultureId],
			X.[Sense],
			X.[Version]
		FROM
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',		'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Resource')								[Resource],
				X.[Entity].query('Culture')									[Culture],
				X.[Entity].value('(Sense/text())[1]',	'NVARCHAR(MAX)')	[Sense],
				X.[Entity].value('(Version/text())[1]',	'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)															X
		OUTER APPLY [Multilanguage].[Resource.Entity](X.[Resource])	R
		OUTER APPLY [Multilanguage].[Culture.Entity](X.[Culture])	C
	)											X
	LEFT JOIN	[Multilanguage].[Translation]	XI	ON	X.[Id]			= XI.[TranslationId]
	LEFT JOIN	[Multilanguage].[Translation]	XRC	ON	X.[ResourceId]	= XRC.[TranslationResourceId]	AND
														X.[CultureId]	= XRC.[TranslationCultureId]
)
GO
