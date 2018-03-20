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
			O.[name]	= 'Entity.Translation'))
	DROP VIEW [Multilanguage].[Entity.Translation];
GO

CREATE VIEW [Multilanguage].[Entity.Translation]
AS
SELECT * FROM [Multilanguage].[Resource]	R
INNER JOIN	[Security].[Emplacement]		E	ON	R.[ResourceEmplacementId]	= E.[EmplacementId]
INNER JOIN	[Security].[Application]		A	ON	R.[ResourceApplicationId]	= A.[ApplicationId]
INNER JOIN	[Multilanguage].[Culture]		C	ON	R.[ResourceEmplacementId]	= C.[CultureEmplacementId]
LEFT JOIN	[Multilanguage].[Translation]	T	ON	R.[ResourceId]				= T.[TranslationResourceId]	AND
													C.[CultureId]				= T.[TranslationCultureId]
GO
