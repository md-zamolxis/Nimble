SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Post'	AND
			O.[type]	= 'IF'				AND
			O.[name]	= 'Split.Entity'))
	DROP FUNCTION [Owner.Post].[Split.Entity];
GO

CREATE FUNCTION [Owner.Post].[Split.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[SplitId], XOC.[SplitId], XOPT.[SplitId])	[Id],
		X.[OrganisationId],
		X.[Code],
		X.[SplitPostType],
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
			O.[Id]	[OrganisationId],
			X.[Code],
			X.[SplitPostType],
			X.[Name],
			X.[Names],
			X.[IsSystem],
			X.[IsExclusive],
			X.[Settings],
			X.[Version]
		FROM 
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',					'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Organisation')					   					[Organisation],
				X.[Entity].value('(Code/text())[1]',				'NVARCHAR(MAX)')	[Code],
				X.[Entity].value('(SplitPostType/text())[1]',		'NVARCHAR(MAX)')	[SplitPostType],
				X.[Entity].value('(Name/text())[1]',				'NVARCHAR(MAX)')	[Name],
				X.[Entity].query('Names/*')												[Names],
				ISNULL(X.[Entity].value('(IsSystem/text())[1]',		'BIT'), 0)			[IsSystem],
				ISNULL(X.[Entity].value('(IsExclusive/text())[1]',	'BIT'), 0)			[IsExclusive],
				X.[Entity].query('Settings/*')											[Settings],
				X.[Entity].value('(Version/text())[1]',				'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)															X
		OUTER APPLY [Owner].[Organisation.Entity](X.[Organisation])	O
	)									X
	LEFT JOIN	[Owner.Post].[Split]	XI		ON	X.[Id]				= XI.[SplitId]
	LEFT JOIN	[Owner.Post].[Split]	XOC		ON	X.[OrganisationId]	= XOC.[SplitOrganisationId]		AND
													X.[Code]			= XOC.[SplitCode]
	LEFT JOIN	[Owner.Post].[Split]	XOPT	ON	X.[SplitPostType]	IS NOT NULL						AND
													X.[OrganisationId]	= XOPT.[SplitOrganisationId]	AND
													X.[SplitPostType]	= XOPT.[SplitPostType]
)
GO
