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
			O.[name]	= 'Entity.Culture'))
	DROP VIEW [Multilanguage].[Entity.Culture];
GO

CREATE VIEW [Multilanguage].[Entity.Culture]
AS
SELECT * FROM [Multilanguage].[Culture] C
INNER JOIN	[Security].[Emplacement]	E	ON	C.[CultureEmplacementId]	= E.[EmplacementId]
GO
