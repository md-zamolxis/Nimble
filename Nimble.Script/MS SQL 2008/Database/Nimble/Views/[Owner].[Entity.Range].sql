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
			O.[name]	= 'Entity.Range'))
	DROP VIEW [Owner].[Entity.Range];
GO

CREATE VIEW [Owner].[Entity.Range]
AS
SELECT * FROM [Owner].[Range]			R
INNER JOIN	[Owner].[Branch]			B	ON	R.[RangeBranchId]				= B.[BranchId]
INNER JOIN	[Owner].[Organisation]		O	ON	B.[BranchOrganisationId]		= O.[OrganisationId]
INNER JOIN	[Security].[Emplacement]	E	ON	O.[OrganisationEmplacementId]	= E.[EmplacementId]
GO
