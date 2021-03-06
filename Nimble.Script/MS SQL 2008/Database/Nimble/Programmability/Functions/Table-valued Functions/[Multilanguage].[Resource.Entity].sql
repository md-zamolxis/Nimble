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
			O.[name]	= 'Resource.Entity'))
	DROP FUNCTION [Multilanguage].[Resource.Entity];
GO

CREATE FUNCTION [Multilanguage].[Resource.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[ResourceId], XEACC.[ResourceId], XEAI.[ResourceId])	[Id],
		X.[EmplacementId],
		X.[ApplicationId],
		X.[Code],
		X.[Category],
		X.[Index],
		X.[CreatedOn],
		X.[LastUsedOn],
		X.[Version]
	FROM
	(
		SELECT TOP 1
			X.[Id],
			E.[Id]	[EmplacementId],
			A.[Id]	[ApplicationId],
			X.[Code],
			X.[Category],
			X.[Index],
			X.[CreatedOn],
			X.[LastUsedOn],
			X.[Version]
		FROM
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',				'UNIQUEIDENTIFIER')												[Id],
				X.[Entity].query('Emplacement')																					[Emplacement],
				X.[Entity].query('Application')																					[Application],
				X.[Entity].value('(Code/text())[1]',			'NVARCHAR(MAX)')		COLLATE SQL_Latin1_General_CP1_CS_AS	[Code],
				ISNULL(X.[Entity].value('(Category/text())[1]',	'NVARCHAR(MAX)'), '')	COLLATE SQL_Latin1_General_CP1_CS_AS	[Category],
				X.[Entity].value('(Index/text())[1]',			'NVARCHAR(MAX)')												[Index],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('CreatedOn'))													[CreatedOn],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('LastUsedOn'))												[LastUsedOn],
				X.[Entity].value('(Version/text())[1]',			'VARBINARY(MAX)')												[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)																X
		OUTER APPLY [Security].[Emplacement.Entity](X.[Emplacement])	E
		OUTER APPLY [Security].[Application.Entity](X.[Application])	A
	)										X
	LEFT JOIN	[Multilanguage].[Resource]	XI		ON	X.[Id]				= XI.[ResourceId]
	LEFT JOIN	[Multilanguage].[Resource]	XEACC	ON	X.[EmplacementId]	= XEACC.[ResourceEmplacementId]	AND
														X.[ApplicationId]	= XEACC.[ResourceApplicationId]	AND
														X.[Code]			= XEACC.[ResourceCode]			AND
														X.[Category]		= XEACC.[ResourceCategory]
	LEFT JOIN	[Multilanguage].[Resource]	XEAI	ON	X.[EmplacementId]	= XEAI.[ResourceEmplacementId]	AND
														X.[ApplicationId]	= XEAI.[ResourceApplicationId]	AND
														X.[Index]			= XEAI.[ResourceIndex]
)
GO
