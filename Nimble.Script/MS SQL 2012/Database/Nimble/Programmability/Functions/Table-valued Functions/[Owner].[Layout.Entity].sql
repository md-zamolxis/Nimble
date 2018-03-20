SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner'	AND
			O.[type]	= 'IF'		AND
			O.[name]	= 'Layout.Entity'))
	DROP FUNCTION [Owner].[Layout.Entity];
GO

CREATE FUNCTION [Owner].[Layout.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[LayoutId], XOETC.[LayoutId])	[Id],
		X.[OrganisationId],
		X.[LayoutEntityType],
		X.[Code],
		X.[Name],
		X.[Description],
		X.[Settings],
		X.[Version]
	FROM 
	(
		SELECT TOP 1
			X.[Id],
			O.[Id]	[OrganisationId],
			X.[LayoutEntityType],
			X.[Code],
			X.[Name],
			X.[Description],
			X.[Settings],
			X.[Version]
		FROM 
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',					'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Organisation')			   							[Organisation],
				X.[Entity].value('(LayoutEntityType/text())[1]',	'NVARCHAR(MAX)')	[LayoutEntityType],
				X.[Entity].value('(Code/text())[1]',				'NVARCHAR(MAX)')	[Code],
				X.[Entity].value('(Name/text())[1]',				'NVARCHAR(MAX)')	[Name],
				X.[Entity].value('(Description/text())[1]',			'NVARCHAR(MAX)')	[Description],
				X.[Entity].query('Settings/*')											[Settings],
				X.[Entity].value('(Version/text())[1]',				'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)															X
		OUTER APPLY [Owner].[Organisation.Entity](X.[Organisation])	O
	)								X
	LEFT JOIN	[Owner].[Layout]	XI		ON	X.[Id]					= XI.[LayoutId]
	LEFT JOIN	[Owner].[Layout]	XOETC	ON	X.[OrganisationId]		= XOETC.[LayoutOrganisationId]	AND
												X.[LayoutEntityType]	= XOETC.[LayoutEntityType]		AND
												X.[Code]				= XOETC.[LayoutCode]
)
GO
