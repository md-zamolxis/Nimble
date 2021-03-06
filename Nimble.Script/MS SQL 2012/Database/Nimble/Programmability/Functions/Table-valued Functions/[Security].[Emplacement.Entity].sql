SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Security'	AND
			O.[type]	= 'IF'			AND
			O.[name]	= 'Emplacement.Entity'))
	DROP FUNCTION [Security].[Emplacement.Entity];
GO

CREATE FUNCTION [Security].[Emplacement.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[EmplacementId], XC.[EmplacementId])	[Id],
		X.[Code],
		X.[Description],
		X.[IsAdministrative],
		X.[Version]
	FROM
	(
		SELECT
			X.[Entity].value('(Id/text())[1]',						'UNIQUEIDENTIFIER')	[Id],
			X.[Entity].value('(Code/text())[1]',					'NVARCHAR(MAX)')	[Code],
			X.[Entity].value('(Description/text())[1]',				'NVARCHAR(MAX)')	[Description],
			ISNULL(X.[Entity].value('(IsAdministrative/text())[1]',	'BIT'), 0)			[IsAdministrative],
			X.[Entity].value('(Version/text())[1]',					'VARBINARY(MAX)')	[Version]
		FROM @entity.nodes('/*') X ([Entity])
	)										X
	LEFT JOIN	[Security].[Emplacement]	XI	ON	X.[Id]		= XI.[EmplacementId]
	LEFT JOIN	[Security].[Emplacement]	XC	ON	X.[Code]	= XC.[EmplacementCode]
)
GO
