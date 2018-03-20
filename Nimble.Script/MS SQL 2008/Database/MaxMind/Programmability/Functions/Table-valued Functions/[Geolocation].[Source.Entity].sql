SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Geolocation'	AND
			O.[type]	= 'IF'			AND
			O.[name]	= 'Source.Entity'))
	DROP FUNCTION [Geolocation].[Source.Entity];
GO

CREATE FUNCTION [Geolocation].[Source.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[SourceId], XC.[SourceId])	[Id],
		X.[Code],
		X.[SourceInputType],
		X.[Description],
		X.[CreatedOn],
		X.[ApprovedOn],
		X.[Input],
		X.[InputLength],
		X.[EntriesLoaded],
		X.[Errors],
		X.[ErrorsLoaded],
		X.[Version]
	FROM 
	(
		SELECT
			X.[Entity].value('(Id/text())[1]',								'UNIQUEIDENTIFIER')	[Id],
			X.[Entity].value('(Code/text())[1]',							'NVARCHAR(MAX)')	[Code],
			X.[Entity].value('(SourceInputType/text())[1]',					'NVARCHAR(MAX)')	[SourceInputType],
			X.[Entity].value('(Description/text())[1]',						'NVARCHAR(MAX)')	[Description],
			[Common].[DateTimeOffset.Entity](X.[Entity].query('CreatedOn'))						[CreatedOn],
			[Common].[DateTimeOffset.Entity](X.[Entity].query('ApprovedOn'))					[ApprovedOn],
			X.[Entity].value('(Input/text())[1]',							'VARBINARY(MAX)')	[Input],
			X.[Entity].value('(InputLength/text())[1]',						'BIGINT')			[InputLength],
			X.[Entity].value('(EntriesLoaded/text())[1]',					'BIGINT')			[EntriesLoaded],
			X.[Entity].value('(Errors/text())[1]',							'NVARCHAR(MAX)')	[Errors],
			X.[Entity].value('(ErrorsLoaded/text())[1]',					'BIGINT')			[ErrorsLoaded],
			X.[Entity].value('(Version/text())[1]',							'VARBINARY(MAX)')	[Version]
		FROM @entity.nodes('/*') X ([Entity])
	)									X
	LEFT JOIN	[Geolocation].[Source]	XI	ON	X.[Id]		= XI.[SourceId]
	LEFT JOIN	[Geolocation].[Source]	XC	ON	X.[Code]	= XC.[SourceCode]
)
GO
