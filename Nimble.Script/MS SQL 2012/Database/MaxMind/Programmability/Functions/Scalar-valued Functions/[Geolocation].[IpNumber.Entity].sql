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
			O.[name]	= 'IpNumber.Entity'))
	DROP FUNCTION [Geolocation].[IpNumber.Entity];
GO

CREATE FUNCTION [Geolocation].[IpNumber.Entity](@ipValue NVARCHAR(MAX))
RETURNS BIGINT
AS
BEGIN
	DECLARE 
		@ipNumber		BIGINT,
		@subnetMask		INT,
		@ipDelimiter	NVARCHAR(MAX),
		@numbers		XML,
		@index			INT;
	SELECT 
		@ipNumber		= 0,
		@subnetMask		= 256,
		@ipDelimiter	= '.',
		@numbers		= CAST('<longs><long>' + REPLACE(@ipValue, @ipDelimiter, '</long><long>') + '</long></longs>' AS XML);
	SELECT @index = COUNT(*) FROM [Common].[Long.Entities](@numbers);
	SELECT @ipNumber = @ipNumber + E.[long] * CAST(POWER(@subnetMask, E.[index]) AS BIGINT)
	FROM (
		SELECT 
			E.[long],
			@index - ROW_NUMBER() OVER (ORDER BY E.[index])	[index]
		FROM (
			SELECT 
				E.[long],
				@index	[index]
			FROM [Common].[Long.Entities](@numbers) E
		) E
	) E;
	RETURN @ipNumber;
END
GO
