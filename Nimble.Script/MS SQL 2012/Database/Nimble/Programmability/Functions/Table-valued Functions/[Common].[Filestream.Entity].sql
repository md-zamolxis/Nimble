SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'IF'		AND
			O.[name]	= 'Filestream.Entity'))
	DROP FUNCTION [Common].[Filestream.Entity];
GO

CREATE FUNCTION [Common].[Filestream.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[FilestreamId], XR.[FilestreamId], XEC.[FilestreamId], XED.[FilestreamId])	[Id],
		COALESCE
		(
			EP.[PersonEmplacementId],
			EO.[OrganisationEmplacementId],
			EE.[PersonEmplacementId],
			EE.[OrganisationEmplacementId],
			EB.[OrganisationEmplacementId],
			EBG.[OrganisationEmplacementId],
			ET.[OrganisationEmplacementId],
			ETG.[OrganisationEmplacementId]
		)																						[EmplacementId],
		COALESCE
		(
			EP.[PersonId],
			EE.[EmployeePersonId]
		)																						[PersonId],
		COALESCE
		(
			EO.[OrganisationId],
			EE.[EmployeeOrganisationId],
			EB.[BranchOrganisationId],
			EBG.[OrganisationId],
			ET.[PostOrganisationId],
			ETG.[OrganisationId]
		)																						[OrganisationId],
		X.[EntityId],
		X.[Code],
		X.[ReferenceId],
		X.[CreatedOn],              
		X.[Name],
		X.[Description],
		X.[Extension],
		X.[Data],
		X.[IsDefault],
		X.[Url],
		X.[ThumbnailId],
		X.[ThumbnailWidth],
		X.[ThumbnailHeight],
		X.[ThumbnailExtension],
		X.[ThumbnailUrl],
		X.[EntityActionType]
	FROM
	(
		SELECT
			X.[Entity].value('(Id/text())[1]',								'UNIQUEIDENTIFIER')	[Id],
			X.[Entity].value('(EntityId/text())[1]',						'UNIQUEIDENTIFIER')	[EntityId],
			X.[Entity].value('(Code/text())[1]',							'NVARCHAR(MAX)')	[Code],
			X.[Entity].value('(ReferenceId/text())[1]',						'UNIQUEIDENTIFIER')	[ReferenceId],
			[Common].[DateTimeOffset.Entity](X.[Entity].query('CreatedOn'))						[CreatedOn],
			X.[Entity].value('(Name/text())[1]',							'NVARCHAR(MAX)')	[Name],
			X.[Entity].value('(Description/text())[1]',						'NVARCHAR(MAX)')	[Description],
			X.[Entity].value('(Extension/text())[1]',						'NVARCHAR(MAX)')	[Extension],
			X.[Entity].value('(Data/text())[1]',							'VARBINARY(MAX)')	[Data],
			ISNULL(X.[Entity].value('(IsDefault/text())[1]',				'BIT'), 0)			[IsDefault],
			X.[Entity].value('(Url/text())[1]',								'NVARCHAR(MAX)')	[Url],
			X.[Entity].value('(ThumbnailId/text())[1]',						'UNIQUEIDENTIFIER')	[ThumbnailId],
			X.[Entity].value('(ThumbnailWidth/text())[1]',					'INT')				[ThumbnailWidth],
			X.[Entity].value('(ThumbnailHeight/text())[1]',					'INT')				[ThumbnailHeight],
			X.[Entity].value('(ThumbnailExtension/text())[1]',				'NVARCHAR(MAX)')	[ThumbnailExtension],
			X.[Entity].value('(ThumbnailUrl/text())[1]',					'NVARCHAR(MAX)')	[ThumbnailUrl],
			X.[Entity].value('(EntityActionType/text())[1]',				'NVARCHAR(MAX)')	[EntityActionType]
		FROM @entity.nodes('/*') X ([Entity])
	)									X
	LEFT JOIN	[Common].[Filestream]	XI	ON	X.[Id]			= XI.[FilestreamId]
	LEFT JOIN	[Common].[Filestream]	XR	ON	X.[ReferenceId]	= XR.[FilestreamReferenceId]
	LEFT JOIN	[Common].[Filestream]	XEC	ON	X.[EntityId]	= XEC.[FilestreamEntityId]	AND
												X.[Code]		= XEC.[FilestreamCode]
	LEFT JOIN	[Common].[Filestream]	XED	ON	X.[IsDefault]	= 1							AND
												X.[EntityId]	= XED.[FilestreamEntityId]	AND
                                                X.[IsDefault]	= XED.[FilestreamIsDefault]
	LEFT JOIN	[Owner].[Person]		EP	ON	X.[EntityId]	= EP.[PersonId]
	LEFT JOIN	[Owner].[Organisation]	EO	ON	X.[EntityId]	= EO.[OrganisationId]
	LEFT JOIN
	(
		SELECT * FROM [Owner].[Employee]	E
		INNER JOIN	[Owner].[Person]		P	ON	E.[EmployeePersonId]		= P.[PersonId]
		INNER JOIN	[Owner].[Organisation]	O	ON	E.[EmployeeOrganisationId]	= O.[OrganisationId]
	)									EE	ON	X.[EntityId]	= EE.[EmployeeId]
	LEFT JOIN
	(
		SELECT * FROM [Owner].[Branch]		B
		INNER JOIN	[Owner].[Organisation]	O	ON	B.[BranchOrganisationId]	= O.[OrganisationId]
	)									EB	ON	X.[EntityId]	= EB.[BranchId]
	LEFT JOIN
	(
		SELECT * FROM [Owner.Branch].[Group]	G
		INNER JOIN	[Owner.Branch].[Split]		S	ON	G.[GroupSplitId]		= S.[SplitId]
		INNER JOIN	[Owner].[Organisation]		O	ON	S.[SplitOrganisationId]	= O.[OrganisationId]
	)									EBG	ON	X.[EntityId]	= EBG.[GroupId]
	LEFT JOIN
	(
		SELECT * FROM [Owner].[Post]		P
		INNER JOIN	[Owner].[Organisation]	O	ON	P.[PostOrganisationId]	= O.[OrganisationId]
	)									ET	ON	X.[EntityId]	= ET.[PostId]
	LEFT JOIN
	(
		SELECT * FROM [Owner.Post].[Group]	G
		INNER JOIN	[Owner.Post].[Split]	S	ON	G.[GroupSplitId]		= S.[SplitId]
		INNER JOIN	[Owner].[Organisation]	O	ON	S.[SplitOrganisationId]	= O.[OrganisationId]
	)									ETG	ON	X.[EntityId]	= ETG.[GroupId]
)
GO
