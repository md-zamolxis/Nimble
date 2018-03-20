SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multilanguage'	AND
			O.[type]	= 'C'				AND
			O.[name]	= 'CK_Translation_ResourceId_CultureId'))
	ALTER TABLE [Multilanguage].[Translation] DROP CONSTRAINT [CK_Translation_ResourceId_CultureId];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multilanguage'	AND
			O.[type]	= 'FN'				AND
			O.[name]	= 'Translation.IsValid'))
	DROP FUNCTION [Multilanguage].[Translation.IsValid];
GO

CREATE FUNCTION [Multilanguage].[Translation.IsValid]
(
	@resourceId	UNIQUEIDENTIFIER,
	@cultureId	UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (NOT EXISTS (
			SELECT * FROM [Multilanguage].[Resource]	R
			INNER JOIN	[Multilanguage].[Culture]		C	ON	R.[ResourceEmplacementId]	= C.[CultureEmplacementId]
			WHERE 
				R.[ResourceId]	= @resourceId	AND
				C.[CultureId]	= @cultureId
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Multilanguage].[Translation] WITH CHECK ADD CONSTRAINT [CK_Translation_ResourceId_CultureId] CHECK ((
	[Multilanguage].[Translation.IsValid]
	(
		[TranslationResourceId],
		[TranslationCultureId]
	)=(1)
))
GO

ALTER TABLE [Multilanguage].[Translation] CHECK CONSTRAINT [CK_Translation_ResourceId_CultureId]
GO
