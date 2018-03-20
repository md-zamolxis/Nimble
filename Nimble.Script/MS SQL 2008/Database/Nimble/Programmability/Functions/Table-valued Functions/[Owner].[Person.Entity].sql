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
			O.[name]	= 'Person.Entity'))
	DROP FUNCTION [Owner].[Person.Entity];
GO

CREATE FUNCTION [Owner].[Person.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[PersonId], XEC.[PersonId], XEI.[PersonId], XU.[PersonId], XEE.[PersonId])	[Id],
		X.[EmplacementId],
		X.[UserId],
		X.[Code],
		X.[IDNP],
		X.[FirstName],
		X.[LastName],
		X.[Patronymic],
		X.[BornOn],
		X.[PersonSexType],
		X.[Email],
		X.[LockedOn],
		X.[Settings],
		X.[Version]
	FROM 
	(
		SELECT TOP 1
			X.[Id],
			E.[Id]	[EmplacementId],
			U.[Id]	[UserId],
			X.[Code],
			X.[IDNP],
			X.[FirstName],
			X.[LastName],
			X.[Patronymic],
			X.[BornOn],
			X.[PersonSexType],
			X.[Email],
			X.[LockedOn],
			X.[Settings],
			X.[Version]
		FROM 
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',								'UNIQUEIDENTIFIER')				[Id],
				X.[Entity].query('Emplacement')																	[Emplacement],
				X.[Entity].query('User')																		[User],
				X.[Entity].value('(Code/text())[1]',							'NVARCHAR(MAX)')				[Code],
				X.[Entity].value('(IDNP/text())[1]',							'NVARCHAR(MAX)')				[IDNP],
				X.[Entity].value('(FirstName/text())[1]',						'NVARCHAR(MAX)')				[FirstName],
				X.[Entity].value('(LastName/text())[1]',						'NVARCHAR(MAX)')				[LastName],
				X.[Entity].value('(Patronymic/text())[1]',						'NVARCHAR(MAX)')				[Patronymic],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('BornOn'))									[BornOn],
				ISNULL(X.[Entity].value('(PersonSexType/text())[1]',			'NVARCHAR(MAX)'), 'Undefined')	[PersonSexType],
				X.[Entity].value('(Email/text())[1]',							'NVARCHAR(MAX)')				[Email],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('LockedOn'))									[LockedOn],
				X.[Entity].query('Settings/*')																	[Settings],
				X.[Entity].value('(Version/text())[1]',							'VARBINARY(MAX)')				[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)																X
		OUTER APPLY [Security].[Emplacement.Entity](X.[Emplacement])	E
		OUTER APPLY [Security].[User.Entity](X.[User])					U
	)								X
	LEFT JOIN	[Owner].[Person]	XI	ON	X.[Id]				= XI.[PersonId]
	LEFT JOIN	[Owner].[Person]	XEC	ON	X.[EmplacementId]	= XEC.[PersonEmplacementId]	AND
											X.[Code]			= XEC.[PersonCode]
	LEFT JOIN	[Owner].[Person]	XEI	ON	X.[EmplacementId]	= XEI.[PersonEmplacementId]	AND
											X.[IDNP]			= XEI.[PersonIDNP]
	LEFT JOIN	[Owner].[Person]	XU	ON	X.[UserId]			= XU.[PersonUserId]
	LEFT JOIN	[Owner].[Person]	XEE	ON	X.[EmplacementId]	= XEE.[PersonEmplacementId]	AND
											X.[Email]			= XEE.[PersonEmail]
)
GO
