SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner'	AND
			O.[type]	= 'C'		AND
			O.[name]	= 'CK_Employee_PersonId_OrganisationId'))
	ALTER TABLE [Owner].[Employee] DROP CONSTRAINT [CK_Employee_PersonId_OrganisationId];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner'	AND
			O.[type]	= 'FN'		AND
			O.[name]	= 'Employee.IsValid'))
	DROP FUNCTION [Owner].[Employee.IsValid];
GO

CREATE FUNCTION [Owner].[Employee.IsValid]
(
	@personId			UNIQUEIDENTIFIER,
	@organisationId		UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (NOT EXISTS (
			SELECT * FROM [Owner].[Person]		P
			INNER JOIN	[Owner].[Organisation]	O	ON	P.[PersonEmplacementId]	= O.[OrganisationEmplacementId]
			WHERE 
				P.[PersonId]		= @personId	AND
				O.[OrganisationId]	= @organisationId
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Owner].[Employee] WITH CHECK ADD CONSTRAINT [CK_Employee_PersonId_OrganisationId] CHECK ((
	[Owner].[Employee.IsValid]
	(
		[EmployeePersonId],
		[EmployeeOrganisationId]
	)=(1)
))
GO

ALTER TABLE [Owner].[Employee] CHECK CONSTRAINT [CK_Employee_PersonId_OrganisationId]
GO
