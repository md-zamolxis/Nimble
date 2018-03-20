SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multilanguage'	AND
			O.[type]	= 'V'				AND
			O.[name]	= 'Entity.Resource'))
	DROP VIEW [Multilanguage].[Entity.Resource];
GO

CREATE VIEW [Multilanguage].[Entity.Resource]
AS
SELECT * FROM [Multilanguage].[Resource]	R
INNER JOIN	[Security].[Emplacement]		E	ON	R.[ResourceEmplacementId]	= E.[EmplacementId]
INNER JOIN	[Security].[Application]		A	ON	R.[ResourceApplicationId]	= A.[ApplicationId]
GO
