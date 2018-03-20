SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Security'	AND
			O.[type]	= 'C'			AND
			O.[name]	= 'CK_Log_ApplicationId_AccountId'))
	ALTER TABLE [Security].[Log] DROP CONSTRAINT [CK_Log_ApplicationId_AccountId];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Security'	AND
			O.[type]	= 'FN'			AND
			O.[name]	= 'Log.IsValid'))
	DROP FUNCTION [Security].[Log.IsValid];
GO

CREATE FUNCTION [Security].[Log.IsValid]
(
	@applicationId	UNIQUEIDENTIFIER,
	@accountId		UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (@accountId IS NOT NULL AND
		NOT EXISTS (
			SELECT * FROM [Security].[Account] A
			WHERE 
				A.[AccountApplicationId]	= @applicationId	AND
				A.[AccountId]				= @accountId
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Security].[Log] WITH CHECK ADD CONSTRAINT [CK_Log_ApplicationId_AccountId] CHECK ((
	[Security].[Log.IsValid]
	(
		[LogApplicationId],
		[LogAccountId]
	)=(1)
))
GO

ALTER TABLE [Security].[Log] CHECK CONSTRAINT [CK_Log_ApplicationId_AccountId]
GO
