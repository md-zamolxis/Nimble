SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Security].[Account](
	[AccountId] [uniqueidentifier] NOT NULL,
	[AccountUserId] [uniqueidentifier] NOT NULL,
	[AccountApplicationId] [uniqueidentifier] NOT NULL,
	[AccountLockedOn] [datetime] NULL,
	[AccountLastUsedOn] [datetime] NULL,
	[AccountVersion] [timestamp] NOT NULL,
 CONSTRAINT [PK_Account] PRIMARY KEY CLUSTERED 
(
	[AccountId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UK_Account_UserId_ApplicationId] UNIQUE NONCLUSTERED 
(
	[AccountUserId] ASC,
	[AccountApplicationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [Security].[Account] ADD  CONSTRAINT [DF_Account_AccountId]  DEFAULT (newsequentialid()) FOR [AccountId]
GO

ALTER TABLE [Security].[Account]  WITH CHECK ADD CONSTRAINT [FK_Account_Application] FOREIGN KEY([AccountApplicationId])
REFERENCES [Security].[Application] ([ApplicationId])
GO

ALTER TABLE [Security].[Account] CHECK CONSTRAINT [FK_Account_Application]
GO

ALTER TABLE [Security].[Account]  WITH CHECK ADD CONSTRAINT [FK_Account_User] FOREIGN KEY([AccountUserId])
REFERENCES [Security].[User] ([UserId])
GO

ALTER TABLE [Security].[Account] CHECK CONSTRAINT [FK_Account_User]
GO

CREATE FUNCTION [Security].[AccountRole.IsValid]
(
	@accountId	UNIQUEIDENTIFIER,
	@roleId		UNIQUEIDENTIFIER
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT;
	SET @isValid = 0;
	IF EXISTS 
	(
		SELECT * FROM [Security].[Account]	A
		INNER JOIN	[Security].[User]		U	ON	A.[AccountUserId]			= U.[UserId]
		INNER JOIN	[Security].[Role]		R	ON	A.[AccountApplicationId]	= R.[RoleApplicationId]	AND
													U.[UserEmplacementId]		= R.[RoleEmplacementId]
		WHERE 
			A.[AccountId]	= @accountId	AND
			R.[RoleId]		= @roleId
	) SET @isValid = 1;
	RETURN @isValid;
END
GO

CREATE TABLE [Security].[AccountRole](
	[AccountRoleAccountId] [uniqueidentifier] NOT NULL,
	[AccountRoleRoleId] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_AccountRole] PRIMARY KEY CLUSTERED 
(
	[AccountRoleAccountId] ASC,
	[AccountRoleRoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [Security].[AccountRole]  WITH CHECK ADD CONSTRAINT [FK_AccountRole_Role] FOREIGN KEY([AccountRoleRoleId])
REFERENCES [Security].[Role] ([RoleId])
GO

ALTER TABLE [Security].[AccountRole] CHECK CONSTRAINT [FK_AccountRole_Role]
GO

ALTER TABLE [Security].[AccountRole]  WITH CHECK ADD CONSTRAINT [FK_AccountRole_Account] FOREIGN KEY([AccountRoleAccountId])
REFERENCES [Security].[Account] ([AccountId])
GO

ALTER TABLE [Security].[AccountRole] CHECK CONSTRAINT [FK_AccountRole_Account]
GO

ALTER TABLE [Security].[AccountRole]  WITH CHECK ADD CONSTRAINT [CK_AccountRole_AccountId_RoleId] CHECK  (([Security].[AccountRole.IsValid]([AccountRoleAccountId],[AccountRoleRoleId])=(1)))
GO

ALTER TABLE [Security].[AccountRole] CHECK CONSTRAINT [CK_AccountRole_AccountId_RoleId]
GO

INSERT [Security].[Account]
( 
	 [AccountId]
	,[AccountUserId]
	,[AccountApplicationId]
	,[AccountLockedOn]
	,[AccountLastUsedOn]
)
SELECT 
	 UA.[UserApplicationId],
	 UA.[UserApplicationUserId],
	 UA.[UserApplicationApplicationId],
	 UA.[UserApplicationLockedOn],
	 UA.[UserApplicationLastUsedOn]
FROM [Security].[UserApplication] UA;
GO

INSERT [Security].[AccountRole] SELECT * FROM [Security].[UserApplicationRole];
GO

ALTER TABLE [Security].[Log] DROP CONSTRAINT [CK_Log_ApplicationId_UserApplicationId];
GO

EXECUTE sp_rename N'Security.[Log].LogUserApplicationId', N'Tmp_LogAccountId_4', 'COLUMN' 
GO
EXECUTE sp_rename N'Security.[Log].Tmp_LogAccountId_4', N'LogAccountId', 'COLUMN' 
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
	DECLARE @isValid BIT;
	SET @isValid = 1;
	IF (@accountId IS NOT NULL AND
		NOT EXISTS 
		(
			SELECT * FROM [Security].[Account] A
			WHERE 
				A.[AccountApplicationId]	= @applicationId	AND
				A.[AccountId]				= @accountId
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Security].[Log]  WITH CHECK ADD CONSTRAINT [CK_Log_ApplicationId_AccountId] CHECK  (([Security].[Log.IsValid]([LogApplicationId],[LogAccountId])=(1)))
GO

ALTER TABLE [Security].[Log] CHECK CONSTRAINT [CK_Log_ApplicationId_AccountId]
GO

ALTER TABLE [Security].[Log]  WITH CHECK ADD CONSTRAINT [FK_Log_Account] FOREIGN KEY([LogAccountId])
REFERENCES [Security].[Account] ([AccountId])
GO

ALTER TABLE [Security].[Log] CHECK CONSTRAINT [FK_Log_Account]
GO

EXECUTE sp_rename N'Common.Preset.PresetUserApplicationId', N'Tmp_PresetAccountId_5', 'COLUMN' 
GO
EXECUTE sp_rename N'Common.Preset.Tmp_PresetAccountId_5', N'PresetAccountId', 'COLUMN' 
GO

ALTER TABLE [Common].[Preset]  WITH CHECK ADD CONSTRAINT [FK_Preset_Account] FOREIGN KEY([PresetAccountId])
REFERENCES [Security].[Account] ([AccountId])
GO

ALTER TABLE [Common].[Preset] CHECK CONSTRAINT [FK_Preset_Account];
GO

ALTER TABLE [Common].[Preset] DROP CONSTRAINT [UK_Preset_UserApplicationId_PresetEntityType_Code];
GO

ALTER TABLE [Common].[Preset] ADD  CONSTRAINT [UK_Preset_AccountId_PresetEntityType_Code] UNIQUE NONCLUSTERED 
(
	[PresetAccountId] ASC,
	[PresetEntityType] ASC,
	[PresetCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

DROP INDEX [UI_Preset_UserApplicationId_PresetEntityType_IsDefault] ON [Common].[Preset];
GO

CREATE UNIQUE NONCLUSTERED INDEX [UI_Preset_AccountId_PresetEntityType_IsDefault] ON [Common].[Preset]
(
	[PresetAccountId] ASC,
	[PresetEntityType] ASC
)
WHERE ([PresetIsDefault]=(1))
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

DROP TABLE [Security].[UserApplicationRole];
GO

ALTER TABLE [Security].[Log] DROP CONSTRAINT [FK_Log_UserApplication];
GO

ALTER TABLE [Common].[Preset] DROP CONSTRAINT [FK_Preset_UserApplication];
GO

DROP TABLE [Security].[UserApplication];
GO

/*
Run this script on:

        EN30327\MSSQL2008E.Nimble    -  This database will be modified

to synchronize it with:

        80.245.81.59\MSSQL2008E, 50003.Nimble

You are recommended to back up your database before running this script

Script created by SQL Compare version 8.1.0 from Red Gate Software Ltd at 18/02/2013 14:21:12

*/
SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#tmpErrors')) DROP TABLE #tmpErrors
GO
CREATE TABLE #tmpErrors (Error int)
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
GO
PRINT N'Dropping [Security].[UserApplication.Action]'
GO
DROP PROCEDURE [Security].[UserApplication.Action]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Dropping [Security].[UserApplication.Filter]'
GO
DROP PROCEDURE [Security].[UserApplication.Filter]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Dropping [Security].[UserApplication.Entities]'
GO
DROP FUNCTION [Security].[UserApplication.Entities]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Dropping [Security].[UserApplication.Entity]'
GO
DROP FUNCTION [Security].[UserApplication.Entity]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Dropping [Security].[UserApplicationRole.IsValid]'
GO
DROP FUNCTION [Security].[UserApplicationRole.IsValid]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Dropping [Security].[Entity.UserApplication]'
GO
DROP VIEW [Security].[Entity.UserApplication]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Security].[Entity.Account]'
GO

CREATE VIEW [Security].[Entity.Account]
AS
SELECT * FROM [Security].[User]			U
INNER JOIN	[Security].[Emplacement]	E	ON	U.[UserEmplacementId]	= E.[EmplacementId]
CROSS JOIN	[Security].[Application]	A
LEFT JOIN	[Security].[Account]		AC	ON	U.[UserId]				= AC.[AccountUserId]	AND
												A.[ApplicationId]		= AC.[AccountApplicationId]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Common].[Entity.Preset]'
GO

ALTER VIEW [Common].[Entity.Preset]
AS
SELECT * FROM [Common].[Preset]			P
INNER JOIN	[Security].[Account]		AC	ON	P.[PresetAccountId]			= AC.[AccountId]
INNER JOIN	[Security].[User]			U	ON	AC.[AccountUserId]			= U.[UserId]
INNER JOIN	[Security].[Emplacement]	E	ON	U.[UserEmplacementId]		= E.[EmplacementId]
INNER JOIN	[Security].[Application]	A	ON	AC.[AccountApplicationId]	= A.[ApplicationId]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Security].[Entity.Log]'
GO

ALTER VIEW [Security].[Entity.Log]
AS
SELECT * FROM [Security].[Log]			L
INNER JOIN	[Security].[Application]	A	ON	L.[LogApplicationId]	= A.[ApplicationId]
LEFT JOIN	[Security].[Account]		AC	ON	L.[LogAccountId]		= AC.[AccountId]
LEFT JOIN	[Security].[User]			U	ON	AC.[AccountUserId]		= U.[UserId]
LEFT JOIN	[Security].[Emplacement]	E	ON	U.[UserEmplacementId]	= E.[EmplacementId]

GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Security].[Account.Entity]'
GO

CREATE FUNCTION [Security].[Account.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(AI.[AccountId], AUA.[AccountId])	[Id],
		X.[UserId],
		X.[ApplicationId],
		X.[LockedOn],
		X.[LastUsedOn],
		X.[Version]
	FROM
	(
		SELECT 
			X.[Id],
			U.[Id]	[UserId],
			A.[Id]	[ApplicationId],
			X.[LockedOn],
			X.[LastUsedOn],
			X.[Version]
		FROM
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',						'UNIQUEIDENTIFIER')					[Id],
				X.[Entity].query('User')																	[User],
				X.[Entity].query('Application')																[Application],
				CAST(LEFT(X.[Entity].value('(LockedOn/text())[1]',		'NVARCHAR(MAX)'), 19) AS DATETIME)	[LockedOn],
				CAST(LEFT(X.[Entity].value('(LastUsedOn/text())[1]',	'NVARCHAR(MAX)'), 19) AS DATETIME)	[LastUsedOn],
				X.[Entity].value('(Version/text())[1]',					'VARBINARY(MAX)')					[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)																X
		OUTER APPLY [Security].[User.Entity](X.[User])					U
		OUTER APPLY [Security].[Application.Entity](X.[Application])	A
	)									X
	LEFT JOIN	[Security].[Account]	AI	ON	X.[Id]				= AI.[AccountId]
	LEFT JOIN	[Security].[Account]	AUA	ON	X.[UserId]			= AUA.[AccountUserId]	AND
												X.[ApplicationId]	= AUA.[AccountApplicationId]
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Security].[Account.Entities]'
GO

CREATE FUNCTION [Security].[Account.Entities](@entities XML)
RETURNS TABLE 
AS
RETURN
(
	SELECT E.[Id] FROM
	(
		SELECT X.[Entity].query('.') [Account]
		FROM @entities.nodes('/*') X ([Entity])
	) X CROSS APPLY [Security].[Account.Entity](X.[Account]) E
	WHERE E.[Id] IS NOT NULL
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Common].[Preset.Entity]'
GO

ALTER FUNCTION [Common].[Preset.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		LI.[PresetId]	[Id],
		X.[AccountId],
		X.[PresetEntityType],
		X.[Code],
		X.[Predicate],
		X.[IsDefault],
		X.[IsInstantly]
	FROM
	(
		SELECT 
			X.[Id],
			A.[Id]	[AccountId],
			X.[PresetEntityType],
			X.[Code],
			X.[Predicate],
			X.[IsDefault],
			X.[IsInstantly]
		FROM
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',					'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Account')												[Account],
				X.[Entity].value('(PresetEntityType/text())[1]',	'NVARCHAR(MAX)')	[PresetEntityType],
				X.[Entity].value('(Code/text())[1]',				'NVARCHAR(MAX)')	[Code],
				X.[Entity].value('(Predicate/text())[1]',			'NVARCHAR(MAX)')	[Predicate],
				X.[Entity].value('(IsDefault/text())[1]',			'BIT')				[IsDefault],
				X.[Entity].value('(IsInstantly/text())[1]',			'BIT')				[IsInstantly]
			FROM @entity.nodes('/*') X ([Entity])
		)														X
		OUTER APPLY [Security].[Account.Entity](X.[Account])	A
	)								X
	LEFT JOIN	[Common].[Preset]	LI	ON	X.[Id]	= LI.[PresetId]
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Security].[Account.Filter]'
GO

CREATE PROCEDURE [Security].[Account.Filter]
(
	@predicate		XML,
	@emplacementId	UNIQUEIDENTIFIER	= NULL,
	@applicationId	UNIQUEIDENTIFIER	= NULL,
	@organisations	BIT					= 0,
	@isIncluded		BIT							OUTPUT,
	@isFiltered		BIT							OUTPUT,
	@number			INT							OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE 
		@dateFrom	DATETIME,
		@dateTo		DATETIME;
	
	SET @isFiltered = 0;

--	Filter by locked datetime
	SELECT @dateFrom = NULL, @dateTo = NULL;
	SELECT 
		@dateFrom	= X.[DateFrom], 
		@dateTo		= X.[DateTo] 
	FROM [Common].[DateInterval.Entity](@predicate.query('/*/LockedOn/Value')) X;
	IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL) BEGIN 
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/LockedOn/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#account] SELECT 
					A.[UserId],
					A.[ApplicationId]
				FROM [Security].[Entity.Account] A
				WHERE A.[AccountLockedOn] BETWEEN ISNULL(@dateFrom, A.[AccountLockedOn]) AND ISNULL(@dateTo, A.[AccountLockedOn]);
			ELSE 
				INSERT [#account] SELECT 
					A.[UserId],
					A.[ApplicationId]
				FROM [Security].[Entity.Account] A
				WHERE A.[AccountLockedOn] NOT BETWEEN ISNULL(@dateFrom, A.[AccountLockedOn]) AND ISNULL(@dateTo, A.[AccountLockedOn]);
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#account]	X
				LEFT JOIN
				(
					SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account] A
					WHERE A.[AccountLockedOn] BETWEEN ISNULL(@dateFrom, A.[AccountLockedOn]) AND ISNULL(@dateTo, A.[AccountLockedOn])
				)							A	ON	X.[UserId]			= A.[UserId]	AND
													X.[ApplicationId]	= A.[ApplicationId]
				WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
			ELSE
				DELETE X FROM [#account]	X
				LEFT JOIN
				(
					SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account] A
					WHERE A.[AccountLockedOn] NOT BETWEEN ISNULL(@dateFrom, A.[AccountLockedOn]) AND ISNULL(@dateTo, A.[AccountLockedOn])
				)							A	ON	X.[UserId]			= A.[UserId]	AND
													X.[ApplicationId]	= A.[ApplicationId]
				WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by locked datetime
	SELECT @dateFrom = NULL, @dateTo = NULL;
	SELECT 
		@dateFrom	= X.[DateFrom], 
		@dateTo		= X.[DateTo] 
	FROM [Common].[DateInterval.Entity](@predicate.query('/*/LastUsedOn/Value')) X;
	IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL) BEGIN 
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/LastUsedOn/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#account] SELECT 
					A.[UserId],
					A.[ApplicationId]
				FROM [Security].[Entity.Account] A
				WHERE A.[AccountLastUsedOn] BETWEEN ISNULL(@dateFrom, A.[AccountLastUsedOn]) AND ISNULL(@dateTo, A.[AccountLastUsedOn]);
			ELSE 
				INSERT [#account] SELECT 
					A.[UserId],
					A.[ApplicationId]
				FROM [Security].[Entity.Account] A
				WHERE A.[AccountLastUsedOn] NOT BETWEEN ISNULL(@dateFrom, A.[AccountLastUsedOn]) AND ISNULL(@dateTo, A.[AccountLastUsedOn]);
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#account]	X
				LEFT JOIN
				(
					SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account] A
					WHERE A.[AccountLastUsedOn] BETWEEN ISNULL(@dateFrom, A.[AccountLastUsedOn]) AND ISNULL(@dateTo, A.[AccountLastUsedOn])
				)							A	ON	X.[UserId]			= A.[UserId]	AND
													X.[ApplicationId]	= A.[ApplicationId]
				WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
			ELSE
				DELETE X FROM [#account]	X
				LEFT JOIN
				(
					SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account] A
					WHERE A.[AccountLastUsedOn] NOT BETWEEN ISNULL(@dateFrom, A.[AccountLastUsedOn]) AND ISNULL(@dateTo, A.[AccountLastUsedOn])
				)							A	ON	X.[UserId]			= A.[UserId]	AND
													X.[ApplicationId]	= A.[ApplicationId]
				WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by entities
	DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
	INSERT @entities SELECT DISTINCT * FROM [Security].[Account.Entities](@predicate.query('/*/Accounts/Value/Account'));
	IF (@@ROWCOUNT > 0) BEGIN
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/Accounts/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#account] SELECT 
					A.[UserId],
					A.[ApplicationId]
				FROM [Security].[Entity.Account]	A
				INNER JOIN	@entities				X	ON	A.[AccountId]	= X.[Id];
			ELSE
				INSERT [#account] SELECT 
					A.[UserId],
					A.[ApplicationId]
				FROM [Security].[Entity.Account]	A
				LEFT JOIN	@entities				X	ON	A.[AccountId]	= X.[Id]
				WHERE X.[Id] IS NULL;
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#account]	X
				LEFT JOIN
				(
					SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account]	A
					INNER JOIN	@entities				X	ON	A.[AccountId]	= X.[Id]
				)							A	ON	X.[UserId]			= A.[UserId]	AND
													X.[ApplicationId]	= A.[ApplicationId]
				WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
			ELSE
				DELETE X FROM [#account]	X
				LEFT JOIN
				(
					SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account]	A
					LEFT JOIN	@entities				X	ON	A.[AccountId]	= X.[Id]
					WHERE X.[Id] IS NULL
				)							A	ON	X.[UserId]			= A.[UserId]	AND
												X.[ApplicationId]	= A.[ApplicationId]
				WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by user predicate
	DECLARE 
		@userPredicate	XML,
		@userIsFiltered	BIT,
		@userNumber		INT;
	SELECT 
		@userPredicate	= @predicate.query('/*/UserPredicate'),
		@userIsFiltered	= @predicate.exist('/*/UserPredicate/*');
	IF (@userIsFiltered = 1) BEGIN
		CREATE TABLE [#user] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC [Security].[User.Filter]
			@predicate		= @userPredicate, 
			@isIncluded		= @isIncluded		OUTPUT,
			@isFiltered		= @userIsFiltered	OUTPUT,
			@number			= @userNumber		OUTPUT;
		IF (@userIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isIncluded = 1)
					INSERT [#account] SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account]	A
					INNER JOIN	[#user]					X	ON	A.[AccountUserId]	= X.[Id];
				ELSE
					INSERT [#account] SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account]	A
					LEFT JOIN	[#user]					X	ON	A.[AccountUserId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isIncluded = 1)
					DELETE X FROM [#account]	X
					LEFT JOIN
					(
						SELECT 
							A.[UserId],
							A.[ApplicationId]
						FROM [Security].[Entity.Account]	A
						INNER JOIN	[#user]					X	ON	A.[AccountUserId]	= X.[Id]
					)							A	ON	X.[UserId]			= A.[UserId]	AND
														X.[ApplicationId]	= A.[ApplicationId]
					WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
				ELSE
					DELETE X FROM [#account]	X
					LEFT JOIN
					(
						SELECT 
							A.[UserId],
							A.[ApplicationId]
						FROM [Security].[Entity.Account]	A
						LEFT JOIN	[#user]					X	ON	A.[AccountUserId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)							A	ON	X.[UserId]			= A.[UserId]	AND
														X.[ApplicationId]	= A.[ApplicationId]
					WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by application predicate
	DECLARE 
		@applicationPredicate	XML,
		@applicationIsFiltered	BIT,
		@applicationNumber		INT;
	SELECT 
		@applicationPredicate	= @predicate.query('/*/ApplicationPredicate'),
		@applicationIsFiltered	= @predicate.exist('/*/ApplicationPredicate/*');
	IF (@applicationIsFiltered = 1) BEGIN
		CREATE TABLE [#application] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC [Security].[Application.Filter]
			@predicate		= @applicationPredicate, 
			@isIncluded		= @isIncluded				OUTPUT,
			@isFiltered		= @applicationIsFiltered	OUTPUT,
			@number			= @applicationNumber		OUTPUT;
		IF (@applicationIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isIncluded = 1)
					INSERT [#account] SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account]	A
					INNER JOIN	[#application]			X	ON	A.[ApplicationId]	= X.[Id];
				ELSE
					INSERT [#account] SELECT 
						A.[UserId],
						A.[ApplicationId]
					FROM [Security].[Entity.Account]	A
					LEFT JOIN	[#application]			X	ON	A.[ApplicationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isIncluded = 1)
					DELETE X FROM [#account]	X
					LEFT JOIN
					(
						SELECT 
							A.[UserId],
							A.[ApplicationId]
						FROM [Security].[Entity.Account]	A
						INNER JOIN	[#application]			X	ON	A.[ApplicationId]	= X.[Id]
					)							A	ON	X.[UserId]			= A.[UserId]	AND
														X.[ApplicationId]	= A.[ApplicationId]
					WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
				ELSE
					DELETE X FROM [#account]	X
					LEFT JOIN
					(
						SELECT 
							A.[UserId],
							A.[ApplicationId]
						FROM [Security].[Entity.Account]	A
						LEFT JOIN	[#application]			X	ON	A.[ApplicationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)							A	ON	X.[UserId]			= A.[UserId]	AND
														X.[ApplicationId]	= A.[ApplicationId]
					WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT [#account] SELECT 
				A.[UserId],
				A.[ApplicationId]
			FROM [Security].[Entity.Account]	A
			WHERE A.[EmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM [#account]	X
			LEFT JOIN
			(
				SELECT 
					A.[UserId],
					A.[ApplicationId]
				FROM [Security].[Entity.Account]	A
				WHERE A.[EmplacementId] = @emplacementId
			)							A	ON	X.[UserId]			= A.[UserId]	AND
												X.[ApplicationId]	= A.[ApplicationId]
			WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by application
	IF (@applicationId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT [#account] SELECT 
				A.[UserId],
				A.[ApplicationId]
			FROM [Security].[Entity.Account]	A
			WHERE A.[ApplicationId] = @applicationId;
		ELSE
			DELETE X FROM [#account]	X
			LEFT JOIN
			(
				SELECT 
					A.[UserId],
					A.[ApplicationId]
				FROM [Security].[Entity.Account]	A
				WHERE A.[ApplicationId] = @applicationId
			)							A	ON	X.[UserId]			= A.[UserId]	AND
												X.[ApplicationId]	= A.[ApplicationId]
			WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
		SET @isFiltered = 1;
	END
	
--	Filter by assigned status
	DECLARE @assigned BIT;
	SET @assigned = [Common].[Bool.Entity](@predicate.query('/*/Assigned'));
	IF (@assigned IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT [#account] SELECT 
				A.[UserId],
				A.[ApplicationId]
			FROM [Security].[Entity.Account]	A
			WHERE 
				(
					@assigned = 1	AND
					A.[AccountId] IS NOT NULL
				)	OR
				(
					@assigned = 0	AND
					A.[AccountId] IS NULL
				);
		ELSE
			DELETE X FROM [#account]	X
			LEFT JOIN
			(
				SELECT 
					A.[UserId],
					A.[ApplicationId]
				FROM [Security].[Entity.Account]	A
				WHERE 
					(
						@assigned = 1	AND
						A.[AccountId] IS NOT NULL
					)	OR
					(
						@assigned = 0	AND
						A.[AccountId] IS NULL
					)
			)										A	ON	X.[UserId]			= A.[UserId]	AND
															X.[ApplicationId]	= A.[ApplicationId]
			WHERE COALESCE(A.[UserId], A.[ApplicationId]) IS NULL;
		SET @isFiltered = 1;
	END

--	Apply filters
	SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/IsIncluded'));
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Security].[Entity.Account] A;
	ELSE
		IF (@isIncluded = 1)
			SELECT @number = COUNT(*) FROM [#account] X;
		ELSE
			SELECT @number = COUNT(*) FROM [Security].[Entity.Account] A
			LEFT JOIN	[#account]	X	ON	A.[UserId]			= X.[UserId]	AND
													A.[ApplicationId]	= X.[ApplicationId]
			WHERE 
				A.[EmplacementId] = ISNULL(@emplacementId, A.[EmplacementId])	AND
				A.[ApplicationId] = ISNULL(@applicationId, A.[ApplicationId])	AND
				COALESCE(X.[UserId], X.[ApplicationId]) IS NULL;

END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Security].[Log.Entity]'
GO

ALTER FUNCTION [Security].[Log.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		LI.[LogId]	[Id],
		X.[ApplicationId],
		X.[AccountId],
		X.[TokenId],
		X.[CreatedOn],
		X.[LogActionType],
		X.[Comment],
		X.[Parameters]
	FROM
	(
		SELECT 
			X.[Id],
			A.[Id]	[ApplicationId],
			AC.[Id]	[AccountId],
			X.[TokenId],
			X.[CreatedOn],
			X.[LogActionType],
			X.[Comment],
			X.[Parameters]
		FROM
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',					'UNIQUEIDENTIFIER')					[Id],
				X.[Entity].query('Application')															[Application],
				X.[Entity].query('Account')																[Account],
				X.[Entity].value('(TokenId/text())[1]',				'UNIQUEIDENTIFIER')					[TokenId],
				CAST(LEFT(X.[Entity].value('(CreatedOn/text())[1]',	'NVARCHAR(MAX)'), 19) AS DATETIME)	[CreatedOn],
				X.[Entity].value('(LogActionType/text())[1]',		'NVARCHAR(MAX)')					[LogActionType],
				X.[Entity].value('(Comment/text())[1]',				'NVARCHAR(MAX)')					[Comment],
				X.[Entity].query('(Parameters/string)')													[Parameters]
			FROM @entity.nodes('/*') X ([Entity])
		)																X
		OUTER APPLY [Security].[Application.Entity](X.[Application])	A
		OUTER APPLY [Security].[Account.Entity](X.[Account])			AC
	)								X
	LEFT JOIN	[Security].[Log]	LI	ON	X.[Id]	= LI.[LogId]
)
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Common].[Preset.Filter]'
GO

ALTER PROCEDURE [Common].[Preset.Filter]
(
	@predicate		XML,
	@emplacementId	UNIQUEIDENTIFIER	= NULL,
	@applicationId	UNIQUEIDENTIFIER	= NULL,
	@organisations	BIT					= 0,
	@isIncluded		BIT							OUTPUT,
	@isFiltered		BIT							OUTPUT,
	@number			INT							OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;
	
	SET @isFiltered = 0;

--	Filter by codes
	DECLARE @codes TABLE ([Code] NVARCHAR(MAX));
	INSERT @codes SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/Codes/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/Codes/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#preset] SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
				INNER JOIN	@codes	X	ON	P.[PresetCode]	LIKE X.[Code];
			ELSE 
				INSERT [#preset] SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
				LEFT JOIN	@codes	X	ON	P.[PresetCode]	LIKE X.[Code]
				WHERE X.[Code] IS NULL;
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#preset]	X
				LEFT JOIN
				(
					SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
					INNER JOIN	@codes	X	ON	P.[PresetCode]	LIKE X.[Code]
				)						P	ON	X.[Id]	= P.[PresetId]
				WHERE P.[PresetId] IS NULL;
			ELSE
				DELETE X FROM [#preset]	X
				LEFT JOIN
				(
					SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
					LEFT JOIN	@codes	X	ON	P.[PresetCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL
				)						P	ON	X.[Id]	= P.[PresetId]
				WHERE P.[PresetId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by preset entity types
	DECLARE @presetEntityTypes TABLE ([PresetEntityType] NVARCHAR(MAX));
	INSERT @presetEntityTypes SELECT DISTINCT LTRIM(X.[Entity].value('(text())[1]', 'NVARCHAR(MAX)')) [PresetEntityType]
	FROM @predicate.nodes('/*/PresetEntityTypes/Value/PresetEntityType') X ([Entity]);
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/PresetEntityTypes/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#preset] SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
				INNER JOIN	@presetEntityTypes		X	ON	P.[PresetEntityType]	LIKE X.[PresetEntityType];
			ELSE 
				INSERT [#preset] SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
				LEFT JOIN	@presetEntityTypes		X	ON	P.[PresetEntityType]	LIKE X.[PresetEntityType]
				WHERE X.[PresetEntityType] IS NULL;
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#preset]	X
				LEFT JOIN
				(
					SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
					INNER JOIN	@presetEntityTypes		X	ON	P.[PresetEntityType]	LIKE X.[PresetEntityType]
				)						P	ON	X.[Id]	= P.[PresetId]
				WHERE P.[PresetId] IS NULL;
			ELSE
				DELETE X FROM [#preset]	X
				LEFT JOIN
				(
					SELECT DISTINCT P.[PresetId] FROM [Common].[Preset] P
					LEFT JOIN	@presetEntityTypes		X	ON	P.[PresetEntityType]	LIKE X.[PresetEntityType]
					WHERE X.[PresetEntityType] IS NULL
				)						P	ON	X.[Id]	= P.[PresetId]
				WHERE P.[PresetId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by entities
	DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
	INSERT @entities SELECT DISTINCT * FROM [Common].[Preset.Entities](@predicate.query('/*/Presets/Value/Preset'));
	IF (@@ROWCOUNT > 0) BEGIN
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/Presets/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#preset] SELECT * FROM @entities;
			ELSE
				INSERT [#preset] SELECT P.[PresetId] FROM [Common].[Preset] P
				WHERE P.[PresetId] NOT IN (SELECT * FROM @entities);
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#preset] X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
			ELSE
				DELETE X FROM [#preset] X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

--	Filter by account predicate
	DECLARE 
		@accountPredicate	XML,
		@accountIsFiltered	BIT,
		@accountNumber		INT;
	SELECT 
		@accountPredicate	= @predicate.query('/*/AccountPredicate'),
		@accountIsFiltered	= @predicate.exist('/*/AccountPredicate/*');
	IF (@accountIsFiltered = 1) BEGIN
		CREATE TABLE [#account] 
		(
			[UserId]		UNIQUEIDENTIFIER,
			[ApplicationId]	UNIQUEIDENTIFIER,
			PRIMARY KEY CLUSTERED 
			(
				[UserId],
				[ApplicationId]
			)
		);
		EXEC [Security].[Account.Filter]
			@predicate		= @accountPredicate, 
			@isIncluded		= @isIncluded			OUTPUT,
			@isFiltered		= @accountIsFiltered	OUTPUT,
			@number			= @accountNumber		OUTPUT;
		IF (@accountIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isIncluded = 1)
					INSERT [#preset] SELECT P.[PresetId] FROM [Common].[Preset] P
					INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]			= A.[AccountId]
					INNER JOIN	[#account]				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																A.[AccountApplicationId]	= X.[ApplicationId];
				ELSE
					INSERT [#preset] SELECT P.[PresetId] FROM [Common].[Preset] P
					INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]			= A.[AccountId]
					LEFT JOIN	[#account]				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																A.[AccountApplicationId]	= X.[ApplicationId]
					WHERE  COALESCE(X.[UserId], X.[ApplicationId]) IS NULL;
			ELSE
				IF (@isIncluded = 1)
					DELETE X FROM [#preset]	X
					LEFT JOIN (
						SELECT P.[PresetId] FROM [Common].[Preset]	P
						INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]			= A.[AccountId]
						INNER JOIN	[#account]				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																	A.[AccountApplicationId]	= X.[ApplicationId]
					)						P	ON	X.[Id]	= P.[PresetId]
					WHERE P.[PresetId] IS NULL;
				ELSE
					DELETE X FROM [#preset]	X
					LEFT JOIN (
						SELECT P.[PresetId] FROM [Common].[Preset]	P
						INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]			= A.[AccountId]
						LEFT JOIN	[#account]				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																	A.[AccountApplicationId]	= X.[ApplicationId]
						WHERE  COALESCE(X.[UserId], X.[ApplicationId]) IS NULL
					)						P	ON	X.[Id]	= P.[PresetId]
					WHERE P.[PresetId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT [#preset] SELECT P.[PresetId] FROM [Common].[Preset]	P
			INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]	= A.[AccountId]
			INNER JOIN	[Security].[User]		U	ON	A.[AccountUserId]	= U.[UserId]
			WHERE U.[UserEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM [#preset]	X
			LEFT JOIN	(
				SELECT P.[PresetId] FROM [Common].[Preset]	P
				INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]	= A.[AccountId]
				INNER JOIN	[Security].[User]		U	ON	A.[AccountUserId]	= U.[UserId]
				WHERE U.[UserEmplacementId] = @emplacementId
			)						P	ON	X.[Id]	= P.[PresetId]
			WHERE P.[PresetId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by application
	IF (@applicationId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT [#preset] SELECT P.[PresetId] FROM [Common].[Preset]	P
			INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]	= A.[AccountId]
			WHERE A.[AccountApplicationId] = @applicationId;
		ELSE
			DELETE X FROM [#preset]	X
			LEFT JOIN	(
				SELECT P.[PresetId] FROM [Common].[Preset]	P
				INNER JOIN	[Security].[Account]	A	ON	P.[PresetAccountId]	= A.[AccountId]
				WHERE A.[AccountApplicationId] = @applicationId
			)						P	ON	X.[Id]	= P.[PresetId]
			WHERE P.[PresetId] IS NULL;
		SET @isFiltered = 1;
	END

--	Apply filters
	SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/IsIncluded'));
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Common].[Preset] P;
	ELSE
		IF (@isIncluded = 1)
			SELECT @number = COUNT(*) FROM [#preset] X;
		ELSE
			SELECT @number = COUNT(*) FROM [Common].[Preset]	P
			INNER JOIN	[Security].[Account]	A	ON	L.[LogAccountId]	= A.[AccountId]
			INNER JOIN	[Security].[User]		U	ON	A.[AccountUserId]	= U.[UserId]
			LEFT JOIN	[#preset]				X	ON	P.[PresetId]		= X.[Id]
			WHERE 
				U.[UserEmplacementId]		= ISNULL(@emplacementId, U.[UserEmplacementId])		AND
				A.[AccountApplicationId]	= ISNULL(@applicationId, A.[AccountApplicationId])	AND
				X.[Id] IS NULL;

END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Common].[Preset.Action]'
GO

ALTER PROCEDURE [Common].[Preset.Action]
(
	@genericInput	XML,
	@number			INT	OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE 
		@permissionType	NVARCHAR(MAX),
		@entity			XML,
		@predicate		XML,
		@startNumber	INT,
		@endNumber		INT,
		@order			NVARCHAR(MAX),
		@emplacementId	UNIQUEIDENTIFIER,
		@applicationId	UNIQUEIDENTIFIER,
		@organisations	BIT,
		@isIncluded		BIT,
		@isFiltered		BIT,
		@command		NVARCHAR(MAX);
	
	DECLARE @input TABLE	
	(
		[Id]				UNIQUEIDENTIFIER,
		[AccountId]			UNIQUEIDENTIFIER,
		[PresetEntityType]	NVARCHAR(MAX),
		[Code]				NVARCHAR(MAX),
		[Predicate]			NVARCHAR(MAX),
		[IsDefault]			BIT,
		[IsInstantly]		BIT
	);
	
	DECLARE @output TABLE ([Id] UNIQUEIDENTIFIER);

	CREATE TABLE [#organisations] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	EXEC [Common].[GenericInput.Entity] 
		@genericInput	= @genericInput,
		@permissionType = @permissionType	OUTPUT,
		@entity			= @entity			OUTPUT,
		@predicate		= @predicate		OUTPUT,
		@startNumber	= @startNumber		OUTPUT,
		@endNumber		= @endNumber		OUTPUT,
		@order			= @order			OUTPUT,
		@emplacementId	= @emplacementId	OUTPUT,
		@applicationId	= @applicationId	OUTPUT,
		@organisations	= @organisations	OUTPUT;
	
	IF (@permissionType = 'PresetCreate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			INSERT @input SELECT X.* FROM [Common].[Preset.Entity](@entity) X;
			IF (EXISTS(SELECT * FROM @input X WHERE X.[IsDefault] = 1))
				UPDATE P SET P.[PresetIsDefault] = 0
				FROM [Common].[Preset]	P
				INNER JOIN	@input		X	ON	P.[PresetAccountId]		= X.[AccountId]	AND
												P.[PresetEntityType]	= X.[PresetEntityType]	AND
												P.[PresetIsDefault]		= 1;
			INSERT [Common].[Preset] 
			(
				[PresetAccountId],
				[PresetEntityType],
				[PresetCode],
				[PresetPredicate],
				[PresetIsDefault],
				[PresetIsInstantly]
			)
			OUTPUT INSERTED.[PresetId] INTO @output ([Id])
			SELECT
				X.[AccountId],
				X.[PresetEntityType],
				X.[Code],
				X.[Predicate],
				X.[IsDefault],
				X.[IsInstantly]
			FROM @input X;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT P.* FROM [Common].[Entity.Preset]		P
		INNER JOIN	@output								X	ON	P.[PresetId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'PresetRead') BEGIN
		SELECT P.* FROM [Common].[Entity.Preset]		P
		INNER JOIN	[Common].[Preset.Entity](@entity)	X	ON	P.[PresetId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'PresetUpdate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			INSERT @input SELECT X.* FROM [Common].[Preset.Entity](@entity) X;
			IF (EXISTS(SELECT * FROM @input X WHERE X.[IsDefault] = 1))
				UPDATE P SET P.[PresetIsDefault] = 0
				FROM [Common].[Preset]	P
				INNER JOIN	@input		X	ON	P.[PresetAccountId]		= X.[AccountId]	AND
												P.[PresetEntityType]	= X.[PresetEntityType]	AND
												P.[PresetIsDefault]		= 1;
			UPDATE P SET 
				P.[PresetAccountId]		= X.[AccountId],
				P.[PresetEntityType]	= X.[PresetEntityType],
				P.[PresetCode]			= X.[Code],
				P.[PresetPredicate]		= X.[Predicate],
				P.[PresetIsDefault]		= X.[IsDefault],
				P.[PresetIsInstantly]	= X.[IsInstantly]
			OUTPUT INSERTED.[PresetId] INTO @output ([Id])
			FROM [Common].[Preset]	P
			INNER JOIN	@input			X	ON	P.[PresetId]	= X.[Id];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT P.* FROM [Security].[Entity.Preset]		P
		INNER JOIN	@output								X	ON	P.[PresetId]	= X.[Id];
	END

	IF (@permissionType = 'PresetDelete') BEGIN
		DELETE P FROM [Common].[Preset]				P
		INNER JOIN	[Security].[Preset.Entity](@entity)	X	ON	P.[PresetId]	= X.[Id];
		EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
	END
	
	IF (@permissionType = 'PresetSearch') BEGIN
		CREATE TABLE [#preset] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC [Common].[Preset.Filter]
			@predicate		= @predicate,
			@emplacementId	= @emplacementId,
			@applicationId	= @applicationId,
			@organisations	= @organisations,
			@isIncluded		= @isIncluded	OUTPUT,
			@isFiltered		= @isFiltered	OUTPUT,
			@number			= @number		OUTPUT;
		SET @order = ISNULL(@order, ' ORDER BY [PresetAccountId] ASC, [PresetCode] ASC ');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT P.* FROM [Common].[Entity.Preset]		P
				';
			ELSE
				IF (@isIncluded = 1)
					SET @command = '
					SELECT P.* FROM [#preset]					X
					INNER JOIN	[Common].[Entity.Preset]		P	ON	X.[Id]		= P.[PresetId]
					';
				ELSE
					SET @command = '
					SELECT P.* FROM [Common].[Entity.Preset]	P
					LEFT JOIN	[#preset]						X	ON	P.[PresetId]	= X.[Id]
					WHERE 
						' + ISNULL('P.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						' + ISNULL('P.[ApplicationId] = ''' + CAST(@applicationId AS NVARCHAR(MAX)) + ''' AND', '') + '
						X.[Id] IS NULL
					';
			SET @command = @command + @order;
		END
		ELSE BEGIN
			IF (@isFiltered = 0)
				SET @command = '
				SELECT * FROM
				(
					SELECT 
						P.*, 
						ROW_NUMBER() OVER(' + @order + ') [Number]
					FROM [Common].[Entity.Preset]				P
				)	P
				WHERE P.[Number] BETWEEN
				';
			ELSE
				IF (@isIncluded = 1)
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							P.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [#preset]							X
						INNER JOIN	[Common].[Entity.Preset]	P	ON	X.[Id]		= P.[PresetId]
					)	P
					WHERE P.[Number] BETWEEN
					';
				ELSE
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							P.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [Common].[Entity.Preset]			P
						LEFT JOIN	[#preset]					X	ON	P.[PresetId]	= X.[Id]
						WHERE 
							' + ISNULL('P.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
							' + ISNULL('P.[ApplicationId] = ''' + CAST(@applicationId AS NVARCHAR(MAX)) + ''' AND', '') + '
							X.[Id] IS NULL
					)	P
					WHERE P.[Number] BETWEEN
					';
			SET @command = @command + CAST(@startNumber AS NVARCHAR(MAX)) + ' AND ' + CAST(@endNumber AS NVARCHAR(MAX));
		END
		EXEC sp_executesql @command;
	END

END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Security].[Log.Filter]'
GO

ALTER PROCEDURE [Security].[Log.Filter]
(
	@predicate		XML,
	@emplacementId	UNIQUEIDENTIFIER	= NULL,
	@applicationId	UNIQUEIDENTIFIER	= NULL,
	@organisations	BIT					= 0,
	@isIncluded		BIT							OUTPUT,
	@isFiltered		BIT							OUTPUT,
	@number			INT							OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE 
		@dateFrom	DATETIME,
		@dateTo		DATETIME;
	
	SET @isFiltered = 0;

--	Filter by created datetime
	SELECT @dateFrom = NULL, @dateTo = NULL;
	SELECT 
		@dateFrom	= X.[DateFrom], 
		@dateTo		= X.[DateTo] 
	FROM [Common].[DateInterval.Entity](@predicate.query('/*/CreatedOn/Value')) X;
	IF (COALESCE(@dateFrom, @dateTo) IS NOT NULL) BEGIN 
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/CreatedOn/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#log] SELECT L.[LogId] FROM [Security].[Log] L
				WHERE L.[LogCreatedOn] BETWEEN ISNULL(@dateFrom, L.[LogCreatedOn]) AND ISNULL(@dateTo, L.[LogCreatedOn]);
			ELSE 
				INSERT [#log] SELECT L.[LogId] FROM [Security].[Log] L
				WHERE L.[LogCreatedOn] NOT BETWEEN ISNULL(@dateFrom, L.[LogCreatedOn]) AND ISNULL(@dateTo, L.[LogCreatedOn]);
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#log]	X
				LEFT JOIN
				(
					SELECT L.[LogId] FROM [Security].[Log] L
					WHERE L.[LogCreatedOn] BETWEEN ISNULL(@dateFrom, L.[LogCreatedOn]) AND ISNULL(@dateTo, L.[LogCreatedOn])
				)						L	ON	X.[Id]	= L.[LogId]
				WHERE L.[LogId] IS NULL;
			ELSE
				DELETE X FROM [#log]	X
				LEFT JOIN
				(
					SELECT L.[LogId] FROM [Security].[Log] L
					WHERE L.[LogCreatedOn] NOT BETWEEN ISNULL(@dateFrom, L.[LogCreatedOn]) AND ISNULL(@dateTo, L.[LogCreatedOn])
				)						L	ON	X.[Id]	= L.[LogId]
				WHERE L.[LogId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by log action types
	DECLARE @logActionTypes TABLE ([LogActionType] NVARCHAR(MAX));
	INSERT @logActionTypes SELECT DISTINCT LTRIM(X.[Entity].value('(text())[1]', 'NVARCHAR(MAX)')) [LogActionType]
	FROM @predicate.nodes('/*/LogActionTypes/Value/LogActionType') X ([Entity]);
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/LogActionTypes/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#log] SELECT DISTINCT L.[LogId] FROM [Security].[Log] L
				INNER JOIN	@logActionTypes		X	ON	L.[LogActionType]	LIKE X.[LogActionType];
			ELSE 
				INSERT [#log] SELECT DISTINCT L.[LogId] FROM [Security].[Log] L
				LEFT JOIN	@logActionTypes		X	ON	L.[LogActionType]	LIKE X.[LogActionType]
				WHERE X.[LogActionType] IS NULL;
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#log]	X
				LEFT JOIN
				(
					SELECT DISTINCT L.[LogId] FROM [Security].[Log] L
					INNER JOIN	@logActionTypes		X	ON	L.[LogActionType]	LIKE X.[LogActionType]
				)						L	ON	X.[Id]	= L.[LogId]
				WHERE L.[LogId] IS NULL;
			ELSE
				DELETE X FROM [#log]	X
				LEFT JOIN
				(
					SELECT DISTINCT L.[LogId] FROM [Security].[Log] L
					LEFT JOIN	@logActionTypes		X	ON	L.[LogActionType]	LIKE X.[LogActionType]
					WHERE X.[LogActionType] IS NULL
				)						L	ON	X.[Id]	= L.[LogId]
				WHERE L.[LogId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by comments
	DECLARE @comments TABLE ([Comment] NVARCHAR(MAX));
	INSERT @comments SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/Comments/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/Comments/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#log] SELECT DISTINCT L.[LogId] FROM [Security].[Log] L
				INNER JOIN	@comments	X	ON	L.[LogComment]	LIKE X.[Comment];
			ELSE 
				INSERT [#log] SELECT DISTINCT L.[LogId] FROM [Security].[Log] L
				LEFT JOIN	@comments	X	ON	L.[LogComment]	LIKE X.[Comment]
				WHERE X.[Comment] IS NULL;
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#log]	X
				LEFT JOIN
				(
					SELECT DISTINCT L.[LogId] FROM [Security].[Log] L
					INNER JOIN	@comments	X	ON	L.[LogComment]	LIKE X.[Comment]
				)						L	ON	X.[Id]	= L.[LogId]
				WHERE L.[LogId] IS NULL;
			ELSE
				DELETE X FROM [#log]	X
				LEFT JOIN
				(
					SELECT DISTINCT L.[LogId] FROM [Security].[Log] L
					LEFT JOIN	@comments	X	ON	L.[LogComment]	LIKE X.[Comment]
					WHERE X.[Comment] IS NULL
				)						L	ON	X.[Id]	= L.[LogId]
				WHERE L.[LogId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by entities
	DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
	INSERT @entities SELECT DISTINCT * FROM [Security].[Log.Entities](@predicate.query('/*/Logs/Value/Log'));
	IF (@@ROWCOUNT > 0) BEGIN
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/Logs/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#log] SELECT * FROM @entities;
			ELSE
				INSERT [#log] SELECT L.[LogId] FROM [Security].[Log] L
				WHERE L.[LogId] NOT IN (SELECT * FROM @entities);
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#log] X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
			ELSE
				DELETE X FROM [#log] X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

--	Filter by application predicate
	DECLARE 
		@applicationPredicate	XML,
		@applicationIsFiltered	BIT,
		@applicationNumber		INT;
	SELECT 
		@applicationPredicate	= @predicate.query('/*/ApplicationPredicate'),
		@applicationIsFiltered	= @predicate.exist('/*/ApplicationPredicate/*');
	IF (@applicationIsFiltered = 1) BEGIN
		CREATE TABLE [#application] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC [Security].[Application.Filter]
			@predicate		= @applicationPredicate, 
			@isIncluded		= @isIncluded				OUTPUT,
			@isFiltered		= @applicationIsFiltered	OUTPUT,
			@number			= @applicationNumber		OUTPUT;
		IF (@applicationIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isIncluded = 1)
					INSERT [#log] SELECT L.[LogId] FROM [Security].[Log] L
					INNER JOIN	[#application]	X	ON	L.[LogApplicationId]	= X.[Id];
				ELSE
					INSERT [#log] SELECT L.[LogId] FROM [Security].[Log] L
					LEFT JOIN	[#application]	X	ON	L.[LogApplicationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isIncluded = 1)
					DELETE X FROM [#log]		X
					LEFT JOIN (
						SELECT L.[LogId] FROM [Security].[Log] L
						INNER JOIN	[#application]	X	ON	L.[LogApplicationId]	= X.[Id]
					)							L	ON	X.[Id]					= L.[LogId]
					WHERE L.[LogId] IS NULL;
				ELSE
					DELETE X FROM [#log]		X
					LEFT JOIN (
						SELECT L.[LogId] FROM [Security].[Log] L
						LEFT JOIN	[#application]	X	ON	L.[LogApplicationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)							L	ON	X.[Id]					= L.[LogId]
					WHERE L.[LogId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by account predicate
	DECLARE 
		@accountPredicate	XML,
		@accountIsFiltered	BIT,
		@accountNumber		INT;
	SELECT 
		@accountPredicate	= @predicate.query('/*/AccountPredicate'),
		@accountIsFiltered	= @predicate.exist('/*/AccountPredicate/*');
	IF (@accountIsFiltered = 1) BEGIN
		CREATE TABLE [#account] 
		(
			[UserId]		UNIQUEIDENTIFIER,
			[ApplicationId]	UNIQUEIDENTIFIER,
			PRIMARY KEY CLUSTERED 
			(
				[UserId],
				[ApplicationId]
			)
		);
		EXEC [Security].[Account.Filter]
			@predicate		= @accountPredicate, 
			@isIncluded		= @isIncluded			OUTPUT,
			@isFiltered		= @accountIsFiltered	OUTPUT,
			@number			= @accountNumber		OUTPUT;
		IF (@accountIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isIncluded = 1)
					INSERT [#log] SELECT L.[LogId] FROM [Security].[Log] L
					INNER JOIN	[Security].[Account]	A	ON	L.[LogAccountId]			= A.[AccountId]
					INNER JOIN	[#account]				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																A.[AccountApplicationId]	= X.[ApplicationId];
				ELSE
					INSERT [#log] SELECT L.[LogId] FROM [Security].[Log] L
					INNER JOIN	[Security].[Account]	A	ON	L.[LogAccountId]			= A.[AccountId]
					LEFT JOIN	[#account]				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																A.[AccountApplicationId]	= X.[ApplicationId]
					WHERE  COALESCE(X.[UserId], X.[ApplicationId]) IS NULL;
			ELSE
				IF (@isIncluded = 1)
					DELETE X FROM [#log]	X
					LEFT JOIN (
						SELECT L.[LogId] FROM [Security].[Log]	L
						INNER JOIN	[Security].[Account]	A	ON	L.[LogAccountId]			= A.[AccountId]
						INNER JOIN	[#account]				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																	A.[AccountApplicationId]	= X.[ApplicationId]
					)						L	ON	X.[Id]	= L.[LogId]
					WHERE L.[LogId] IS NULL;
				ELSE
					DELETE X FROM [#log]	X
					LEFT JOIN (
						SELECT L.[LogId] FROM [Security].[Log]	L
						INNER JOIN	[Security].[Account]	A	ON	L.[LogAccountId]			= A.[AccountId]
						LEFT JOIN	[#account]				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																	A.[AccountApplicationId]	= X.[ApplicationId]
						WHERE  COALESCE(X.[UserId], X.[ApplicationId]) IS NULL
					)						L	ON	X.[Id]	= L.[LogId]
					WHERE L.[LogId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT [#log] SELECT L.[LogId] FROM [Security].[Log] L
			INNER JOIN	[Security].[Account]	A	ON	L.[LogAccountId]	= A.[AccountId]
			INNER JOIN	[Security].[User]		U	ON	A.[AccountUserId]	= U.[UserId]
			WHERE U.[UserEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM [#log]	X
			LEFT JOIN	(
				SELECT L.[LogId] FROM [Security].[Log] L
				INNER JOIN	[Security].[Account]	A	ON	L.[LogAccountId]	= A.[AccountId]
				INNER JOIN	[Security].[User]		U	ON	A.[AccountUserId]	= U.[UserId]
				WHERE U.[UserEmplacementId] = @emplacementId
			)						L	ON	X.[Id]	= L.[LogId]
			WHERE L.[LogId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by application
	IF (@applicationId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT [#log] SELECT L.[LogId] FROM [Security].[Log] L
			WHERE L.[LogApplicationId] = @applicationId;
		ELSE
			DELETE X FROM [#log]	X
			LEFT JOIN	(
				SELECT L.[LogId] FROM [Security].[Log] L
				WHERE L.[LogApplicationId] = @applicationId
			)						L	ON	X.[Id]	= L.[LogId]
			WHERE L.[LogId] IS NULL;
		SET @isFiltered = 1;
	END

--	Apply filters
	SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/IsIncluded'));
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Security].[Log] L;
	ELSE
		IF (@isIncluded = 1)
			SELECT @number = COUNT(*) FROM [#log] X;
		ELSE
			IF (@emplacementId IS NULL)
				SELECT @number = COUNT(*) FROM [Security].[Log] L
				LEFT JOIN	[#log]								X	ON	L.[LogId]					= X.[Id]
				WHERE 
					L.[LogApplicationId] = ISNULL(@applicationId, L.[LogApplicationId])	AND
					X.[Id] IS NULL;
			ELSE 
				SELECT @number = COUNT(*) FROM [Security].[Log] L
				INNER JOIN	[Security].[Account]		A	ON	L.[LogAccountId]	= A.[AccountId]
				INNER JOIN	[Security].[User]			U	ON	A.[AccountUserId]	= U.[UserId]
				LEFT JOIN	[#log]						X	ON	L.[LogId]			= X.[Id]
				WHERE 
					U.[UserEmplacementId]	= @emplacementId								AND
					L.[LogApplicationId]	= ISNULL(@applicationId, L.[LogApplicationId])	AND
					X.[Id] IS NULL;

END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Security].[Log.Action]'
GO

ALTER PROCEDURE [Security].[Log.Action]
(
	@genericInput	XML,
	@number			INT	OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE 
		@permissionType	NVARCHAR(MAX),
		@entity			XML,
		@predicate		XML,
		@startNumber	INT,
		@endNumber		INT,
		@order			NVARCHAR(MAX),
		@emplacementId	UNIQUEIDENTIFIER,
		@applicationId	UNIQUEIDENTIFIER,
		@organisations	BIT,
		@isIncluded		BIT,
		@isFiltered		BIT,
		@command		NVARCHAR(MAX);
	
	DECLARE @output TABLE ([Id] UNIQUEIDENTIFIER);
	
	CREATE TABLE [#organisations] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	EXEC [Common].[GenericInput.Entity] 
		@genericInput	= @genericInput,
		@permissionType = @permissionType	OUTPUT,
		@entity			= @entity			OUTPUT,
		@predicate		= @predicate		OUTPUT,
		@startNumber	= @startNumber		OUTPUT,
		@endNumber		= @endNumber		OUTPUT,
		@order			= @order			OUTPUT,
		@emplacementId	= @emplacementId	OUTPUT,
		@applicationId	= @applicationId	OUTPUT,
		@organisations	= @organisations	OUTPUT;
	
	IF (@permissionType = 'LogCreate') BEGIN
		INSERT [Security].[Log] 
		(
			[LogApplicationId],
			[LogAccountId],
			[LogTokenId],
			[LogCreatedOn],
			[LogActionType],
			[LogComment],
			[LogParameters]
		)
		OUTPUT INSERTED.[LogId] INTO @output ([Id])
		SELECT
			X.[ApplicationId],
			X.[AccountId],
			X.[TokenId],
			X.[CreatedOn],
			X.[LogActionType],
			X.[Comment],
			X.[Parameters]
		FROM [Security].[Log.Entity](@entity) X;
		SELECT L.* FROM [Security].[Entity.Log]			L
		INNER JOIN	@output								X	ON	L.[LogId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'LogRead') BEGIN
		SELECT L.* FROM [Security].[Entity.Log]			L
		INNER JOIN	[Security].[Log.Entity](@entity)	X	ON	L.[LogId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'LogSearch') BEGIN
		CREATE TABLE [#log] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC [Security].[Log.Filter]
			@predicate		= @predicate,
			@emplacementId	= @emplacementId,
			@applicationId	= @applicationId,
			@organisations	= @organisations,
			@isIncluded		= @isIncluded	OUTPUT,
			@isFiltered		= @isFiltered	OUTPUT,
			@number			= @number		OUTPUT;
		SET @order = ISNULL(@order, ' ORDER BY [LogCreatedOn] DESC ');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT L.* FROM [Security].[Entity.Log]		L
				';
			ELSE
				IF (@isIncluded = 1)
					SET @command = '
					SELECT L.* FROM [#log]					X
					INNER JOIN	[Security].[Entity.Log]		L	ON	X.[Id]		= L.[LogId]
					';
				ELSE
					SET @command = '
					SELECT L.* FROM [Security].[Entity.Log]	L
					LEFT JOIN	[#log]						X	ON	L.[LogId]	= X.[Id]
					WHERE 
						' + ISNULL('L.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						' + ISNULL('L.[ApplicationId] = ''' + CAST(@applicationId AS NVARCHAR(MAX)) + ''' AND', '') + '
						X.[Id] IS NULL
					';
			SET @command = @command + @order;
		END
		ELSE BEGIN
			IF (@isFiltered = 0)
				SET @command = '
				SELECT * FROM
				(
					SELECT 
						L.*, 
						ROW_NUMBER() OVER(' + @order + ') [Number]
					FROM [Security].[Entity.Log]			L
				)	L
				WHERE L.[Number] BETWEEN
				';
			ELSE
				IF (@isIncluded = 1)
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							L.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [#log]							X
						INNER JOIN	[Security].[Entity.Log]	L	ON	X.[Id]		= L.[LogId]
					)	L
					WHERE L.[Number] BETWEEN
					';
				ELSE
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							L.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [Security].[Entity.Log]		L
						LEFT JOIN	[#log]					X	ON	L.[LogId]	= X.[Id]
						WHERE 
							' + ISNULL('L.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
							' + ISNULL('L.[ApplicationId] = ''' + CAST(@applicationId AS NVARCHAR(MAX)) + ''' AND', '') + '
							X.[Id] IS NULL
					)	L
					WHERE L.[Number] BETWEEN
					';
			SET @command = @command + CAST(@startNumber AS NVARCHAR(MAX)) + ' AND ' + CAST(@endNumber AS NVARCHAR(MAX));
		END
		EXEC sp_executesql @command;
	END

END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Creating [Security].[Account.Action]'
GO

CREATE PROCEDURE [Security].[Account.Action]
(
	@genericInput	XML,
	@number			INT	OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE 
		@permissionType	NVARCHAR(MAX),
		@entity			XML,
		@predicate		XML,
		@startNumber	INT,
		@endNumber		INT,
		@order			NVARCHAR(MAX),
		@emplacementId	UNIQUEIDENTIFIER,
		@applicationId	UNIQUEIDENTIFIER,
		@organisations	BIT,
		@isIncluded		BIT,
		@isFiltered		BIT,
		@command		NVARCHAR(MAX);
	
	DECLARE @input TABLE	
	(
		[Id]		UNIQUEIDENTIFIER,
		[Version]	VARBINARY(MAX)
	);
	
	DECLARE @output TABLE ([Id] UNIQUEIDENTIFIER);
	
	CREATE TABLE [#organisations] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	EXEC [Common].[GenericInput.Entity] 
		@genericInput	= @genericInput,
		@permissionType = @permissionType	OUTPUT,
		@entity			= @entity			OUTPUT,
		@predicate		= @predicate		OUTPUT,
		@startNumber	= @startNumber		OUTPUT,
		@endNumber		= @endNumber		OUTPUT,
		@order			= @order			OUTPUT,
		@emplacementId	= @emplacementId	OUTPUT,
		@applicationId	= @applicationId	OUTPUT,
		@organisations	= @organisations	OUTPUT;
	
	DECLARE @roles XML;
	SELECT 
		@isIncluded	= @entity.exist('/*/Roles'),
		@roles		= @entity.query('/*/Roles/Role');
	
	IF (@permissionType = 'AccountCreate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			INSERT [Security].[Account] 
			(
				[AccountUserId],
				[AccountApplicationId],
				[AccountLockedOn],
				[AccountLastUsedOn]
			)
			OUTPUT INSERTED.[AccountId] INTO @output ([Id])
			SELECT
				X.[UserId],
				X.[ApplicationId],
				X.[LockedOn],
				X.[LastUsedOn]
			FROM [Security].[Account.Entity](@entity) X;
			IF (@isIncluded = 1)
				INSERT [Security].[AccountRole]
				SELECT DISTINCT
					X.[Id]	[AccountId],
					R.[Id]	[RoleId]
				FROM @output X, [Security].[Role.Entities](@roles) R;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT A.* FROM [Security].[Entity.Account]		A
		INNER JOIN	@output								X	ON	A.[AccountId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
	
	IF (@permissionType = 'AccountRead') BEGIN
		SELECT A.* FROM [Security].[Entity.Account]			A
		INNER JOIN	[Security].[Account.Entity](@entity)	X	ON	A.[AccountId]	= X.[Id];
		SET @number = @@ROWCOUNT;
	END
		
	IF (@permissionType = 'AccountUpdate') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			UPDATE A SET 
				A.[AccountLockedOn]	= X.[LockedOn],
				A.[AccountLastUsedOn]	= X.[LastUsedOn]
			OUTPUT INSERTED.[AccountId] INTO @output ([Id])
			FROM [Security].[Account]							A
			INNER JOIN	[Security].[Account.Entity](@entity)	X	ON	A.[AccountId]		= X.[Id]	AND
																		A.[AccountVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			IF (@isIncluded = 1) BEGIN
				DELETE	AR	FROM [Security].[AccountRole]	AR
				INNER JOIN	@output							X	ON	AR.[AccountRoleAccountId]	= X.[Id];
				INSERT [Security].[AccountRole]
				SELECT DISTINCT
					X.[Id]	[AccountId],
					R.[Id]	[RoleId]
				FROM @output X, [Security].[Role.Entities](@roles) R;
			END
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
		SELECT A.* FROM [Security].[Entity.Account]	A
		INNER JOIN	@output							X	ON	A.[AccountId]	= X.[Id];
	END

	IF (@permissionType = 'AccountDelete') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			INSERT @input
			SELECT 
				X.[Id],
				X.[Version]
			FROM [Security].[Account.Entity](@entity) X;
			DELETE	AR	FROM [Security].[AccountRole]	AR
			INNER JOIN	@input							X	ON	AR.[AccountRoleAccountId]	= X.[Id];
			DELETE	A	FROM [Security].[Account]		A
			INNER JOIN	@input							X	ON	A.[AccountId]		= X.[Id]	AND
																A.[AccountVersion]	= X.[Version];
			EXEC [Error].[EntityAction.Throw] @number = @number OUTPUT;
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END
	
	IF (@permissionType = 'AccountSearch') BEGIN
		CREATE TABLE [#account] 
		(
			[UserId]		UNIQUEIDENTIFIER,
			[ApplicationId]	UNIQUEIDENTIFIER,
			PRIMARY KEY CLUSTERED 
			(
				[UserId],
				[ApplicationId]
			)
		);
		EXEC [Security].[Account.Filter]
			@predicate		= @predicate,
			@emplacementId	= @emplacementId,
			@applicationId	= @applicationId,
			@organisations	= @organisations,
			@isIncluded		= @isIncluded	OUTPUT,
			@isFiltered		= @isFiltered	OUTPUT,
			@number			= @number		OUTPUT;
		SET @order = ISNULL(@order, ' ORDER BY [AccountUserId] ASC, [AccountApplicationId] ASC ');
		IF (@startNumber IS NULL AND @endNumber IS NULL) BEGIN 
			IF (@isFiltered = 0)
				SET @command = '
				SELECT A.* FROM [Security].[Entity.Account]		A
				';
			ELSE
				IF (@isIncluded = 1)
					SET @command = '
					SELECT A.* FROM [#account]					X
					INNER JOIN	[Security].[Entity.Account]		A	ON	X.[UserId]			= A.[UserId]	AND
																		X.[ApplicationId]	= A.[ApplicationId]
					';
				ELSE
					SET @command = '
					SELECT A.* FROM [Security].[Entity.Account]	A
					LEFT JOIN	[#account]						X	ON	A.[UserId]			= X.[UserId]	AND
																		A.[ApplicationId]	= X.[ApplicationId]
					WHERE															
						' + ISNULL('A.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
						' + ISNULL('A.[ApplicationId] = ''' + CAST(@applicationId AS NVARCHAR(MAX)) + ''' AND', '') + '
						COALESCE(X.[UserId], X.[ApplicationId]) IS NULL
					';
			SET @command = @command + @order;
		END
		ELSE BEGIN
			IF (@isFiltered = 0)
				SET @command = '
				SELECT * FROM
				(
					SELECT 
						A.*, 
						ROW_NUMBER() OVER(' + @order + ') [Number]
					FROM [Security].[Entity.Account]			A
				)	A
				WHERE A.[Number] BETWEEN
				';
			ELSE
				IF (@isIncluded = 1)
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							A.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [#account]							X
						INNER JOIN	[Security].[Entity.Account]	A	ON	X.[UserId]			= A.[UserId]	AND
																		X.[ApplicationId]	= A.[ApplicationId]
					)	A
					WHERE A.[Number] BETWEEN
					';
				ELSE
					SET @command = '
					SELECT * FROM
					(
						SELECT 
							A.*, 
							ROW_NUMBER() OVER(' + @order + ') [Number]
						FROM [Security].[Entity.Account]		A
						LEFT JOIN	[#account]					X	ON	A.[UserId]			= X.[UserId]	AND
																		A.[ApplicationId]	= X.[ApplicationId]
						WHERE 
							' + ISNULL('A.[EmplacementId] = ''' + CAST(@emplacementId AS NVARCHAR(MAX)) + ''' AND', '') + '
							' + ISNULL('A.[ApplicationId] = ''' + CAST(@applicationId AS NVARCHAR(MAX)) + ''' AND', '') + '
							COALESCE(X.[UserId], X.[ApplicationId]) IS NULL
					)	A
					WHERE A.[Number] BETWEEN
					';
			SET @command = @command + CAST(@startNumber AS NVARCHAR(MAX)) + ' AND ' + CAST(@endNumber AS NVARCHAR(MAX));
		END
		EXEC sp_executesql @command;
	END

END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Security].[Permission.Filter]'
GO

ALTER PROCEDURE [Security].[Permission.Filter]
(
	@predicate		XML,
	@emplacementId	UNIQUEIDENTIFIER	= NULL,
	@applicationId	UNIQUEIDENTIFIER	= NULL,
	@organisations	BIT					= 0,
	@isIncluded		BIT							OUTPUT,
	@isFiltered		BIT							OUTPUT,
	@number			INT							OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;
	
	SET @isFiltered = 0;

--	Filter by codes
	DECLARE @codes TABLE ([Code] NVARCHAR(MAX));
	INSERT @codes SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/Codes/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/Codes/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#permission] SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
				INNER JOIN	@codes	X	ON	P.[PermissionCode]	LIKE X.[Code];
			ELSE 
				INSERT [#permission] SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
				LEFT JOIN	@codes	X	ON	P.[PermissionCode]	LIKE X.[Code]
				WHERE X.[Code] IS NULL;
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#permission]	X
				LEFT JOIN
				(
					SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
					INNER JOIN	@codes	X	ON	P.[PermissionCode]	LIKE X.[Code]
				)						P	ON	X.[Id]	= P.[PermissionId]
				WHERE P.[PermissionId] IS NULL;
			ELSE
				DELETE X FROM [#permission]	X
				LEFT JOIN
				(
					SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
					LEFT JOIN	@codes	X	ON	P.[PermissionCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL
				)						P	ON	X.[Id]	= P.[PermissionId]
				WHERE P.[PermissionId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by categories
	DECLARE @categories TABLE ([Category] NVARCHAR(MAX));
	INSERT @categories SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/Categories/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/Categories/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#permission] SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
				INNER JOIN	@categories	X	ON	P.[PermissionCategory]	LIKE X.[Category];
			ELSE 
				INSERT [#permission] SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
				LEFT JOIN	@categories	X	ON	P.[PermissionCategory]	LIKE X.[Category]
				WHERE X.[Category] IS NULL;
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#permission]	X
				LEFT JOIN
				(
					SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
					INNER JOIN	@categories	X	ON	P.[PermissionCategory]	LIKE X.[Category]
				)						P	ON	X.[Id]	= P.[PermissionId]
				WHERE P.[PermissionId] IS NULL;
			ELSE
				DELETE X FROM [#permission]	X
				LEFT JOIN
				(
					SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
					LEFT JOIN	@categories	X	ON	P.[PermissionCategory]	LIKE X.[Category]
					WHERE X.[Category] IS NULL
				)						P	ON	X.[Id]	= P.[PermissionId]
				WHERE P.[PermissionId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by descriptions
	DECLARE @descriptions TABLE ([Description] NVARCHAR(MAX));
	INSERT @descriptions SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/Descriptions/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/Descriptions/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#permission] SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
				INNER JOIN	@descriptions	X	ON	P.[PermissionDescription]	LIKE X.[Description];
			ELSE 
				INSERT [#permission] SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
				LEFT JOIN	@descriptions	X	ON	P.[PermissionDescription]	LIKE X.[Description]
				WHERE X.[Description] IS NULL;
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#permission]	X
				LEFT JOIN
				(
					SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
					INNER JOIN	@descriptions	X	ON	P.[PermissionDescription]	LIKE X.[Description]
				)						P	ON	X.[Id]	= P.[PermissionId]
				WHERE P.[PermissionId] IS NULL;
			ELSE
				DELETE X FROM [#permission]	X
				LEFT JOIN
				(
					SELECT DISTINCT P.[PermissionId] FROM [Security].[Permission] P
					LEFT JOIN	@descriptions	X	ON	P.[PermissionDescription]	LIKE X.[Description]
					WHERE X.[Description] IS NULL
				)						P	ON	X.[Id]	= P.[PermissionId]
				WHERE P.[PermissionId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by entities
	DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
	INSERT @entities SELECT DISTINCT * FROM [Security].[Permission.Entities](@predicate.query('/*/Permissions/Value/Permission'));
	IF (@@ROWCOUNT > 0) BEGIN
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/Permissions/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#permission] SELECT * FROM @entities;
			ELSE
				INSERT [#permission] SELECT P.[PermissionId] FROM [Security].[Permission] P
				WHERE P.[PermissionId] NOT IN (SELECT * FROM @entities);
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#permission] X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
			ELSE
				DELETE X FROM [#permission] X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

--	Filter by application predicate
	DECLARE 
		@applicationPredicate	XML,
		@applicationIsFiltered	BIT,
		@applicationNumber		INT;
	SELECT 
		@applicationPredicate	= @predicate.query('/*/ApplicationPredicate'),
		@applicationIsFiltered	= @predicate.exist('/*/ApplicationPredicate/*');
	IF (@applicationIsFiltered = 1) BEGIN
		CREATE TABLE [#application] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC [Security].[Application.Filter]
			@predicate		= @applicationPredicate, 
			@isIncluded		= @isIncluded				OUTPUT,
			@isFiltered		= @applicationIsFiltered	OUTPUT,
			@number			= @applicationNumber		OUTPUT;
		IF (@applicationIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isIncluded = 1)
					INSERT [#permission] SELECT P.[PermissionId] FROM [Security].[Permission] P
					INNER JOIN	[#application]	X	ON	P.[PermissionApplicationId]	= X.[Id];
				ELSE
					INSERT [#permission] SELECT P.[PermissionId] FROM [Security].[Permission] P
					LEFT JOIN	[#application]	X	ON	P.[PermissionApplicationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isIncluded = 1)
					DELETE X FROM [#permission]	X
					LEFT JOIN (
						SELECT P.[PermissionId] FROM [Security].[Permission] P
						INNER JOIN	[#application]	X	ON	P.[PermissionApplicationId]	= X.[Id]
					)							P	ON	X.[Id]						= P.[PermissionId]
					WHERE P.[PermissionId] IS NULL;
				ELSE
					DELETE X FROM [#permission]	X
					LEFT JOIN (
						SELECT P.[PermissionId] FROM [Security].[Permission] P
						LEFT JOIN	[#application]	X	ON	P.[PermissionApplicationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)							P	ON	X.[Id]						= P.[PermissionId]
					WHERE P.[PermissionId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by role predicate
	DECLARE 
		@rolePredicate	XML,
		@roleIsFiltered	BIT,
		@roleNumber		INT;
	SELECT 
		@rolePredicate	= @predicate.query('/*/RolePredicate'),
		@roleIsFiltered	= @predicate.exist('/*/RolePredicate/*');
	IF (@roleIsFiltered = 1) BEGIN
		CREATE TABLE [#role] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC [Security].[Role.Filter]
			@predicate		= @rolePredicate, 
			@isIncluded		= @isIncluded		OUTPUT,
			@isFiltered		= @roleIsFiltered	OUTPUT,
			@number			= @roleNumber		OUTPUT;
		IF (@roleIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isIncluded = 1)
					INSERT [#permission] SELECT DISTINCT RP.[RolePermissionPermissionId] FROM [Security].[RolePermission] RP
					INNER JOIN	[#role]	X	ON	RP.[RolePermissionRoleId]	= X.[Id];
				ELSE
					INSERT [#permission] SELECT DISTINCT RP.[RolePermissionPermissionId] FROM [Security].[RolePermission] RP
					LEFT JOIN	[#role]	X	ON	RP.[RolePermissionRoleId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isIncluded = 1)
					DELETE X FROM [#permission]	X
					LEFT JOIN (
						SELECT DISTINCT RP.[RolePermissionPermissionId] FROM [Security].[RolePermission] RP
						INNER JOIN	[#role]	X	ON	RP.[RolePermissionRoleId]	= X.[Id]
					)					RP	ON	X.[Id]						= RP.[RolePermissionPermissionId]
					WHERE RP.[RolePermissionPermissionId] IS NULL;
				ELSE
					DELETE X FROM [#role]		X
					LEFT JOIN (
						SELECT DISTINCT RP.[RolePermissionPermissionId] FROM [Security].[RolePermission] RP
						LEFT JOIN	[#role]	X	ON	RP.[RolePermissionRoleId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)					RP	ON	X.[Id]						= RP.[RolePermissionPermissionId]
					WHERE RP.[RolePermissionPermissionId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by account predicate
	DECLARE 
		@accountPredicate	XML,
		@accountIsFiltered	BIT,
		@accountNumber		INT;
	SELECT 
		@accountPredicate	= @predicate.query('/*/AccountPredicate'),
		@accountIsFiltered	= @predicate.exist('/*/AccountPredicate/*');
	IF (@accountIsFiltered = 1) BEGIN
		CREATE TABLE [#account] 
		(
			[UserId]		UNIQUEIDENTIFIER,
			[ApplicationId]	UNIQUEIDENTIFIER,
			PRIMARY KEY CLUSTERED 
			(
				[UserId],
				[ApplicationId]
			)
		);
		EXEC [Security].[Account.Filter]
			@predicate		= @accountPredicate, 
			@isIncluded		= @isIncluded			OUTPUT,
			@isFiltered		= @accountIsFiltered	OUTPUT,
			@number			= @accountNumber		OUTPUT;
		IF (@accountIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isIncluded = 1)
					INSERT [#permission] SELECT DISTINCT RP.[RolePermissionPermissionId] FROM [Security].[RolePermission] RP
					INNER JOIN	[Security].[AccountRole]	AR	ON	RP.[RolePermissionRoleId]	= AR.[AccountRoleRoleId]
					INNER JOIN	[Security].[Account]		A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
					INNER JOIN	[#account]					X	ON	A.[AccountUserId]			= X.[UserId]	AND
																	A.[AccountApplicationId]	= X.[ApplicationId];
				ELSE
					INSERT [#permission] SELECT DISTINCT RP.[RolePermissionPermissionId] FROM [Security].[RolePermission] RP
					INNER JOIN	[Security].[AccountRole]	AR	ON	RP.[RolePermissionRoleId]	= AR.[AccountRoleRoleId]
					INNER JOIN	[Security].[Account]		A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
					LEFT JOIN	[#account]					X	ON	A.[AccountUserId]			= X.[UserId]	AND
																	A.[AccountApplicationId]	= X.[ApplicationId]
					WHERE COALESCE(X.[UserId], X.[ApplicationId]) IS NULL;
			ELSE
				IF (@isIncluded = 1)
					DELETE X FROM [#permission]	X
					LEFT JOIN (
						SELECT DISTINCT RP.[RolePermissionPermissionId] FROM [Security].[RolePermission]	RP
						INNER JOIN	[Security].[AccountRole]	AR	ON	RP.[RolePermissionRoleId]	= AR.[AccountRoleRoleId]
						INNER JOIN	[Security].[Account]		A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
						INNER JOIN	[#account]					X	ON	A.[AccountUserId]			= X.[UserId]	AND
																		A.[AccountApplicationId]	= X.[ApplicationId]
					)							RP	ON	X.[Id]	= RP.[RolePermissionPermissionId]
					WHERE RP.[RolePermissionPermissionId] IS NULL;
				ELSE
					DELETE X FROM [#permission]	X
					LEFT JOIN (
						SELECT DISTINCT RP.[RolePermissionPermissionId] FROM [Security].[RolePermission]	RP
						INNER JOIN	[Security].[AccountRole]	AR	ON	RP.[RolePermissionRoleId]	= AR.[AccountRoleRoleId]
						INNER JOIN	[Security].[Account]		A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
						LEFT JOIN	[#account]					X	ON	A.[AccountUserId]			= X.[UserId]	AND
																		A.[AccountApplicationId]	= X.[ApplicationId]
						WHERE COALESCE(X.[UserId], X.[ApplicationId]) IS NULL
					)							RP	ON	X.[Id]	= RP.[RolePermissionPermissionId]
					WHERE RP.[RolePermissionPermissionId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by application
	IF (@applicationId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT [#permission] SELECT P.[PermissionId] FROM [Security].[Permission] P
			WHERE P.[PermissionApplicationId] = @applicationId;
		ELSE
			DELETE X FROM [#permission]	X
			LEFT JOIN	(
				SELECT P.[PermissionId] FROM [Security].[Permission] P
				WHERE P.[PermissionApplicationId] = @applicationId
			)							P	ON	X.[Id]	= P.[PermissionId]
			WHERE P.[PermissionId] IS NULL;
		SET @isFiltered = 1;
	END

--	Apply filters
	SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/IsIncluded'));
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Security].[Permission] P;
	ELSE
		IF (@isIncluded = 1)
			SELECT @number = COUNT(*) FROM [#permission] X;
		ELSE
			SELECT @number = COUNT(*) FROM [Security].[Permission] P
			LEFT JOIN	[#permission]	X	ON	P.[PermissionId] = X.[Id]
			WHERE 
				P.[PermissionApplicationId] = ISNULL(@applicationId, P.[PermissionApplicationId])	AND
				X.[Id] IS NULL;

END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [Security].[Role.Filter]'
GO

ALTER PROCEDURE [Security].[Role.Filter]
(
	@predicate		XML,
	@emplacementId	UNIQUEIDENTIFIER	= NULL,
	@applicationId	UNIQUEIDENTIFIER	= NULL,
	@organisations	BIT					= 0,
	@isIncluded		BIT							OUTPUT,
	@isFiltered		BIT							OUTPUT,
	@number			INT							OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;
	
	SET @isFiltered = 0;

--	Filter by codes
	DECLARE @codes TABLE ([Code] NVARCHAR(MAX));
	INSERT @codes SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/Codes/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/Codes/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#role] SELECT DISTINCT R.[RoleId] FROM [Security].[Role] R
				INNER JOIN	@codes	X	ON	R.[RoleCode]	LIKE X.[Code];
			ELSE 
				INSERT [#role] SELECT DISTINCT R.[RoleId] FROM [Security].[Role] R
				LEFT JOIN	@codes	X	ON	R.[RoleCode]	LIKE X.[Code]
				WHERE X.[Code] IS NULL;
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#role]	X
				LEFT JOIN
				(
					SELECT DISTINCT R.[RoleId] FROM [Security].[Role] R
					INNER JOIN	@codes	X	ON	R.[RoleCode]	LIKE X.[Code]
				)						R	ON	X.[Id]	= R.[RoleId]
				WHERE R.[RoleId] IS NULL;
			ELSE
				DELETE X FROM [#role]	X
				LEFT JOIN
				(
					SELECT DISTINCT R.[RoleId] FROM [Security].[Role] R
					LEFT JOIN	@codes	X	ON	R.[RoleCode]	LIKE X.[Code]
					WHERE X.[Code] IS NULL
				)						R	ON	X.[Id]	= R.[RoleId]
				WHERE R.[RoleId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by descriptions
	DECLARE @descriptions TABLE ([Description] NVARCHAR(MAX));
	INSERT @descriptions SELECT DISTINCT * FROM [Common].[String.Entities](@predicate.query('/*/Descriptions/Value'));
	IF (@@ROWCOUNT > 0) BEGIN 
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/Descriptions/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#role] SELECT DISTINCT R.[RoleId] FROM [Security].[Role] R
				INNER JOIN	@descriptions	X	ON	R.[RoleDescription]	LIKE X.[Description];
			ELSE 
				INSERT [#role] SELECT DISTINCT R.[RoleId] FROM [Security].[Role] R
				LEFT JOIN	@descriptions	X	ON	R.[RoleDescription]	LIKE X.[Description]
				WHERE X.[Description] IS NULL;
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#role]	X
				LEFT JOIN
				(
					SELECT DISTINCT R.[RoleId] FROM [Security].[Role] R
					INNER JOIN	@descriptions	X	ON	R.[RoleDescription]	LIKE X.[Description]
				)						R	ON	X.[Id]	= R.[RoleId]
				WHERE R.[RoleId] IS NULL;
			ELSE
				DELETE X FROM [#role]	X
				LEFT JOIN
				(
					SELECT DISTINCT R.[RoleId] FROM [Security].[Role] R
					LEFT JOIN	@descriptions	X	ON	R.[RoleDescription]	LIKE X.[Description]
					WHERE X.[Description] IS NULL
				)						R	ON	X.[Id]	= R.[RoleId]
				WHERE R.[RoleId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by entities
	DECLARE @entities TABLE ([Id] UNIQUEIDENTIFIER);
	INSERT @entities SELECT DISTINCT * FROM [Security].[Role.Entities](@predicate.query('/*/Roles/Value/Role'));
	IF (@@ROWCOUNT > 0) BEGIN
		SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/Roles/IsIncluded'));
		IF (@isFiltered = 0)
			IF (@isIncluded = 1)
				INSERT [#role] SELECT * FROM @entities;
			ELSE
				INSERT [#role] SELECT R.[RoleId] FROM [Security].[Role] R
				WHERE R.[RoleId] NOT IN (SELECT * FROM @entities);
		ELSE
			IF (@isIncluded = 1)
				DELETE X FROM [#role] X WHERE X.[Id] NOT IN (SELECT * FROM @entities);
			ELSE
				DELETE X FROM [#role] X WHERE X.[Id] IN (SELECT * FROM @entities);
		SET @isFiltered = 1;
	END

--	Filter by emplacement predicate
	DECLARE 
		@emplacementPredicate	XML,
		@emplacementIsFiltered	BIT,
		@emplacementNumber		INT;
	SELECT 
		@emplacementPredicate	= @predicate.query('/*/EmplacementPredicate'),
		@emplacementIsFiltered	= @predicate.exist('/*/EmplacementPredicate/*');
	IF (@emplacementIsFiltered = 1) BEGIN
		CREATE TABLE [#emplacement] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC [Security].[Emplacement.Filter]
			@predicate		= @emplacementPredicate, 
			@isIncluded		= @isIncluded				OUTPUT,
			@isFiltered		= @emplacementIsFiltered	OUTPUT,
			@number			= @emplacementNumber		OUTPUT;
		IF (@emplacementIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isIncluded = 1)
					INSERT [#role] SELECT R.[RoleId] FROM [Security].[Role] R
					INNER JOIN	[#emplacement]	X	ON	R.[RoleEmplacementId]	= X.[Id];
				ELSE
					INSERT [#role] SELECT R.[RoleId] FROM [Security].[Role] R
					LEFT JOIN	[#emplacement]	X	ON	R.[RoleEmplacementId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isIncluded = 1)
					DELETE X FROM [#role]		X
					LEFT JOIN (
						SELECT R.[RoleId] FROM [Security].[Role] R
						INNER JOIN	[#emplacement]	X	ON	R.[RoleEmplacementId]	= X.[Id]
					)							R	ON	X.[Id]					= R.[RoleId]
					WHERE R.[RoleId] IS NULL;
				ELSE
					DELETE X FROM [#role]		X
					LEFT JOIN (
						SELECT R.[RoleId] FROM [Security].[Role] R
						LEFT JOIN	[#emplacement]	X	ON	R.[RoleEmplacementId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)							R	ON	X.[Id]					= R.[RoleId]
					WHERE R.[RoleId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by application predicate
	DECLARE 
		@applicationPredicate	XML,
		@applicationIsFiltered	BIT,
		@applicationNumber		INT;
	SELECT 
		@applicationPredicate	= @predicate.query('/*/ApplicationPredicate'),
		@applicationIsFiltered	= @predicate.exist('/*/ApplicationPredicate/*');
	IF (@applicationIsFiltered = 1) BEGIN
		CREATE TABLE [#application] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC [Security].[Application.Filter]
			@predicate		= @applicationPredicate, 
			@isIncluded		= @isIncluded				OUTPUT,
			@isFiltered		= @applicationIsFiltered	OUTPUT,
			@number			= @applicationNumber		OUTPUT;
		IF (@applicationIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isIncluded = 1)
					INSERT [#role] SELECT R.[RoleId] FROM [Security].[Role] R
					INNER JOIN	[#application]	X	ON	R.[RoleApplicationId]	= X.[Id];
				ELSE
					INSERT [#role] SELECT R.[RoleId] FROM [Security].[Role] R
					LEFT JOIN	[#application]	X	ON	R.[RoleApplicationId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isIncluded = 1)
					DELETE X FROM [#role]		X
					LEFT JOIN (
						SELECT R.[RoleId] FROM [Security].[Role] R
						INNER JOIN	[#application]	X	ON	R.[RoleApplicationId]	= X.[Id]
					)							R	ON	X.[Id]					= R.[RoleId]
					WHERE R.[RoleId] IS NULL;
				ELSE
					DELETE X FROM [#role]		X
					LEFT JOIN (
						SELECT R.[RoleId] FROM [Security].[Role] R
						LEFT JOIN	[#application]	X	ON	R.[RoleApplicationId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)							R	ON	X.[Id]					= R.[RoleId]
					WHERE R.[RoleId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by permission predicate
	DECLARE 
		@permissionPredicate	XML,
		@permissionIsFiltered	BIT,
		@permissionNumber		INT;
	SELECT 
		@permissionPredicate	= @predicate.query('/*/PermissionPredicate'),
		@permissionIsFiltered	= @predicate.exist('/*/PermissionPredicate/*');
	IF (@permissionIsFiltered = 1) BEGIN
		CREATE TABLE [#permission] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
		EXEC [Security].[Permission.Filter]
			@predicate		= @permissionPredicate, 
			@isIncluded		= @isIncluded			OUTPUT,
			@isFiltered		= @permissionIsFiltered	OUTPUT,
			@number			= @permissionNumber		OUTPUT;
		IF (@permissionIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isIncluded = 1)
					INSERT [#role] SELECT DISTINCT RP.[RolePermissionRoleId] FROM [Security].[RolePermission] RP
					INNER JOIN	[#permission]	X	ON	RP.[RolePermissionPermissionId]	= X.[Id];
				ELSE
					INSERT [#role] SELECT DISTINCT RP.[RolePermissionRoleId] FROM [Security].[RolePermission] RP
					LEFT JOIN	[#permission]	X	ON	RP.[RolePermissionPermissionId]	= X.[Id]
					WHERE X.[Id] IS NULL;
			ELSE
				IF (@isIncluded = 1)
					DELETE X FROM [#role]		X
					LEFT JOIN (
						SELECT DISTINCT RP.[RolePermissionRoleId] FROM [Security].[RolePermission] RP
						INNER JOIN	[#permission]	X	ON	RP.[RolePermissionPermissionId]	= X.[Id]
					)							RP	ON	X.[Id]							= RP.[RolePermissionRoleId]
					WHERE RP.[RolePermissionRoleId] IS NULL;
				ELSE
					DELETE X FROM [#role]		X
					LEFT JOIN (
						SELECT DISTINCT RP.[RolePermissionRoleId] FROM [Security].[RolePermission] RP
						LEFT JOIN	[#permission]	X	ON	RP.[RolePermissionPermissionId]	= X.[Id]
						WHERE X.[Id] IS NULL
					)							RP	ON	X.[Id]							= RP.[RolePermissionRoleId]
					WHERE RP.[RolePermissionRoleId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by account predicate
	DECLARE 
		@accountPredicate	XML,
		@accountIsFiltered	BIT,
		@accountNumber		INT;
	SELECT 
		@accountPredicate	= @predicate.query('/*/AccountPredicate'),
		@accountIsFiltered	= @predicate.exist('/*/AccountPredicate/*');
	IF (@accountIsFiltered = 1) BEGIN
		CREATE TABLE [#account] 
		(
			[UserId]		UNIQUEIDENTIFIER,
			[ApplicationId]	UNIQUEIDENTIFIER,
			PRIMARY KEY CLUSTERED 
			(
				[UserId],
				[ApplicationId]
			)
		);
		EXEC [Security].[Account.Filter]
			@predicate		= @accountPredicate, 
			@isIncluded		= @isIncluded			OUTPUT,
			@isFiltered		= @accountIsFiltered	OUTPUT,
			@number			= @accountNumber		OUTPUT;
		IF (@accountIsFiltered = 1) BEGIN
			IF (@isFiltered = 0)
				IF (@isIncluded = 1)
					INSERT [#role] SELECT DISTINCT AR.[AccountRoleRoleId] FROM [Security].[AccountRole] AR
					INNER JOIN	[Security].[Account]	A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
					INNER JOIN	[#account]				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																A.[AccountApplicationId]	= X.[ApplicationId];
				ELSE
					INSERT [#role] SELECT DISTINCT AR.[AccountRoleRoleId] FROM [Security].[AccountRole] AR
					INNER JOIN	[Security].[Account]	A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
					LEFT JOIN	[#account]				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																A.[AccountApplicationId]	= X.[ApplicationId]
					WHERE COALESCE(X.[UserId], X.[ApplicationId]) IS NULL;
			ELSE
				IF (@isIncluded = 1)
					DELETE X FROM [#role]	X
					LEFT JOIN (
						SELECT DISTINCT AR.[AccountRoleRoleId] FROM [Security].[AccountRole] AR
						INNER JOIN	[Security].[Account]	A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
						INNER JOIN	[#account]				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																	A.[AccountApplicationId]	= X.[ApplicationId]
					)						AR	ON	X.[Id]	= AR.[AccountRoleRoleId]
					WHERE AR.[AccountRoleRoleId] IS NULL;
				ELSE
					DELETE X FROM [#role]	X
					LEFT JOIN (
							SELECT DISTINCT AR.[AccountRoleRoleId] FROM [Security].[AccountRole] AR
						INNER JOIN	[Security].[Account]	A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
						LEFT JOIN	[#account]				X	ON	A.[AccountUserId]			= X.[UserId]	AND
																	A.[AccountApplicationId]	= X.[ApplicationId]
						WHERE COALESCE(X.[UserId], X.[ApplicationId]) IS NULL
					)						AR	ON	X.[Id]	= AR.[AccountRoleRoleId]
					WHERE AR.[AccountRoleRoleId] IS NULL;
			SET @isFiltered = 1;
		END
	END

--	Filter by emplacement
	IF (@emplacementId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT [#role] SELECT R.[RoleId] FROM [Security].[Role] R
			WHERE R.[RoleEmplacementId] = @emplacementId;
		ELSE
			DELETE X FROM [#role]	X
			LEFT JOIN	(
				SELECT R.[RoleId] FROM [Security].[Role] R
				WHERE R.[RoleEmplacementId] = @emplacementId
			)						R	ON	X.[Id]	= R.[RoleId]
			WHERE R.[RoleId] IS NULL;
		SET @isFiltered = 1;
	END

--	Filter by application
	IF (@applicationId IS NOT NULL) BEGIN
		IF (@isFiltered = 0)
			INSERT [#role] SELECT R.[RoleId] FROM [Security].[Role] R
			WHERE R.[RoleApplicationId] = @applicationId;
		ELSE
			DELETE X FROM [#role]	X
			LEFT JOIN	(
				SELECT R.[RoleId] FROM [Security].[Role] R
				WHERE R.[RoleApplicationId] = @applicationId
			)						R	ON	X.[Id]	= R.[RoleId]
			WHERE R.[RoleId] IS NULL;
		SET @isFiltered = 1;
	END

--	Apply filters
	SET @isIncluded = [Common].[Bool.Entity](@predicate.query('/*/IsIncluded'));
	IF (@isFiltered = 0)
		SELECT @number = COUNT(*) FROM [Security].[Role] R;
	ELSE
		IF (@isIncluded = 1)
			SELECT @number = COUNT(*) FROM [#role] X;
		ELSE
			SELECT @number = COUNT(*) FROM [Security].[Role] R
			LEFT JOIN	[#role]	X	ON	R.[RoleId] = X.[Id]
			WHERE 
				R.[RoleEmplacementId] = ISNULL(@emplacementId, R.[RoleEmplacementId])	AND
				R.[RoleApplicationId] = ISNULL(@applicationId, R.[RoleApplicationId])	AND
				X.[Id] IS NULL;

END
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
COMMIT TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO
