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
			O.[name]	= 'Entity.Branch'))
	DROP VIEW [Owner].[Entity.Branch];
GO

CREATE VIEW [Owner].[Entity.Branch]
AS
SELECT * FROM [Owner].[Branch]				B
INNER JOIN	[Owner].[Organisation]			O	ON	B.[BranchOrganisationId]		= O.[OrganisationId]
INNER JOIN	[Security].[Emplacement]		E	ON	O.[OrganisationEmplacementId]	= E.[EmplacementId]
LEFT JOIN	[Common].[Entity.Filestream]	F	ON	B.[BranchId]					= F.[FilestreamEntityId]	AND
													F.[FilestreamIsDefault]			= 1
GO
