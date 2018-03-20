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
			O.[name]	= 'Entity.Employee'))
	DROP VIEW [Owner].[Entity.Employee];
GO

CREATE VIEW [Owner].[Entity.Employee]
AS
SELECT * FROM [Owner].[Employee]			EM
INNER JOIN	[Owner].[Person]				P	ON	EM.[EmployeePersonId]		= P.[PersonId]
INNER JOIN	[Security].[Emplacement]		E	ON	P.[PersonEmplacementId]		= E.[EmplacementId]
LEFT JOIN	[Security].[User]				U	ON	P.[PersonUserId]			= U.[UserId]
INNER JOIN	[Owner].[Organisation]			O	ON	EM.[EmployeeOrganisationId]	= O.[OrganisationId]
LEFT JOIN	[Common].[Entity.Filestream]	F	ON	EM.[EmployeeId]				= F.[FilestreamEntityId]	AND
													F.[FilestreamIsDefault]		= 1
GO
