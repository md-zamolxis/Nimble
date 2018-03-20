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
			O.[name]	= 'Branch.Entity'))
	DROP FUNCTION [Owner].[Branch.Entity];
GO

CREATE FUNCTION [Owner].[Branch.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[BranchId], XOC.[BranchId])	[Id],
		X.[OrganisationId],
		X.[Code],
		X.[Name],
		X.[Description],
		X.[BranchActionType],
		X.[LockedOn],
		X.[Address],
		X.[Version]
	FROM 
	(
		SELECT TOP 1
			X.[Id],
			O.[Id]	[OrganisationId],
			X.[Code],
			X.[Name],
			X.[Description],
			X.[BranchActionType],
			X.[LockedOn],
			X.[Address],
			X.[Version]
		FROM 
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',									'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Organisation')									   					[Organisation],
				X.[Entity].value('(Code/text())[1]',								'NVARCHAR(MAX)')	[Code],
				X.[Entity].value('(Name/text())[1]',								'NVARCHAR(MAX)')	[Name],
				X.[Entity].value('(Description/text())[1]',							'NVARCHAR(MAX)')	[Description],
				ISNULL(X.[Entity].value('(BranchActionType/Number/text())[1]',		'INT'), 0)         	[BranchActionType],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('LockedOn'))							[LockedOn],
				X.[Entity].value('(Address/text())[1]',								'NVARCHAR(MAX)')	[Address],
				X.[Entity].value('(Version/text())[1]',								'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)															X
		OUTER APPLY [Owner].[Organisation.Entity](X.[Organisation])	O
	)								X
	LEFT JOIN	[Owner].[Branch]	XI	ON	X.[Id]				= XI.[BranchId]
	LEFT JOIN	[Owner].[Branch]	XOC	ON	X.[OrganisationId]	= XOC.[BranchOrganisationId]	AND
											X.[Code]			= XOC.[BranchCode]
)
GO
