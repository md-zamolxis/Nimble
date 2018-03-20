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
			O.[name]	= 'Flags.LineIsEqual'))
	DROP FUNCTION [Common].[Flags.LineIsEqual];
GO

CREATE FUNCTION [Common].[Flags.LineIsEqual]
(
	@value		NVARCHAR(MAX),
	@line		NVARCHAR(MAX),
	@isExact	BIT
)
RETURNS BIT
AS
BEGIN
	DECLARE 
		@isEqual	BIT	= 0,
		@index		INT	= 0,
		@length		INT;
	SELECT @length = MIN(LEN(ISNULL(X.[Parameter], 0))) 
	FROM (SELECT @value [Parameter] UNION SELECT @line [Parameter]) X;
	IF (@isExact = 0) BEGIN
		WHILE (@index < @length) BEGIN 
			IF (CAST(SUBSTRING(@value, @length - @index, 1) AS INT) * 
				CAST(SUBSTRING(@line, @length - @index, 1) AS INT) > 0) 
			BEGIN
				SET @isEqual = 1;
				BREAK;
			END
			SET @index = @index + 1;
		END
	END
	ELSE IF (@isExact = 1 AND @value = @line) 
		SET @isEqual = 1;
	RETURN @isEqual;
END
GO
