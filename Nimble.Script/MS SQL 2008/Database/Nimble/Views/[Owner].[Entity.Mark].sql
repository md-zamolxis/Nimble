SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner'	AND
			O.[type]	= 'V'		AND
			O.[name]	= 'Entity.Mark'))
	DROP VIEW [Owner].[Entity.Mark];
GO

CREATE VIEW [Owner].[Entity.Mark]
AS
SELECT * FROM [Owner].[Mark]			M	
INNER JOIN	[Owner].[Person]			P	ON	M.[MarkPersonId]		= P.[PersonId]
INNER JOIN	[Security].[Emplacement]	E	ON	P.[PersonEmplacementId]	= E.[EmplacementId]
LEFT JOIN	[Security].[User]			U	ON	P.[PersonUserId]		= U.[UserId]
GO
