SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner.Branch'	AND
			O.[type]	= 'V'				AND
			O.[name]	= 'Entity.Bond'))
	DROP VIEW [Owner.Branch].[Entity.Bond];
GO

CREATE VIEW [Owner.Branch].[Entity.Bond]
AS
SELECT * FROM [Owner.Branch].[Group]	G
INNER JOIN	[Owner.Branch].[Split]		S	ON	G.[GroupSplitId]				= S.[SplitId]
INNER JOIN	[Owner].[Organisation]		O	ON	S.[SplitOrganisationId]			= O.[OrganisationId]
INNER JOIN	[Security].[Emplacement]	E	ON	O.[OrganisationEmplacementId]	= E.[EmplacementId]
INNER JOIN	[Owner].[Branch]			B	ON	S.[SplitOrganisationId]			= B.[BranchOrganisationId]
GO
