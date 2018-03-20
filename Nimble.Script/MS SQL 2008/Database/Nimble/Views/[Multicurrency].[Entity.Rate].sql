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
			O.[name]	= 'Entity.Rate'))
	DROP VIEW [Multicurrency].[Entity.Rate];
GO

CREATE VIEW [Multicurrency].[Entity.Rate]
AS
SELECT * FROM [Multicurrency].[Rate]	R
INNER JOIN	[Multicurrency].[Trade]		T	ON	R.[RateTradeId]					= T.[TradeId]
INNER JOIN	[Owner].[Organisation]		O	ON	T.[TradeOrganisationId]			= O.[OrganisationId]
INNER JOIN	[Security].[Emplacement]	E	ON	O.[OrganisationEmplacementId]	= E.[EmplacementId]
INNER JOIN
(
	SELECT
		C.[CurrencyId]					[FromCurrencyId],
		C.[CurrencyOrganisationId]		[FromCurrencyOrganisationId],
		C.[CurrencyCode]				[FromCurrencyCode],
		C.[CurrencyDescription]			[FromCurrencyDescription],
		C.[CurrencyCreatedOn]			[FromCurrencyCreatedOn],
		C.[CurrencyLockedOn]			[FromCurrencyLockedOn],
		C.[CurrencyIsDefault]			[FromCurrencyIsDefault],
		C.[CurrencyVersion]				[FromCurrencyVersion],
		O.[OrganisationId]				[FromOrganisationId],
		O.[OrganisationEmplacementId]	[FromOrganisationEmplacementId],
		O.[OrganisationCode]			[FromOrganisationCode],
		O.[OrganisationIDNO]			[FromOrganisationIDNO],
		O.[OrganisationName]			[FromOrganisationName],
		O.[OrganisationCreatedOn]		[FromOrganisationCreatedOn],
		O.[OrganisationRegisteredOn]	[FromOrganisationRegisteredOn],
		O.[OrganisationActionType]		[FromOrganisationActionType],
		O.[OrganisationLockedOn]		[FromOrganisationLockedOn],
		O.[OrganisationLockedReason]	[FromOrganisationLockedReason],
		O.[OrganisationSettings]		[FromOrganisationSettings],
		O.[OrganisationVersion]			[FromOrganisationVersion],
		E.[EmplacementId]				[FromEmplacementId],
		E.[EmplacementCode]				[FromEmplacementCode],
		E.[EmplacementDescription]		[FromEmplacementDescription],
		E.[EmplacementIsAdministrative]	[FromEmplacementIsAdministrative],
		E.[EmplacementVersion]			[FromEmplacementVersion]
	FROM [Multicurrency].[Currency]			C
	INNER JOIN	[Owner].[Organisation]		O	ON	C.[CurrencyOrganisationId]		= O.[OrganisationId]
	INNER JOIN	[Security].[Emplacement]	E	ON	O.[OrganisationEmplacementId]	= E.[EmplacementId]
	
)										CF	ON	R.[RateCurrencyFrom]			= CF.[FromCurrencyId]
INNER JOIN
(
	SELECT
		C.[CurrencyId]					[ToCurrencyId],
		C.[CurrencyOrganisationId]		[ToCurrencyOrganisationId],
		C.[CurrencyCode]				[ToCurrencyCode],
		C.[CurrencyDescription]			[ToCurrencyDescription],
		C.[CurrencyCreatedOn]			[ToCurrencyCreatedOn],
		C.[CurrencyIsDefault]			[ToCurrencyIsDefault],
		C.[CurrencyLockedOn]			[ToCurrencyLockedOn],
		C.[CurrencyVersion]				[ToCurrencyVersion],
		O.[OrganisationId]				[ToOrganisationId],
		O.[OrganisationEmplacementId]	[ToOrganisationEmplacementId],
		O.[OrganisationCode]			[ToOrganisationCode],
		O.[OrganisationIDNO]			[ToOrganisationIDNO],
		O.[OrganisationName]			[ToOrganisationName],
		O.[OrganisationCreatedOn]		[ToOrganisationCreatedOn],
		O.[OrganisationRegisteredOn]	[ToOrganisationRegisteredOn],
		O.[OrganisationActionType]		[ToOrganisationActionType],
		O.[OrganisationLockedOn]		[ToOrganisationLockedOn],
		O.[OrganisationLockedReason]	[ToOrganisationLockedReason],
		O.[OrganisationSettings]		[ToOrganisationSettings],
		O.[OrganisationVersion]			[ToOrganisationVersion],
		E.[EmplacementId]				[ToEmplacementId],
		E.[EmplacementCode]				[ToEmplacementCode],
		E.[EmplacementDescription]		[ToEmplacementDescription],
		E.[EmplacementIsAdministrative]	[ToEmplacementIsAdministrative],
		E.[EmplacementVersion]			[ToEmplacementVersion]
	FROM [Multicurrency].[Currency]			C
	INNER JOIN	[Owner].[Organisation]		O	ON	C.[CurrencyOrganisationId]		= O.[OrganisationId]
	INNER JOIN	[Security].[Emplacement]	E	ON	O.[OrganisationEmplacementId]	= E.[EmplacementId]
)										CT	ON	R.[RateCurrencyTo]				= CT.[ToCurrencyId]
GO
