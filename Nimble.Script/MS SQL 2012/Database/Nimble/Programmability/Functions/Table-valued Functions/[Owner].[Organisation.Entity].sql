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
			O.[name]	= 'Organisation.Entity'))
	DROP FUNCTION [Owner].[Organisation.Entity];
GO

CREATE FUNCTION [Owner].[Organisation.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[OrganisationId], XEC.[OrganisationId], XEI.[OrganisationId])	[Id],
		X.[EmplacementId],
		X.[Code],
		X.[IDNO],
		X.[Name],
		X.[CreatedOn],
		X.[RegisteredOn],
		X.[OrganisationActionType],
		X.[LockedOn],
		X.[LockedReason],
		X.[Settings],
		X.[Version]
	FROM 
	(
		SELECT TOP 1
			X.[Id],
			E.[Id]	[EmplacementId],
			X.[Code],
			X.[IDNO],
			X.[Name],
			X.[CreatedOn],
			X.[RegisteredOn],
			X.[OrganisationActionType],
			X.[LockedOn],
			X.[LockedReason],
			X.[Settings],
			X.[Version]
		FROM 
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',										'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Emplacement')																[Emplacement],
				X.[Entity].value('(Code/text())[1]',									'NVARCHAR(MAX)')	[Code],
				X.[Entity].value('(IDNO/text())[1]',									'NVARCHAR(MAX)')	[IDNO],
				X.[Entity].value('(Name/text())[1]',									'NVARCHAR(MAX)')	[Name],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('CreatedOn'))								[CreatedOn],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('RegisteredOn'))							[RegisteredOn],
				ISNULL(X.[Entity].value('(OrganisationActionType/Number/text())[1]',	'INT'), 0)         	[OrganisationActionType],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('LockedOn'))								[LockedOn],
				X.[Entity].value('(LockedReason/text())[1]',							'NVARCHAR(MAX)')	[LockedReason],
				X.[Entity].query('Settings/*')																[Settings],
				X.[Entity].value('(Version/text())[1]',									'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)																X
		OUTER APPLY [Security].[Emplacement.Entity](X.[Emplacement])	E
	)									X
	LEFT JOIN	[Owner].[Organisation]	XI	ON	X.[Id]				= XI.[OrganisationId]
	LEFT JOIN	[Owner].[Organisation]	XEC	ON	X.[EmplacementId]	= XEC.[OrganisationEmplacementId]	AND
												X.[Code]			= XEC.[OrganisationCode]
	LEFT JOIN	[Owner].[Organisation]	XEI	ON	X.[EmplacementId]	= XEI.[OrganisationEmplacementId]	AND
												X.[IDNO]			= XEI.[OrganisationIDNO]
)
GO
