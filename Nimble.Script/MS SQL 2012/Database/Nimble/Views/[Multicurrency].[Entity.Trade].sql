SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multicurrency'	AND
			O.[type]	= 'V'			AND
			O.[name]	= 'Entity.Trade'))
	DROP VIEW [Multicurrency].[Entity.Trade];
GO

CREATE VIEW [Multicurrency].[Entity.Trade]
AS
SELECT * FROM [Multicurrency].[Trade]		T
INNER JOIN	[Owner].[Organisation]		O	ON	T.[TradeOrganisationId]			= O.[OrganisationId]
INNER JOIN	[Security].[Emplacement]	E	ON	O.[OrganisationEmplacementId]	= E.[EmplacementId]
GO
