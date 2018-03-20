SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner'	AND
			O.[type]	= 'C'		AND
			O.[name]	= 'CK_Person_EmplacementId_UserId'))
	ALTER TABLE [Owner].[Person] DROP CONSTRAINT [CK_Person_EmplacementId_UserId];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner'	AND
			O.[type]	= 'FN'		AND
			O.[name]	= 'Person.IsValid'))
	DROP FUNCTION [Owner].[Person.IsValid];
GO

CREATE FUNCTION [Owner].[Person.IsValid]
(
	@emplacementId	UNIQUEIDENTIFIER,
	@userId			UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (@userId IS NOT NULL	AND
		NOT EXISTS 
		(
			SELECT * FROM [Security].[User]	U
			WHERE 
				U.[UserId]				= @userId	AND
				U.[UserEmplacementId]	= @emplacementId
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Owner].[Person] WITH CHECK ADD CONSTRAINT [CK_Person_EmplacementId_UserId] CHECK ((
	[Owner].[Person.IsValid]
	(
		[PersonEmplacementId],
		[PersonUserId]
	)=(1)
))
GO

ALTER TABLE [Owner].[Person] CHECK CONSTRAINT [CK_Person_EmplacementId_UserId]
GO
