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
			O.[name]	= 'Group.Entity'))
	DROP FUNCTION [Owner.Branch].[Group.Entity];
GO

CREATE FUNCTION [Owner.Branch].[Group.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[GroupId], XSC.[GroupId], XSD.[GroupId], XSI.[GroupId])	[Id],
		X.[SplitId],
		X.[Code],
		X.[Name],
		X.[Names],
		X.[Description],
		X.[Descriptions],
		X.[IsDefault],
		X.[Index],
		X.[Settings],
		X.[Version]
	FROM 
	(
		SELECT TOP 1
			X.[Id],
			S.[Id]	[SplitId],
			X.[Code],
			X.[Name],
			X.[Names],
			X.[Description],
			X.[Descriptions],
			X.[IsDefault],
			X.[Index],
			X.[Settings],
			X.[Version]
		FROM 
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',					'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('BranchSplit')						   					[BranchSplit],
				X.[Entity].value('(Code/text())[1]',				'NVARCHAR(MAX)')	[Code],
				X.[Entity].value('(Name/text())[1]',				'NVARCHAR(MAX)')	[Name],
				X.[Entity].query('Names/*')												[Names],
				X.[Entity].value('(Description/text())[1]',			'NVARCHAR(MAX)')	[Description],
				X.[Entity].query('Descriptions/*')										[Descriptions],
				ISNULL(X.[Entity].value('(IsDefault/text())[1]',	'BIT'), 0)			[IsDefault],
				X.[Entity].value('(Index/text())[1]',				'INT')				[Index],
				X.[Entity].query('Settings/*')											[Settings],
				X.[Entity].value('(Version/text())[1]',				'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)															X
		OUTER APPLY [Owner.Branch].[Split.Entity](X.[BranchSplit])	S
	)									X
	LEFT JOIN	[Owner.Branch].[Group]	XI	ON	X.[Id]			= XI.[GroupId]
	LEFT JOIN	[Owner.Branch].[Group]	XSC	ON	X.[SplitId]		= XSC.[GroupSplitId]	AND
												X.[Code]		= XSC.[GroupCode]
	LEFT JOIN	[Owner.Branch].[Group]	XSD	ON	X.[IsDefault]	= 1						AND
												X.[SplitId]		= XSD.[GroupSplitId]	AND
												X.[IsDefault]	= XSD.[GroupIsDefault]
	LEFT JOIN	[Owner.Branch].[Group]	XSI	ON	X.[Index]		IS NOT NULL				AND
												X.[SplitId]		= XSI.[GroupSplitId]	AND
												X.[Index]		= XSI.[GroupIndex]
)
GO
