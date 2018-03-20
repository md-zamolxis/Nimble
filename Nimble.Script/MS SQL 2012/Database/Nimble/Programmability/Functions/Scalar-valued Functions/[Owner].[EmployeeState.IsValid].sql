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
			O.[name]	= 'CK_EmployeeState_Id_EmployeeId_From_To'))
	ALTER TABLE [Owner].[EmployeeState] DROP CONSTRAINT [CK_EmployeeState_Id_EmployeeId_From_To];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner'	AND
			O.[type]	= 'FN'		AND
			O.[name]	= 'EmployeeState.IsValid'))
	DROP FUNCTION [Owner].[EmployeeState.IsValid];
GO

CREATE FUNCTION [Owner].[EmployeeState.IsValid]
(
	@id			UNIQUEIDENTIFIER,
	@employeeId	UNIQUEIDENTIFIER,
	@from		DATETIMEOFFSET,
	@to			DATETIMEOFFSET
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (EXISTS (
			SELECT * FROM [Owner].[EmployeeState] S
			WHERE 
				S.[EmployeeStateId]			<>	@id			AND
				S.[EmployeeStateEmployeeId]	=	@employeeId	AND 
				(
					(S.[EmployeeFrom] <= @from AND @from < S.[EmployeeTo])	OR
					(@from <= S.[EmployeeFrom] AND S.[EmployeeFrom] < @to)
				)
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Owner].[EmployeeState] WITH CHECK ADD CONSTRAINT [CK_EmployeeState_Id_EmployeeId_From_To] CHECK ((
	[Owner].[EmployeeState.IsValid]
	(
		[EmployeeStateId],
		[EmployeeStateEmployeeId],
		[EmployeeFrom],
		[EmployeeTo]
	)=(1)
))
GO

ALTER TABLE [Owner].[EmployeeState] CHECK CONSTRAINT [CK_EmployeeState_Id_EmployeeId_From_To]
GO
