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
			O.[name]	= 'Entity.Permission'))
	DROP VIEW [Security].[Entity.Permission];
GO

CREATE VIEW [Security].[Entity.Permission]
AS
SELECT * FROM [Security].[Permission]	P
INNER JOIN	[Security].[Application]	A	ON	P.[PermissionApplicationId]	= A.[ApplicationId]
GO
