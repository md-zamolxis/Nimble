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
			O.[name]	= 'Entity.Split'))
	DROP VIEW [Common].[Entity.Split];
GO

CREATE VIEW [Common].[Entity.Split]
AS
SELECT * FROM [Common].[Split]			S
INNER JOIN	[Security].[Emplacement]	E	ON	S.[SplitEmplacementId]	= E.[EmplacementId]
GO
