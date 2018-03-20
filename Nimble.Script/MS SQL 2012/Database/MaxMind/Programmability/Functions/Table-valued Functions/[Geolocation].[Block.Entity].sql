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
			O.[name]	= 'Block.Entity'))
	DROP FUNCTION [Geolocation].[Block.Entity];
GO

CREATE FUNCTION [Geolocation].[Block.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XF.[BlockIpNumberFrom],	XT.[BlockIpNumberFrom], X.[IpNumberFrom])	[IpNumberFrom],
		COALESCE(XF.[BlockIpNumberTo],		XT.[BlockIpNumberTo],	X.[IpNumberTo])		[IpNumberTo],
		X.[LocationCode],
		X.[IpDataFrom],
		X.[IpDataTo]
	FROM 
	(
		SELECT TOP 1
			ISNULL(X.[IpNumberFrom],	[Geolocation].[IpNumber.Entity](X.[IpDataFrom]))	[IpNumberFrom],
			ISNULL(X.[IpNumberTo],		[Geolocation].[IpNumber.Entity](X.[IpDataTo]))		[IpNumberTo],
			X.[LocationCode],
			ISNULL(X.[IpDataFrom],		[Geolocation].[IpValue.Entity](X.[IpNumberFrom]))	[IpDataFrom],
			ISNULL(X.[IpDataTo],		[Geolocation].[IpValue.Entity](X.[IpNumberTo]))		[IpDataTo]
		FROM (
			SELECT
				X.[Entity].value('(IpNumberFrom/text())[1]',	'BIGINT')			[IpNumberFrom],
				X.[Entity].value('(IpNumberTo/text())[1]',		'BIGINT')			[IpNumberTo],
				X.[Entity].value('(LocationCode/text())[1]',	'BIGINT')			[LocationCode],
				X.[Entity].value('(IpDataFrom/text())[1]',		'NVARCHAR(MAX)')	[IpDataFrom],
				X.[Entity].value('(IpDataTo/text())[1]',		'NVARCHAR(MAX)')	[IpDataTo]
			FROM @entity.nodes('/*') X ([Entity])
		) X
	)									X
	LEFT JOIN	[Geolocation].[Block]	XF	ON	X.[IpNumberFrom]	BETWEEN XF.[BlockIpNumberFrom] AND XF.[BlockIpNumberTo]
	LEFT JOIN	[Geolocation].[Block]	XT	ON	X.[IpNumberTo]		BETWEEN XT.[BlockIpNumberFrom] AND XT.[BlockIpNumberTo]
)
GO
