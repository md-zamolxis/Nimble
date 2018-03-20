ALTER TABLE [Owner].[Range] DROP CONSTRAINT [CK_Range_BranchId_IpNumberFrom_IpNumberTo]
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner'	AND
			O.[type]	= 'FN'		AND
			O.[name]	= 'Range.IsValid'))
	DROP FUNCTION [Owner].[Range.IsValid];
GO

CREATE FUNCTION [Owner].[Range.IsValid]
(
	@id				UNIQUEIDENTIFIER,
	@branchId		UNIQUEIDENTIFIER,
	@ipNumberFrom	BIGINT,
	@ipNumberTo		BIGINT
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT;
	SET @isValid = 0;
	IF (EXISTS 
		(
			SELECT * FROM [Owner].[Range] R
			WHERE 
				R.[RangeBranchId] = @branchId AND 
				(
					(R.[RangeIpNumberFrom] BETWEEN @ipNumberFrom AND @ipNumberTo) OR
					(@ipNumberFrom BETWEEN R.[RangeIpNumberFrom] AND R.[RangeIpNumberTo])
				)	AND
				R.[RangeId]	<> @id
		)
	) SET @isValid = 1;
	RETURN @isValid;
END
GO

ALTER TABLE [Owner].[Range]  WITH CHECK ADD  CONSTRAINT [CK_Range_BranchId_IpNumberFrom_IpNumberTo] CHECK  (([Owner].[Range.IsValid]([RangeId],[RangeBranchId],[RangeIpNumberFrom],[RangeIpNumberTo])=(0)))
GO

ALTER TABLE [Owner].[Range] CHECK CONSTRAINT [CK_Range_BranchId_IpNumberFrom_IpNumberTo]
GO
