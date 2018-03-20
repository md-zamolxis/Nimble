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
			O.[name]	= 'Location.Entity'))
	DROP FUNCTION [Geolocation].[Location.Entity];
GO

CREATE FUNCTION [Geolocation].[Location.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XC.[LocationCode], X.[Code]) [Code],
		X.[Country],
		X.[Region],
		X.[City],
		X.[PostalCode],
		X.[Latitude],
		X.[Longitude],
		X.[MetroCode],
		X.[AreaCode]
	FROM 
	(
		SELECT
			X.[Entity].value('(Code/text())[1]',		'BIGINT')			[Code],
			X.[Entity].value('(Country/text())[1]',		'NVARCHAR(MAX)')	[Country],
			X.[Entity].value('(Region/text())[1]',		'NVARCHAR(MAX)')	[Region],
			X.[Entity].value('(City/text())[1]',		'NVARCHAR(MAX)')	[City],
			X.[Entity].value('(PostalCode/text())[1]',	'NVARCHAR(MAX)')	[PostalCode],
			X.[Entity].value('(Latitude/text())[1]',	'MONEY')			[Latitude],
			X.[Entity].value('(Longitude/text())[1]',	'MONEY')			[Longitude],
			X.[Entity].value('(MetroCode/text())[1]',	'NVARCHAR(MAX)')	[MetroCode],
			X.[Entity].value('(AreaCode/text())[1]',	'NVARCHAR(MAX)')	[AreaCode]
		FROM @entity.nodes('/*') X ([Entity])
	)										X
	LEFT JOIN	[Geolocation].[Location]	XC	ON	X.[Code]	= XC.[LocationCode]
)
GO
