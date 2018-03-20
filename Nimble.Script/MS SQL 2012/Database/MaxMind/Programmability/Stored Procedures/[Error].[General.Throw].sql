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
			O.[name]	= 'General.Throw'))
	DROP PROCEDURE [Error].[General.Throw];
GO

CREATE PROCEDURE [Error].[General.Throw]
AS
BEGIN

	DECLARE 
		@errorMessage	NVARCHAR(MAX),
		@errorNumber	INT,
		@errorSeverity	INT,
		@errorState		INT,
		@errorLine		INT,
		@errorProcedure NVARCHAR(MAX) ;

	SELECT  
		@errorMessage	= N'Error %d, Level %d, State %d, Procedure %s, Line %d, Message: ' + ERROR_MESSAGE(),
		@errorNumber	= ERROR_NUMBER(), 
		@errorSeverity	= ERROR_SEVERITY(),
		@errorState		= ERROR_STATE(), 
		@errorLine		= ERROR_LINE(),
		@errorProcedure = ISNULL(ERROR_PROCEDURE(), '-');

	IF (@errorNumber IS NULL) RETURN;

	RAISERROR 
	(
		@errorMessage, 
		@errorSeverity, 
		1, 
		@errorNumber,
		@errorSeverity,
		@errorState,
		@errorProcedure,
		@errorLine
	);

END
GO
