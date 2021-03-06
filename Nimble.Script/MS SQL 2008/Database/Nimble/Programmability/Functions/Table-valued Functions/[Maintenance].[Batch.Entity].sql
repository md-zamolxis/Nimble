SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Maintenance'	AND
			O.[type]	= 'IF'			AND
			O.[name]	= 'Batch.Entity'))
	DROP FUNCTION [Maintenance].[Batch.Entity];
GO

CREATE FUNCTION [Maintenance].[Batch.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		XI.[BatchId]	[Id],
		X.[Start],
		X.[End],
		X.[Before],
		X.[After],
		X.[MaximumFragmentation]
	FROM
	(
		SELECT
			X.[Entity].value('(Id/text())[1]',						'UNIQUEIDENTIFIER')	[Id],
			[Common].[DateTimeOffset.Entity](X.[Entity].query('Start'))					[Start],
			[Common].[DateTimeOffset.Entity](X.[Entity].query('End'))					[End],
			X.[Entity].value('(Before/text())[1]',					'INT')				[Before],
			X.[Entity].value('(After/text())[1]',					'INT')				[After],
			[Common].[Decimal.Entity](X.[Entity].query('MaximumFragmentation'))			[MaximumFragmentation]
		FROM @entity.nodes('/*') X ([Entity])
	)									X
	LEFT JOIN	[Maintenance].[Batch]	XI	ON	X.[Id]	= XI.[BatchId]
)
GO
