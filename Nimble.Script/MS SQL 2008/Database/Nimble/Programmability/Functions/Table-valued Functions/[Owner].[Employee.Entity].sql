SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner'	AND
			O.[type]	= 'IF'		AND
			O.[name]	= 'Employee.Entity'))
	DROP FUNCTION [Owner].[Employee.Entity];
GO

CREATE FUNCTION [Owner].[Employee.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[EmployeeId], XOF.[EmployeeId], XOC.[EmployeeId], XOD.[EmployeeId])	[Id],
		X.[PersonId],
		X.[OrganisationId],
		X.[Code],
		X.[Function],
		X.[CreatedOn],
		X.[EmployeeActorType],
		X.[IsDefault],
		X.[Version]
	FROM 
	(
		SELECT TOP 1
			X.[Id],
			P.[Id]	[PersonId],
			O.[Id]	[OrganisationId],
			X.[Code],
			X.[Function],
			X.[CreatedOn],
			X.[EmployeeActorType],
			X.[IsDefault],
			X.[Version]
		FROM 
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',								'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Person')															[Person],
				X.[Entity].query('Organisation')													[Organisation],
				X.[Entity].value('(Code/text())[1]',							'NVARCHAR(MAX)')	[Code],
				X.[Entity].value('(Function/text())[1]',						'NVARCHAR(MAX)')	[Function],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('CreatedOn'))						[CreatedOn],
				X.[Entity].value('(EmployeeActorType/text())[1]',				'NVARCHAR(MAX)')	[EmployeeActorType],
				ISNULL(X.[Entity].value('(IsDefault/text())[1]',				'BIT'), 0)			[IsDefault],
				X.[Entity].value('(Version/text())[1]',							'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)															X
		OUTER APPLY [Owner].[Person.Entity](X.[Person])				P
		OUTER APPLY [Owner].[Organisation.Entity](X.[Organisation])	O
	)								X
	LEFT JOIN	[Owner].[Employee]	XI	ON	X.[Id]				= XI.[EmployeeId]
	LEFT JOIN	[Owner].[Employee]	XOF	ON	X.[PersonId]		= XOF.[EmployeePersonId]		AND
											X.[OrganisationId]  = XOF.[EmployeeOrganisationId]	AND
											X.[Function]		= XOF.[EmployeeFunction]
	LEFT JOIN	[Owner].[Employee]	XOC	ON	X.[OrganisationId]  = XOC.[EmployeeOrganisationId]	AND
											X.[Code]			= XOC.[EmployeeCode]
	LEFT JOIN	[Owner].[Employee]	XOD	ON	X.[IsDefault]		= 1								AND
											X.[OrganisationId]  = XOD.[EmployeeOrganisationId]	AND
											X.[IsDefault]		= XOD.[EmployeeIsDefault]
)
GO
