SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Security'	AND
			O.[type]	= 'IF'			AND
			O.[name]	= 'Account.Entity'))
	DROP FUNCTION [Security].[Account.Entity];
GO

CREATE FUNCTION [Security].[Account.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[AccountId], XUA.[AccountId])	[Id],
		X.[UserId],
		X.[ApplicationId],
		X.[LockedOn],
		X.[LastUsedOn],
		X.[Sessions],
		X.[Version]
	FROM
	(
		SELECT TOP 1
			X.[Id],
			U.[Id]	[UserId],
			A.[Id]	[ApplicationId],
			X.[LockedOn],
			X.[LastUsedOn],
			X.[Sessions],
			X.[Version]
		FROM
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',			'UNIQUEIDENTIFIER')		[Id],
				X.[Entity].query('User')											[User],
				X.[Entity].query('Application')										[Application],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('LockedOn'))		[LockedOn],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('LastUsedOn'))	[LastUsedOn],
				X.[Entity].value('(Sessions/text())[1]',	'INT')					[Sessions],
				X.[Entity].value('(Version/text())[1]',		'VARBINARY(MAX)')		[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)																X
		OUTER APPLY [Security].[User.Entity](X.[User])					U
		OUTER APPLY [Security].[Application.Entity](X.[Application])	A
	)									X
	LEFT JOIN	[Security].[Account]	XI	ON	X.[Id]				= XI.[AccountId]
	LEFT JOIN	[Security].[Account]	XUA	ON	X.[UserId]			= XUA.[AccountUserId]	AND
												X.[ApplicationId]	= XUA.[AccountApplicationId]
)
GO
