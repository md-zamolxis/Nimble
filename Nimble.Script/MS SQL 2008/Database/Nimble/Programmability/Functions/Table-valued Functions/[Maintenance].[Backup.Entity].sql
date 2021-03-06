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
			O.[name]	= 'Backup.Entity'))
	DROP FUNCTION [Maintenance].[Backup.Entity];
GO

CREATE FUNCTION [Maintenance].[Backup.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		XI.[BackupId]	[Id],
		X.[Start],
		X.[End],
		X.[Data],
		X.[Destination],
		X.[Size]
	FROM
	(
		SELECT
			X.[Entity].value('(Id/text())[1]',			'UNIQUEIDENTIFIER')	[Id],
			[Common].[DateTimeOffset.Entity](X.[Entity].query('Start'))		[Start],
			[Common].[DateTimeOffset.Entity](X.[Entity].query('End'))		[End],
			X.[Entity].value('(Data/text())[1]',		'INT')				[Data],
			X.[Entity].value('(Destination/text())[1]',	'NVARCHAR(MAX)')	[Destination],
			X.[Entity].value('(Size/text())[1]',		'INT')				[Size]
		FROM @entity.nodes('/*') X ([Entity])
	)									X
	LEFT JOIN	[Maintenance].[Backup]	XI	ON	X.[Id]	= XI.[BackupId]
)
GO
