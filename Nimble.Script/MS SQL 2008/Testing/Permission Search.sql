--SELECT * FROM [Security].[Emplacement] E;

--SELECT * FROM [Security].[Application] A;

--SELECT * FROM [Security].[Permission] P;

--SELECT * FROM [Security].[Role] R;

--SELECT * FROM [Security].[User] U;

/*
SELECT 
	AR.*,
	U.[UserCode],
	U.[UserPassword],
	R.[RoleCode],
	U.*,
	R.*
FROM [Security].[AccountRole]		AR
INNER JOIN	[Security].[Account]	A	ON	AR.[AccountRoleAccountId]	= A.[AccountId]
INNER JOIN	[Security].[User]		U	ON	A.[AccountUserId]			= U.[UserId]
INNER JOIN	[Security].[Role]		R	ON	AR.[AccountRoleRoleId]		= R.[RoleId]
*/

DECLARE 
	@genericInput XML = 
	N'
	<GenericInput>
		<PermissionType>PermissionSearch</PermissionType>
		<Predicate>
			<Order>ORDER BY [ApplicationCode], [PermissionCategory] DESC, [PermissionCode] DESC</Order>
			<AccountPredicate>
				<UserPredicate>
					<Codes>
						<Value>
							<string>Piv%</string>
						</Value>
					</Codes>
				</UserPredicate>
			</AccountPredicate>
		</Predicate>
		<Emplacement>
			<Code>ProvectaB2B.Central</Code>
		</Emplacement>
		<Application>
			<Code>ProvectaB2B.Server.Iis</Code>
		</Application>
	</GenericInput>
	',
	@number	INT;

EXEC [Security].[Permission.Action] 
	@genericInput	= @genericInput,
    @number			= @number		OUTPUT
