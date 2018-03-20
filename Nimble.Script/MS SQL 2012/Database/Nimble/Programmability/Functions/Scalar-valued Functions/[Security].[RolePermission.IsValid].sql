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
			O.[name]	= 'CK_RolePermission_RoleId_PermissionId'))
	ALTER TABLE [Security].[RolePermission] DROP CONSTRAINT [CK_RolePermission_RoleId_PermissionId];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Security'	AND
			O.[type]	= 'FN'			AND
			O.[name]	= 'RolePermission.IsValid'))
	DROP FUNCTION [Security].[RolePermission.IsValid];
GO

CREATE FUNCTION [Security].[RolePermission.IsValid]
(
	@roleId			UNIQUEIDENTIFIER,
	@permissionId	UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (NOT EXISTS (
			SELECT * FROM [Security].[Role]		R
			INNER JOIN	[Security].[Permission]	P	ON	R.[RoleApplicationId]	= P.[PermissionApplicationId]
			WHERE 
				R.[RoleId]			= @roleId	AND
				P.[PermissionId]	= @permissionId
		) 
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Security].[RolePermission] WITH CHECK ADD CONSTRAINT [CK_RolePermission_RoleId_PermissionId] CHECK ((
	[Security].[RolePermission.IsValid]
	(
		[RolePermissionRoleId],
		[RolePermissionPermissionId]
	)=(1)
))
GO

ALTER TABLE [Security].[RolePermission] CHECK CONSTRAINT [CK_RolePermission_RoleId_PermissionId]
GO
