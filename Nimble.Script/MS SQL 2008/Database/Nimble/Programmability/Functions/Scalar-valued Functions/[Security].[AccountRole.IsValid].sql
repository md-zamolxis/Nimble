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
			O.[name]	= 'CK_AccountRole_AccountId_RoleId'))
	ALTER TABLE [Security].[AccountRole] DROP CONSTRAINT [CK_AccountRole_AccountId_RoleId];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Security'	AND
			O.[type]	= 'FN'			AND
			O.[name]	= 'AccountRole.IsValid'))
	DROP FUNCTION [Security].[AccountRole.IsValid];
GO

CREATE FUNCTION [Security].[AccountRole.IsValid]
(
	@accountId	UNIQUEIDENTIFIER,
	@roleId		UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (NOT EXISTS (
			SELECT * FROM [Security].[Account]	A
			INNER JOIN	[Security].[User]		U	ON	A.[AccountUserId]			= U.[UserId]
			INNER JOIN	[Security].[Role]		R	ON	A.[AccountApplicationId]	= R.[RoleApplicationId]	AND
														U.[UserEmplacementId]		= R.[RoleEmplacementId]
			WHERE 
				A.[AccountId]	= @accountId	AND
				R.[RoleId]		= @roleId
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Security].[AccountRole] WITH CHECK ADD CONSTRAINT [CK_AccountRole_AccountId_RoleId] CHECK ((
	[Security].[AccountRole.IsValid]
	(
		[AccountRoleAccountId],
		[AccountRoleRoleId]
	)=(1)
))
GO

ALTER TABLE [Security].[AccountRole] CHECK CONSTRAINT [CK_AccountRole_AccountId_RoleId]
GO
