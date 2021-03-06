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
			O.[name]	= 'Culture.Entity'))
	DROP FUNCTION [Multilanguage].[Culture.Entity];
GO

CREATE FUNCTION [Multilanguage].[Culture.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[CultureId], XEC.[CultureId], XEN.[CultureId])	[Id],
		X.[EmplacementId],
		X.[Code],
		X.[Name],
		X.[Version]
	FROM
	(
		SELECT TOP 1
			X.[Id],
			E.[Id]	[EmplacementId],
			X.[Code],
			X.[Name],
			X.[Version]
		FROM
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',		'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Emplacement')								[Emplacement],
				X.[Entity].value('(Code/text())[1]',	'NVARCHAR(MAX)')	[Code],
				X.[Entity].value('(Name/text())[1]',	'NVARCHAR(MAX)')	[Name],
				X.[Entity].value('(Version/text())[1]',	'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)																X
		OUTER APPLY [Security].[Emplacement.Entity](X.[Emplacement])	E
	)										X
	LEFT JOIN	[Multilanguage].[Culture]	XI	ON	X.[Id]				= XI.[CultureId]
	LEFT JOIN	[Multilanguage].[Culture]	XEC	ON	X.[EmplacementId]	= XEC.[CultureEmplacementId]	AND
													X.[Code]			= XEC.[CultureCode]
	LEFT JOIN	[Multilanguage].[Culture]	XEN	ON	X.[EmplacementId]	= XEN.[CultureEmplacementId]	AND
													X.[Name]			= XEN.[CultureName]
)
GO
