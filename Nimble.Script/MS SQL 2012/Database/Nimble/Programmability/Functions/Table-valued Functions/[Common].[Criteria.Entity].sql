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
			O.[name]	= 'Criteria.Entity'))
	DROP FUNCTION [Common].[Criteria.Entity];
GO

CREATE FUNCTION [Common].[Criteria.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN
(
	SELECT 
		@entity																[Criteria],
		@entity.exist('/*/*')												[CriteriaExist],
		ISNULL([Common].[Bool.Entity](@entity.query('/*/IsExcluded')), 0)	[CriteriaIsExcluded],
		ISNULL([Common].[Bool.Entity](@entity.query('/*/IsNull')), 0)		[CriteriaIsNull],
		@entity.query('/*/Value')											[CriteriaValue],
		@entity.exist('/*/Value/*')											[CriteriaValueExist]
)
GO
