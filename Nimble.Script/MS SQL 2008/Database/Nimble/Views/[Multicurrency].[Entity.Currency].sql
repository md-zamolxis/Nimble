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
			O.[name]	= 'Entity.Currency'))
	DROP VIEW [Multicurrency].[Entity.Currency];
GO

CREATE VIEW [Multicurrency].[Entity.Currency]
AS
SELECT * FROM [Multicurrency].[Currency]		C
INNER JOIN	[Owner].[Organisation]		O	ON	C.[CurrencyOrganisationId]		= O.[OrganisationId]
INNER JOIN	[Security].[Emplacement]	E	ON	O.[OrganisationEmplacementId]	= E.[EmplacementId]
GO
