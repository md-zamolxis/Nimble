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
			O.[name]	= 'Role.Entity'))
	DROP FUNCTION [Security].[Role.Entity];
GO

CREATE FUNCTION [Security].[Role.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[RoleId], XEAC.[RoleId])	[Id],
		X.[EmplacementId],
		X.[ApplicationId],
		X.[Code],
		X.[Description],
		X.[Version]
	FROM
	(
		SELECT TOP 1
			X.[Id],
			E.[Id]	[EmplacementId],
			A.[Id]	[ApplicationId],
			X.[Code],
			X.[Description],
			X.[Version]
		FROM
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',			'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Emplacement')									[Emplacement],
				X.[Entity].query('Application')									[Application],
				X.[Entity].value('(Code/text())[1]',		'NVARCHAR(MAX)')	[Code],
				X.[Entity].value('(Description/text())[1]',	'NVARCHAR(MAX)')	[Description],
				X.[Entity].value('(Version/text())[1]',		'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)																X
		OUTER APPLY [Security].[Emplacement.Entity](X.[Emplacement])	E
		OUTER APPLY [Security].[Application.Entity](X.[Application])	A
	)								X
	LEFT JOIN	[Security].[Role]	XI		ON	X.[Id]				= XI.[RoleId]
	LEFT JOIN	[Security].[Role]	XEAC	ON	X.[EmplacementId]	= XEAC.[RoleEmplacementId]	AND
												X.[ApplicationId]	= XEAC.[RoleApplicationId]	AND
												X.[Code]			= XEAC.[RoleCode]
)
GO
