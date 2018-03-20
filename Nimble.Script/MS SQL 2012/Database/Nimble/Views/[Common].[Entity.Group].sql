SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'V'		AND
			O.[name]	= 'Entity.Group'))
	DROP VIEW [Common].[Entity.Group];
GO

CREATE VIEW [Common].[Entity.Group]
AS
SELECT * FROM [Common].[Group]			G
INNER JOIN	[Common].[Split]			S	ON	G.[GroupSplitId]		= S.[SplitId]
INNER JOIN	[Security].[Emplacement]	E	ON	S.[SplitEmplacementId]	= E.[EmplacementId]
GO
