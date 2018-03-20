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
			O.[name]	= 'Post.Entity'))
	DROP FUNCTION [Owner].[Post.Entity];
GO

CREATE FUNCTION [Owner].[Post.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[PostId], XOC.[PostId])	[Id],
		X.[OrganisationId],
		X.[Code],
		X.[Date],
		X.[Title],
		X.[Titles],
		X.[Subject],
		X.[Subjects],
		X.[Body],
		X.[Bodies],
		X.[Urls],
		X.[CreatedOn],
		X.[UpdatedOn],
		X.[DeletedOn],
		X.[PostActionType],
		X.[Settings],
		X.[Version]
	FROM 
	(
		SELECT TOP 1
			X.[Id],
			O.[Id]	[OrganisationId],
			X.[Code],
			X.[Date],
			X.[Title],
			X.[Titles],
			X.[Subject],
			X.[Subjects],
			X.[Body],
			X.[Bodies],
			X.[Urls],
			X.[CreatedOn],
			X.[UpdatedOn],
			X.[DeletedOn],
			X.[PostActionType],
			X.[Settings],
			X.[Version]
		FROM 
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',								'UNIQUEIDENTIFIER')				[Id],
				X.[Entity].query('Organisation')								   								[Organisation],
				X.[Entity].value('(Code/text())[1]',							'NVARCHAR(MAX)')				[Code],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('Date'))										[Date],
				X.[Entity].value('(Title/text())[1]',							'NVARCHAR(MAX)')				[Title],
				X.[Entity].query('Titles/*')																	[Titles],
				X.[Entity].value('(Subject/text())[1]',							'NVARCHAR(MAX)')				[Subject],
				X.[Entity].query('Subjects/*')																	[Subjects],
				X.[Entity].value('(Body/text())[1]',							'NVARCHAR(MAX)')				[Body],
				X.[Entity].query('Bodies/*')																	[Bodies],
				X.[Entity].query('Urls/*')																		[Urls],
				ISNULL([Common].[DateTimeOffset.Entity](X.[Entity].query('CreatedOn')), SYSDATETIMEOFFSET())	[CreatedOn],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('UpdatedOn'))									[UpdatedOn],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('DeletedOn'))									[DeletedOn],
				ISNULL(X.[Entity].value('(PostActionType/Number/text())[1]',	'INT'), 0)         				[PostActionType],
				X.[Entity].query('Settings/*')																	[Settings],
				X.[Entity].value('(Version/text())[1]',							'VARBINARY(MAX)')				[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)															X
		OUTER APPLY [Owner].[Organisation.Entity](X.[Organisation])	O
	)							X
	LEFT JOIN	[Owner].[Post]	XI	ON	X.[Id]				= XI.[PostId]
	LEFT JOIN	[Owner].[Post]	XOC	ON	X.[OrganisationId]	= XOC.[PostOrganisationId]	AND
										X.[Code]			= XOC.[PostCode]
)
GO
