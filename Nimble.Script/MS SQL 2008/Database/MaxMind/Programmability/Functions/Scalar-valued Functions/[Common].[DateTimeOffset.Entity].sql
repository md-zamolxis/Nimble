SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'FN'		AND
			O.[name]	= 'DateTimeOffset.Entity'))
	DROP FUNCTION [Common].[DateTimeOffset.Entity];
GO

CREATE FUNCTION [Common].[DateTimeOffset.Entity](@entity XML)
RETURNS DATETIMEOFFSET 
AS
BEGIN
	DECLARE 
		@dateTimeOffset DATETIMEOFFSET,
		@offsetMinutes	INT;
	SELECT 
		@dateTimeOffset	= X.[Entity].value('(DateTime/text())[1]',				'DATETIMEOFFSET'),
		@offsetMinutes	= ISNULL(X.[Entity].value('(OffsetMinutes/text())[1]',	'INT'), 0)
	FROM @entity.nodes('/*') X ([Entity]);
	RETURN SWITCHOFFSET(@dateTimeOffset, @offsetMinutes);
END
GO
