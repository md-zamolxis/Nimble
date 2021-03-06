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
			O.[name]	= 'User.Entity'))
	DROP FUNCTION [Security].[User.Entity];
GO

CREATE FUNCTION [Security].[User.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[UserId], XEC.[UserId], XEF.[UserId], XEG.[UserId])	[Id],
		X.[EmplacementId],
		X.[Code],
		X.[Password],
		X.[CreatedOn],
		X.[LockedOn],
		X.[FacebookId],
		X.[GmailId],
		X.[Version]
	FROM
	(
		SELECT TOP 1
			X.[Id],
			E.[Id]	[EmplacementId],
			X.[Code],
			X.[Password],
			X.[CreatedOn],
			X.[LockedOn],
			X.[FacebookId],
			X.[GmailId],
			X.[Version]
		FROM
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',			'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Emplacement')									[Emplacement],
				X.[Entity].value('(Code/text())[1]',		'NVARCHAR(MAX)')	[Code],
				X.[Entity].value('(Password/text())[1]',	'NVARCHAR(MAX)')	[Password],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('CreatedOn'))	[CreatedOn],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('LockedOn'))	[LockedOn],
				X.[Entity].value('(FacebookId/text())[1]',	'NVARCHAR(MAX)')	[FacebookId],
				X.[Entity].value('(GmailId/text())[1]',		'NVARCHAR(MAX)')	[GmailId],
				X.[Entity].value('(Version/text())[1]',		'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)																X
		OUTER APPLY [Security].[Emplacement.Entity](X.[Emplacement])	E
	)								X
	LEFT JOIN	[Security].[User]	XI	ON	X.[Id]				= XI.[UserId]
	LEFT JOIN	[Security].[User]	XEC	ON	X.[EmplacementId]	= XEC.[UserEmplacementId]	AND
											X.[Code]			= XEC.[UserCode]
	LEFT JOIN	[Security].[User]	XEF	ON	X.[EmplacementId]	= XEF.[UserEmplacementId]	AND
											X.[FacebookId]		= XEF.[UserFacebookId]
	LEFT JOIN	[Security].[User]	XEG	ON	X.[EmplacementId]	= XEG.[UserEmplacementId]	AND
											X.[GmailId]			= XEG.[UserGmailId]
)
GO
