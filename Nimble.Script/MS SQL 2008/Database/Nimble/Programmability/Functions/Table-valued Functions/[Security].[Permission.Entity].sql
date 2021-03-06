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
			O.[name]	= 'Permission.Entity'))
	DROP FUNCTION [Security].[Permission.Entity];
GO

CREATE FUNCTION [Security].[Permission.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[PermissionId], XAC.[PermissionId])	[Id],
		X.[ApplicationId],
		X.[Code],
		X.[Category],
		X.[Description],
		X.[Version]
	FROM
	(
		SELECT TOP 1
			X.[Id],
			A.[Id]	[ApplicationId],
			X.[Code],
			X.[Category],
			X.[Description],
			X.[Version]
		FROM
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',			'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Application')									[Application],
				X.[Entity].value('(Code/text())[1]',		'NVARCHAR(MAX)')	[Code],
				X.[Entity].value('(Category/text())[1]',	'NVARCHAR(MAX)')	[Category],
				X.[Entity].value('(Description/text())[1]',	'NVARCHAR(MAX)')	[Description],
				X.[Entity].value('(Version/text())[1]',		'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)																X
		OUTER APPLY [Security].[Application.Entity](X.[Application])	A
	)									X
	LEFT JOIN	[Security].[Permission]	XI	ON	X.[Id]				= XI.[PermissionId]
	LEFT JOIN	[Security].[Permission]	XAC	ON	X.[ApplicationId]	= XAC.[PermissionApplicationId]	AND
												X.[Code]			= XAC.[PermissionCode]
)
GO
