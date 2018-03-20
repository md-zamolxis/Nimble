SET NOCOUNT ON;

BEGIN TRANSACTION;

BEGIN TRY 

	DECLARE @predicate XML = 
	N'
	<Predicate>
		<Users>
			<Value>
				<User>
					<Emplacement>
						<Code>ProvectaB2B.Central</Code>
					</Emplacement>
					<Code>sa</Code>
				</User>
			</Value>
		</Users>
	</Predicate>
	';

	IF OBJECT_ID('tempdb..#user') IS NOT NULL
		DROP TABLE [#user];

	CREATE TABLE [#user] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
	EXEC [Security].[User.Filter] 
		@predicate		= @predicate,
		@emplacementId	= NULL,
		@applicationId	= NULL,
		@isExcluded		= 0,
		@isFiltered		= 0,
		@number			= 0;

	DELETE P FROM [Common].[Preset]				P
	INNER JOIN	[Security].[Account]			A	ON	P.[PresetAccountId]			= A.[AccountId]
	INNER JOIN	[#user]							X	ON	A.[AccountUserId]			= X.[Id];
	PRINT CAST(@@ROWCOUNT AS NVARCHAR(MAX)) + ' presets removed.';

	DELETE L FROM [Security].[Log]				L
	INNER JOIN	[Security].[Account]			A	ON	L.[LogAccountId]			= A.[AccountId]
	INNER JOIN	[#user]								ON	A.[AccountUserId]			= X.[Id];
	PRINT CAST(@@ROWCOUNT AS NVARCHAR(MAX)) + ' logs removed.';

	DELETE AR FROM [Security].[AccountRole]		AR
	INNER JOIN	[Security].[Account]			A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
	INNER JOIN	[#user]							X	ON	A.[AccountUserId]			= X.[Id];
	PRINT CAST(@@ROWCOUNT AS NVARCHAR(MAX)) + ' user application roles removed.';

	DELETE A FROM [Security].[Account]			A
	INNER JOIN	[#user]							X	ON	A.[AccountUserId]			= X.[Id];
	PRINT CAST(@@ROWCOUNT AS NVARCHAR(MAX)) + ' user applications removed.';

	UPDATE P SET P.[PersonUserId] = NULL 
	FROM [Owner].[Person]						P
	INNER JOIN	[#user]							X	ON	P.[PersonUserId]			= X.[Id];
	PRINT CAST(@@ROWCOUNT AS NVARCHAR(MAX)) + ' person users updated.';

	DELETE U FROM [Security].[User]				U
	INNER JOIN	[#user]							X	ON	U.[UserId]					= X.[Id];
	PRINT CAST(@@ROWCOUNT AS NVARCHAR(MAX)) + ' users removed.';

	COMMIT TRANSACTION;
	
END TRY
BEGIN CATCH

	PRINT ERROR_MESSAGE();

	ROLLBACK TRANSACTION;
	
END CATCH
