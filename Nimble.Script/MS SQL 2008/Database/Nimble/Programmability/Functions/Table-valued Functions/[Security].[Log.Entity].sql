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
			O.[name]	= 'Log.Entity'))
	DROP FUNCTION [Security].[Log.Entity];
GO

CREATE FUNCTION [Security].[Log.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		XI.[LogId]	[Id],
		X.[ApplicationId],
		X.[AccountId],
		X.[TokenId],
		X.[CreatedOn],
		X.[LogActionType],
		X.[Comment],
		X.[Parameters]
	FROM
	(
		SELECT TOP 1
			X.[Id],
			A.[Id]	[ApplicationId],
			AC.[Id]	[AccountId],
			X.[TokenId],
			X.[CreatedOn],
			X.[LogActionType],
			X.[Comment],
			X.[Parameters]
		FROM
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',				'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Application')										[Application],
				X.[Entity].query('Account')											[Account],
				X.[Entity].value('(TokenId/text())[1]',			'UNIQUEIDENTIFIER')	[TokenId],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('CreatedOn'))		[CreatedOn],
				X.[Entity].value('(LogActionType/text())[1]',	'NVARCHAR(MAX)')	[LogActionType],
				X.[Entity].value('(Comment/text())[1]',			'NVARCHAR(MAX)')	[Comment],
				X.[Entity].query('(Parameters/string)')								[Parameters]
			FROM @entity.nodes('/*') X ([Entity])
		)																X
		OUTER APPLY [Security].[Application.Entity](X.[Application])	A
		OUTER APPLY [Security].[Account.Entity](X.[Account])			AC
	)								X
	LEFT JOIN	[Security].[Log]	XI	ON	X.[Id]	= XI.[LogId]
)
GO
