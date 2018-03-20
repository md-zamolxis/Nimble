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
			O.[name]	= 'Flags.NumberIsEqual'))
	DROP FUNCTION [Common].[Flags.NumberIsEqual];
GO

CREATE FUNCTION [Common].[Flags.NumberIsEqual]
(
	@value		INT,
	@number		INT,
	@isExact	BIT
)
RETURNS BIT
AS
BEGIN
	DECLARE @isEqual BIT = 0;
	IF ((@isExact = 0 AND @value ^ @number < @value + @number) OR
		(@isExact = 1 AND @value = @number)
	) SET @isEqual = 1;
	RETURN @isEqual;
END
GO
