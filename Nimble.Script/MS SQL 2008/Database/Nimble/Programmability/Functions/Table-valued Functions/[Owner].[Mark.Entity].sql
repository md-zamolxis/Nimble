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
			O.[name]	= 'Mark.Entity'))
	DROP FUNCTION [Owner].[Mark.Entity];
GO

CREATE FUNCTION [Owner].[Mark.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[MarkId], XPETE.[MarkId])	[Id],
		X.[PersonId],
		X.[MarkEntityType],
		X.[EntityId],
		X.[CreatedOn],
		X.[UpdatedOn],
		X.[MarkActionType],
		X.[Comment],
		X.[Settings]
	FROM 
	(
		SELECT TOP 1
			X.[Id],
			P.[Id]	[PersonId],
			X.[MarkEntityType],
			X.[EntityId],
			X.[CreatedOn],
			X.[UpdatedOn],
			X.[MarkActionType],
			X.[Comment],
			X.[Settings]
		FROM 
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',				'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Person')											[Person],
				X.[Entity].value('(MarkEntityType/text())[1]',	'NVARCHAR(MAX)')	[MarkEntityType],
				X.[Entity].value('(EntityId/text())[1]',		'UNIQUEIDENTIFIER')	[EntityId],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('CreatedOn'))		[CreatedOn],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('UpdatedOn'))		[UpdatedOn],
				X.[Entity].value('(MarkActionType/text())[1]',	'NVARCHAR(MAX)')	[MarkActionType],
				X.[Entity].value('(Comment/text())[1]',			'NVARCHAR(MAX)')	[Comment],
				X.[Entity].query('Settings/*')										[Settings]
			FROM @entity.nodes('/*') X ([Entity])
		)												X
		OUTER APPLY [Owner].[Person.Entity](X.[Person])	P
	)							X
	LEFT JOIN	[Owner].[Mark]	XI		ON	X.[Id]				= XI.[MarkId]
	LEFT JOIN	[Owner].[Mark]	XPETE	ON	X.[PersonId]		= XPETE.[MarkPersonId]		AND
											X.[MarkEntityType]	= XPETE.[MarkEntityType]	AND
											X.[EntityId]		= XPETE.[MarkEntityId]
)
GO
