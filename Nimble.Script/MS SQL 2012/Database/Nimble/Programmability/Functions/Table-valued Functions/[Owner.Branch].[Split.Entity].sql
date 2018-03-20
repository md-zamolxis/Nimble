SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Branch'	AND
			O.[type]	= 'IF'				AND
			O.[name]	= 'Split.Entity'))
	DROP FUNCTION [Owner.Branch].[Split.Entity];
GO

CREATE FUNCTION [Owner.Branch].[Split.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[SplitId], XOC.[SplitId], XOBT.[SplitId])	[Id],
		X.[OrganisationId],
		X.[Code],
		X.[SplitBranchType],
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
			X.[SplitBranchType],
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
				X.[Entity].value('(SplitBranchType/text())[1]',		'NVARCHAR(MAX)')	[SplitBranchType],
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
	LEFT JOIN	[Owner.Branch].[Split]	XI		ON	X.[Id]				= XI.[SplitId]
	LEFT JOIN	[Owner.Branch].[Split]	XOC		ON	X.[OrganisationId]	= XOC.[SplitOrganisationId]		AND
													X.[Code]			= XOC.[SplitCode]
	LEFT JOIN	[Owner.Branch].[Split]	XOBT	ON	X.[SplitBranchType]	IS NOT NULL						AND
													X.[OrganisationId]	= XOBT.[SplitOrganisationId]	AND
													X.[SplitBranchType]	= XOBT.[SplitBranchType]
)
GO
