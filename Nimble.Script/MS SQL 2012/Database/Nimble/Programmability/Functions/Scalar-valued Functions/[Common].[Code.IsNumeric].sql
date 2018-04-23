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
			O.[name]	= 'Code.IsNumeric'))
	DROP FUNCTION [Common].[Code.IsNumeric];
GO

CREATE FUNCTION [Common].[Code.IsNumeric](@value NVARCHAR(MAX))
RETURNS BIT
AS
BEGIN
	DECLARE @isNumeric BIT = 0;
	IF (ISNUMERIC(@value) = 1 AND LEN(@value) < 10 AND @value LIKE '%[0-9]%') 
		SET @isNumeric = 1;
	RETURN @isNumeric;
END
GO
