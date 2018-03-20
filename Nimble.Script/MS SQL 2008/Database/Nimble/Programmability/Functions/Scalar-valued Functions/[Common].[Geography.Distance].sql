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
			O.[name]	= 'Geography.Distance'))
	DROP FUNCTION [Common].[Geography.Distance];
GO

CREATE FUNCTION [Common].[Geography.Distance](	
	@latitudeA	FLOAT,
	@longitudeA	FLOAT,
	@latitudeB	FLOAT,
	@longitudeB	FLOAT
)
RETURNS FLOAT 
AS
BEGIN
	DECLARE 
		@theta		FLOAT,
		@calculate	FLOAT;
	SET @latitudeA = PI() * @latitudeA / 180;
	SET @latitudeB = PI() * @latitudeB / 180;
	SET @theta = PI() * (@longitudeA - @longitudeB) / 180;
	SET @calculate = SIN(@latitudeA) * SIN(@latitudeB) + COS(@latitudeA) * COS(@latitudeB) * COS(@theta);
	SET @calculate = ACOS(@calculate);
	SET @calculate = @calculate * 180 / PI();
	SET @calculate = @calculate * 60 * 1.1515;
	RETURN @calculate;
END
GO
