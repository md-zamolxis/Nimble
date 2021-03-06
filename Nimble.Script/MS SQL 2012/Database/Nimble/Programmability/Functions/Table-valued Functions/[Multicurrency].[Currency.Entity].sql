SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multicurrency'	AND
			O.[type]	= 'IF'				AND
			O.[name]	= 'Currency.Entity'))
	DROP FUNCTION [Multicurrency].[Currency.Entity];
GO

CREATE FUNCTION [Multicurrency].[Currency.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[CurrencyId], XOC.[CurrencyId], XOD.[CurrencyId])	[Id],
		X.[OrganisationId],
		X.[Code],
		X.[CreatedOn],
		X.[Description],
		X.[IsDefault],
		X.[LockedOn],
		X.[Version]
	FROM
	(
		SELECT TOP 1
			X.[Id],
			O.[Id]	[OrganisationId],
			X.[Code],
			X.[CreatedOn],
			X.[Description],
			X.[IsDefault],
			X.[LockedOn],
			X.[Version]
		FROM
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',					'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Organisation')							       		[Organisation],
				X.[Entity].value('(Code/text())[1]',				'NVARCHAR(MAX)')	[Code],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('CreatedOn'))			[CreatedOn],
				X.[Entity].value('(Description/text())[1]',			'NVARCHAR(MAX)')	[Description],
				ISNULL(X.[Entity].value('(IsDefault/text())[1]',	'BIT'), 0)			[IsDefault],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('LockedOn'))			[LockedOn],
				X.[Entity].value('(Version/text())[1]',				'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)															X
		OUTER APPLY [Owner].[Organisation.Entity](X.[Organisation])	O
	)										X
	LEFT JOIN	[Multicurrency].[Currency]	XI	ON	X.[Id]				= XI.[CurrencyId]
	LEFT JOIN	[Multicurrency].[Currency]	XOC	ON	X.[OrganisationId]	= XOC.[CurrencyOrganisationId]	AND
													X.[Code]			= XOC.[CurrencyCode]
	LEFT JOIN	[Multicurrency].[Currency]	XOD	ON	X.[IsDefault]		= 1								AND
													X.[OrganisationId]	= XOD.[CurrencyOrganisationId]	AND
													X.[IsDefault]		= XOD.[CurrencyIsDefault]
)
GO
