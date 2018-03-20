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
			O.[name]	= 'Entity.Log'))
	DROP VIEW [Security].[Entity.Log];
GO

CREATE VIEW [Security].[Entity.Log]
AS
SELECT * FROM [Security].[Log]			L
INNER JOIN	[Security].[Application]	A	ON	L.[LogApplicationId]	= A.[ApplicationId]
LEFT JOIN	[Security].[Account]		AC	ON	L.[LogAccountId]		= AC.[AccountId]
LEFT JOIN	[Security].[User]			U	ON	AC.[AccountUserId]		= U.[UserId]
LEFT JOIN	[Security].[Emplacement]	E	ON	U.[UserEmplacementId]	= E.[EmplacementId]

GO
