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
			O.[name]	= 'State.Entity'))
	DROP FUNCTION [Common].[State.Entity];
GO

CREATE FUNCTION [Common].[State.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		[Common].[DateTimeOffset.Entity](X.[Entity].query('From'))										[From],
		[Common].[DateTimeOffset.Entity](X.[Entity].query('To'))										[To],
		ISNULL([Common].[DateTimeOffset.Entity](X.[Entity].query('AppliedOn')), SYSDATETIMEOFFSET())	[AppliedOn],
		X.[Entity].value('(IsActive/text())[1]',	'BIT')												[IsActive]
	FROM @entity.nodes('/*') X ([Entity])
)
GO
