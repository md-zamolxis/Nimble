SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Geolocation'	AND
			O.[type]	= 'V'			AND
			O.[name]	= 'Entity.Block'))
	DROP VIEW [Geolocation].[Entity.Block];
GO

CREATE VIEW [Geolocation].[Entity.Block]
AS
SELECT * FROM [Geolocation].[Block]		B
INNER JOIN	[Geolocation].[Location]	L	ON	B.[BlockLocationCode]	= L.[LocationCode]
GO
