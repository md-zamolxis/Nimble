SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Maintenance'	AND
			O.[type]	= 'V'			AND
			O.[name]	= 'Entity.Operation'))
	DROP VIEW [Maintenance].[Entity.Operation];
GO

CREATE VIEW [Maintenance].[Entity.Operation]
AS
SELECT * FROM [Maintenance].[Operation]		O
INNER JOIN	[Maintenance].[Batch]			B	ON	O.[OperationBatchId]	= B.[BatchId]
GO
