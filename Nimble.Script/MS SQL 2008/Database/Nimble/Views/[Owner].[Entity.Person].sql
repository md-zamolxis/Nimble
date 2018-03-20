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
			O.[name]	= 'Entity.Person'))
	DROP VIEW [Owner].[Entity.Person];
GO

CREATE VIEW [Owner].[Entity.Person]
AS
SELECT * FROM [Owner].[Person]				P
INNER JOIN	[Security].[Emplacement]		E	ON	P.[PersonEmplacementId]		= E.[EmplacementId]
LEFT JOIN	[Security].[User]				U	ON	P.[PersonUserId]			= U.[UserId]
LEFT JOIN	[Common].[Entity.Filestream]	F	ON	P.[PersonId]				= F.[FilestreamEntityId]	AND
													F.[FilestreamIsDefault]		= 1
GO
