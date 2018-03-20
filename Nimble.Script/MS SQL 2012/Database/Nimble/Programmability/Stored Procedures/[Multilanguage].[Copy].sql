SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	R
		INNER JOIN	[sys].[objects]		O	ON	R.[schema_id]	= O.[schema_id]
		WHERE 
			R.[name]	= 'Multilanguage'	AND
			O.[type]	= 'P'				AND
			O.[name]	= 'Copy'))
	DROP PROCEDURE [Multilanguage].[Copy];
GO

CREATE PROCEDURE [Multilanguage].[Copy]
(
	@emplacement	XML,
	@application	XML
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE 
		@emplacementId	UNIQUEIDENTIFIER,
		@applicationId	UNIQUEIDENTIFIER,
		@dateTimeOffset	DATETIMEOFFSET;

	SELECT
		@emplacementId	= E.[Id],
		@applicationId	= A.[Id],
		@dateTimeOffset	= SYSDATETIMEOFFSET()
	FROM [Security].[Emplacement.Entity](@emplacement) E, [Security].[Application.Entity](@application) A;

	BEGIN TRANSACTION;
	BEGIN TRY
	
		IF (@emplacementId IS NOT NULL) BEGIN
		
			WITH X AS (
				SELECT
					@emplacementId			[CultureEmplacementId],
					C.[CultureCode],
					MAX(C.[CultureName])	[CultureName]
				FROM [Multilanguage].[Culture] C
				WHERE C.[CultureEmplacementId] <> @emplacementId
				GROUP BY C.[CultureCode]
				UNION
				SELECT
					@emplacementId			[CultureEmplacementId],
					MAX(C.[CultureCode])	[CultureCode],
					C.[CultureName]
				FROM [Multilanguage].[Culture] C
				WHERE C.[CultureEmplacementId] <> @emplacementId
				GROUP BY C.[CultureName]
			)
			INSERT [Multilanguage].[Culture] 
			(
				[CultureEmplacementId],
				[CultureCode],
				[CultureName]
			)
			SELECT X.* FROM							X
			LEFT JOIN	[Multilanguage].[Culture]	C	ON	X.[CultureEmplacementId]	= C.[CultureEmplacementId]	AND
													(
														X.[CultureCode]	= C.[CultureCode]	OR
														X.[CultureName]	= C.[CultureName]
													)
			WHERE C.[CultureId] IS NULL;

			IF (@applicationId IS NOT NULL) BEGIN
			
				WITH X AS (
					SELECT
						@emplacementId			[ResourceEmplacementId],
						@applicationId			[ResourceApplicationId],
						R.[ResourceCode],
						R.[ResourceCategory],
						@dateTimeOffset			[ResourceCreatedOn],
						@dateTimeOffset			[ResourceLastUsedOn]
					FROM 
					(
						SELECT DISTINCT
							R.[ResourceCode],
							R.[ResourceCategory]
						FROM [Multilanguage].[Resource] R
						WHERE 
							R.[ResourceEmplacementId]	<> @emplacementId AND
							R.[ResourceApplicationId]	<> @applicationId
					)	R
				)
				INSERT [Multilanguage].[Resource] 
				(
					[ResourceEmplacementId],
					[ResourceApplicationId],
					[ResourceCode],
					[ResourceCategory],
					[ResourceCreatedOn],
					[ResourceLastUsedOn]
				)
				SELECT X.* FROM							X
				LEFT JOIN	[Multilanguage].[Resource]	R	ON	X.[ResourceEmplacementId]	= R.[ResourceEmplacementId]	AND
																X.[ResourceApplicationId]	= R.[ResourceApplicationId]	AND
																X.[ResourceCode]			= R.[ResourceCode]			AND
																X.[ResourceCategory]		= R.[ResourceCategory]
				WHERE R.[ResourceId] IS NULL;
				
				WITH X AS (
					SELECT
						RT.[ResourceId]	[TranslationResourceId],
						CT.[CultureId]	[TranslationCultureId],
						MAX(T.[TranslationSense])	[TranslationSense]
					FROM [Multilanguage].[Translation]		T
					INNER JOIN	[Multilanguage].[Resource]	RF	ON	T.[TranslationResourceId]	= RF.[ResourceId]
					INNER JOIN	[Multilanguage].[Culture]	CF	ON	T.[TranslationCultureId]	= CF.[CultureId]				AND
																	RF.[ResourceEmplacementId]	= CF.[CultureEmplacementId]
					INNER JOIN	[Multilanguage].[Resource]	RT	ON	@emplacementId				= RT.[ResourceEmplacementId]	AND
																	@applicationId				= RT.[ResourceApplicationId]	AND
																	RF.[ResourceCode]			= RT.[ResourceCode]				AND
																	RF.[ResourceCategory]		= RT.[ResourceCategory]
					INNER JOIN	[Multilanguage].[Culture]	CT	ON	@emplacementId				= CT.[CultureEmplacementId]		AND
																	(
																		CF.[CultureCode]	= CT.[CultureCode]	OR
																		CF.[CultureName]	= CT.[CultureName]
																	)
					WHERE 
						RF.[ResourceEmplacementId]	<> @emplacementId AND
						RF.[ResourceApplicationId]	<> @applicationId
					GROUP BY 
						RT.[ResourceId],
						CT.[CultureId]
				)
				INSERT [Multilanguage].[Translation] 
				(
					[TranslationResourceId],
					[TranslationCultureId],
					[TranslationSense]
				)
				SELECT X.* FROM								X
				LEFT JOIN	[Multilanguage].[Translation]	T	ON	X.[TranslationResourceId]	= T.[TranslationResourceId]	AND
																	X.[TranslationCultureId]	= T.[TranslationCultureId]
				WHERE T.[TranslationId] IS NULL;
				
			END
			
		END
		
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		EXEC [Error].[General.Throw];
	END CATCH;	

END
GO
