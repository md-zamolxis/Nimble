SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'IF'		AND
			O.[name]	= 'Split.Entity'))
	DROP FUNCTION [Common].[Split.Entity];
GO

CREATE FUNCTION [Common].[Split.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[SplitId], XEETC.[SplitId])	[Id],
		X.[EmplacementId],
		X.[SplitEntityType],
		X.[SplitEntityCode],
		X.[Name],
		X.[Names],
		X.[IsSystem],
		X.[IsExclusive],
		X.[Settings],
		X.[Version]
	FROM
	(
		SELECT TOP 1
			X.[Id],
			E.[Id]	[EmplacementId],
			X.[SplitEntityType],
			X.[SplitEntityCode],
			X.[Name],
			X.[Names],
			X.[IsSystem],
			X.[IsExclusive],
			X.[Settings],
			X.[Version]
		FROM
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',					'UNIQUEIDENTIFIER') [Id],
				X.[Entity].query('Emplacement')											[Emplacement],
				X.[Entity].value('(SplitEntityType/text())[1]',		'NVARCHAR(MAX)')	[SplitEntityType],
				X.[Entity].value('(SplitEntityCode/text())[1]',		'NVARCHAR(MAX)')	[SplitEntityCode],
				X.[Entity].value('(Name/text())[1]',				'NVARCHAR(MAX)')	[Name],
				X.[Entity].query('Names/*')												[Names],
				ISNULL(X.[Entity].value('(IsSystem/text())[1]',		'BIT'), 0)			[IsSystem],
				ISNULL(X.[Entity].value('(IsExclusive/text())[1]',	'BIT'), 0)			[IsExclusive],
				X.[Entity].query('Settings/*')											[Settings],
				X.[Entity].value('(Version/text())[1]',				'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)																X
		OUTER APPLY [Security].[Emplacement.Entity](X.[Emplacement])	E
	)								X
	LEFT JOIN	[Common].[Split]	XI		ON	X.[Id]				= XI.[SplitId]
	LEFT JOIN	[Common].[Split]	XEETC	ON	X.[EmplacementId]	= XEETC.[SplitEmplacementId]	AND
												X.[SplitEntityType]	= XEETC.[SplitEntityType]		AND
												X.[SplitEntityCode]	= XEETC.[SplitEntityCode]
)
GO
