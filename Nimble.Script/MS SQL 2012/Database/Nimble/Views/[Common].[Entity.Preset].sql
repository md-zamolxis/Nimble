SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'V'		AND
			O.[name]	= 'Entity.Preset'))
	DROP VIEW [Common].[Entity.Preset];
GO

CREATE VIEW [Common].[Entity.Preset]
AS
SELECT * FROM [Common].[Preset]			P
INNER JOIN	[Security].[Account]		AC	ON	P.[PresetAccountId]			= AC.[AccountId]
INNER JOIN	[Security].[User]			U	ON	AC.[AccountUserId]			= U.[UserId]
INNER JOIN	[Security].[Emplacement]	E	ON	U.[UserEmplacementId]		= E.[EmplacementId]
INNER JOIN	[Security].[Application]	A	ON	AC.[AccountApplicationId]	= A.[ApplicationId]
GO
