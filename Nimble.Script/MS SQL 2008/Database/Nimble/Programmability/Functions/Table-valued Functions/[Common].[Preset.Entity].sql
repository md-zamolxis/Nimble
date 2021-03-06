SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'IF'		AND
			O.[name]	= 'Preset.Entity'))
	DROP FUNCTION [Common].[Preset.Entity];
GO

CREATE FUNCTION [Common].[Preset.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[PresetId], XAETCC.[PresetId], XAETD.[PresetId])	[Id],
		X.[AccountId],
		X.[PresetEntityType],
		X.[Code],
		X.[Category],
		X.[Description],
		X.[Predicate],
		X.[IsDefault],
		X.[IsInstantly]
	FROM
	(
		SELECT TOP 1
			X.[Id],
			A.[Id]	[AccountId],
			X.[PresetEntityType],
			X.[Code],
			X.[Category],
			X.[Description],
			X.[Predicate],
			X.[IsDefault],
			X.[IsInstantly]
		FROM
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',					'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Account')												[Account],
				X.[Entity].value('(PresetEntityType/text())[1]',	'NVARCHAR(MAX)')	[PresetEntityType],
				X.[Entity].value('(Code/text())[1]',				'NVARCHAR(MAX)')	[Code],
				X.[Entity].value('(Category/text())[1]',			'INT')				[Category],
				X.[Entity].value('(Description/text())[1]',			'NVARCHAR(MAX)')	[Description],
				X.[Entity].value('(Predicate/text())[1]',			'NVARCHAR(MAX)')	[Predicate],
				ISNULL(X.[Entity].value('(IsDefault/text())[1]',	'BIT'), 0)			[IsDefault],
				ISNULL(X.[Entity].value('(IsInstantly/text())[1]',	'BIT'), 0)			[IsInstantly]
			FROM @entity.nodes('/*') X ([Entity])
		)														X
		OUTER APPLY [Security].[Account.Entity](X.[Account])	A
	)								X
	LEFT JOIN	[Common].[Preset]	XI		ON	X.[Id]					= XI.[PresetId]
	LEFT JOIN	[Common].[Preset]	XAETCC	ON	X.[AccountId]			= XAETCC.[PresetAccountId]	AND
												X.[PresetEntityType]	= XAETCC.[PresetEntityType]	AND
												X.[Code]				= XAETCC.[PresetCode]		AND
												(                                              
													X.[Category] = XAETCC.[PresetCategory]	OR
                                                    COALESCE(X.[Category], XAETCC.[PresetCategory]) IS NULL
												) 
	LEFT JOIN	[Common].[Preset]	XAETD	ON	X.[IsDefault]			= 1							AND
												X.[AccountId]			= XAETD.[PresetAccountId]	AND
												X.[PresetEntityType]	= XAETD.[PresetEntityType]	AND
												X.[IsDefault]			= XAETD.[PresetIsDefault]
)
GO
