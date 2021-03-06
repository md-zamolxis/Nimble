SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Error'	AND
			O.[type]	= 'P'		AND
			O.[name]	= 'EntityAction.Throw'))
	DROP PROCEDURE [Error].[EntityAction.Throw];
GO

CREATE PROCEDURE [Error].[EntityAction.Throw] (@number INT OUTPUT)
AS
BEGIN
	
	SET @number = @@ROWCOUNT;
	
	IF (@@ERROR	= 0 AND 
		@number	= 0)
		RAISERROR ('Entity not found or unmatched entity version - data was changed or removed from the previous read.', 16, 0);

END
GO
