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
			O.[name]	= 'CK_EmployeeBranch_EmployeeId_BranchId'))
	ALTER TABLE [Owner].[EmployeeBranch] DROP CONSTRAINT [CK_EmployeeBranch_EmployeeId_BranchId];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner'	AND
			O.[type]	= 'FN'		AND
			O.[name]	= 'EmployeeBranch.IsValid'))
	DROP FUNCTION [Owner].[EmployeeBranch.IsValid];
GO

CREATE FUNCTION [Owner].[EmployeeBranch.IsValid]
(
	@employeeId	UNIQUEIDENTIFIER,
	@branchId	UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (NOT EXISTS (
			SELECT * FROM [Owner].[Employee]	E
			INNER JOIN	[Owner].[Branch]		B	ON	E.[EmployeeOrganisationId]	= B.[BranchOrganisationId]
			WHERE 
				E.[EmployeeId]	= @employeeId	AND
				B.[BranchId]	= @branchId
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Owner].[EmployeeBranch] WITH CHECK ADD CONSTRAINT [CK_EmployeeBranch_EmployeeId_BranchId] CHECK ((
	[Owner].[EmployeeBranch.IsValid]
	(
		[EmployeeBranchEmployeeId],
		[EmployeeBranchBranchId]
	)=(1)
))
GO

ALTER TABLE [Owner].[EmployeeBranch] CHECK CONSTRAINT [CK_EmployeeBranch_EmployeeId_BranchId]
GO
