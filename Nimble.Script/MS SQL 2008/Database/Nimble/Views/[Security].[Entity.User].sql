SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Security'	AND
			O.[type]	= 'V'			AND
			O.[name]	= 'Entity.User'))
	DROP VIEW [Security].[Entity.User];
GO

CREATE VIEW [Security].[Entity.User]
AS
SELECT * FROM [Security].[User]			U
INNER JOIN	[Security].[Emplacement]	E	ON	U.[UserEmplacementId]	= E.[EmplacementId]
GO
