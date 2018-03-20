SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Geolocation'	AND
			O.[type]	= 'FN'			AND
			O.[name]	= 'IpValue.Entity'))
	DROP FUNCTION [Geolocation].[IpValue.Entity];
GO

CREATE FUNCTION [Geolocation].[IpValue.Entity](@ipNumber BIGINT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE 
		@ipValue		NVARCHAR(MAX),
		@subnetMask		INT,
		@ipDelimiter	NVARCHAR(MAX),
		@index			INT,
		@subnetOrder	BIGINT,
		@number			BIGINT;
	SELECT 
		@ipValue		= '',
		@subnetMask		= 256,
		@ipDelimiter	= '.',
		@index			= CAST(LOG(@ipNumber)/LOG(@subnetMask) AS INT);
	WHILE (@index >= 0) BEGIN
		SELECT 
			@subnetOrder	= POWER(@subnetMask, @index),
			@number			= @ipNumber / @subnetOrder,
			@ipValue		= @ipValue + CAST(@number AS NVARCHAR(MAX)),
			@ipNumber		= @ipNumber - @number * @subnetOrder,
			@index			= @index - 1;
		IF (@index >= 0)
			SET @ipValue = @ipValue + @ipDelimiter;
	END
	RETURN @ipValue;
END
GO
