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
			O.[name]	= 'Xml.IsEmpty'))
	DROP FUNCTION [Common].[Xml.IsEmpty];
GO

CREATE FUNCTION [Common].[Xml.IsEmpty](@value XML)
RETURNS BIT
AS
BEGIN
	DECLARE @isNumeric BIT = 0;
	IF (LEN(CAST(@value AS NVARCHAR(MAX))) = 0)
		SET @isNumeric = 1;
	RETURN @isNumeric;
END
GO
