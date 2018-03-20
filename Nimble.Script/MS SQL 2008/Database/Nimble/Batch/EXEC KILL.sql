-- This T-SQL batch kiils all processes, running on databases listed below.
-- Note: database name supports LIKE pattern.

SET NOCOUNT ON;

DECLARE @entity XML= N'
<Databases Kill="false">
	<Database Name="%CIWEM_MSCRM%" />
	<Database Name="%-MSCRM_CONFIG%" />
</Databases>
';

DECLARE @databaseProcesses TABLE 
(
	 [Id]				INT
	,[DatabaseId]		INT
	,[DatabaseName]		NVARCHAR(MAX)
	,[ProcessId]		INT
	,[ProcessLoggedOn]	DATETIMEOFFSET
	,[ProcessDomain]	NVARCHAR(MAX)
	,[ProcessUserName]	NVARCHAR(MAX)
	,[ProcessLoginName]	NVARCHAR(MAX)
	,[Status]			NVARCHAR(MAX)
);

INSERT @databaseProcesses
SELECT
	 ROW_NUMBER() OVER(ORDER BY SD.[name] ASC, SP.[spid] ASC)
	,SD.[dbid]
	,SD.[name]
	,SP.[spid]
	,SP.[login_time]
	,SP.[nt_domain]
	,SP.[nt_username]
	,SP.[loginame]
	,SP.[cmd]
FROM [sys].[sysprocesses]		SP
INNER JOIN [sys].[sysdatabases]	SD	ON	SP.[dbid]	=		SD.[dbid]
INNER JOIN
(
	SELECT X.[Entity].value('(@Name)[1]', 'NVARCHAR(MAX)') [Name]
	FROM @entity.nodes('/*/Database') X ([Entity])
)								X	ON	SD.[name]	LIKE	X.[Name];

IF ((SELECT X.[Entity].value('(@Kill)[1]', 'BIT')
	 FROM @entity.nodes('/*') X ([Entity])) = 1)
BEGIN
	DECLARE
		 @minId		INT
		,@maxId		INT
		,@processId	INT
		,@command	NVARCHAR(MAX);
		
	SELECT 
		 @minId = MIN(X.[Id])
		,@maxId = MAX(X.[Id])
	FROM @databaseProcesses X;

	WHILE @minId <= @maxId
	BEGIN
		SELECT @processId = X.[ProcessId] FROM @databaseProcesses X WHERE X.[Id] = @minId;
		BEGIN TRY
			SET @command = 'KILL ' + CAST(@processId AS NVARCHAR(MAX));
			EXEC (@command);
			SET @command = 'KILLED';
		END TRY
		BEGIN CATCH
			SET @command = ERROR_MESSAGE();
		END CATCH
		UPDATE X SET X.[Status] = @command FROM @databaseProcesses X WHERE X.[Id] = @minId;
		SET @minId = @minId + 1;
	END
END

SELECT * FROM @databaseProcesses X;
