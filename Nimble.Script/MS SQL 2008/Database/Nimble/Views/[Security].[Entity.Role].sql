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
			O.[name]	= 'Entity.Role'))
	DROP VIEW [Security].[Entity.Role];
GO

CREATE VIEW [Security].[Entity.Role]
AS
SELECT * FROM [Security].[Role]			R
INNER JOIN	[Security].[Emplacement]	E	ON	R.[RoleEmplacementId]	= E.[EmplacementId]
INNER JOIN	[Security].[Application]	A	ON	R.[RoleApplicationId]	= A.[ApplicationId]
GO
