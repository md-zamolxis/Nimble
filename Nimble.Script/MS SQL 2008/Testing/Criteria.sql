SET NOCOUNT ON;

DECLARE @entity XML;
SET @entity = 
'
<PersonPredicate>
    <LastNames>
		<IsAdministrative p4:nil="true" xmlns:p4="http://www.w3.org/2001/XMLSchema-instance"></IsAdministrative>
        <Value>
            <string>Duja</string>
            <string>Marcu</string>
        </Value>
    </LastNames>
    <FirstNames>
        <Exclude>true</Exclude>
        <Value>
            <string>Corneliu</string>
        </Value>
    </FirstNames>
</PersonPredicate>
';

DECLARE @isExclude BIT;
SET @isExclude = [Common].[Bool](@entity.query('/*/LastNames/IsAdministrative'))
SELECT @isExclude;

SELECT DISTINCT * FROM [Common].[String](@entity.query('/*/LastNames/Value'));

DROP TABLE [#entities];
CREATE TABLE [#entities] ([Id] UNIQUEIDENTIFIER);

DECLARE 
    @isFiltered BIT,
    @exclude    BIT;

SET @isFiltered = 0;

--	Filter by last names
DECLARE @lastNames TABLE ([LastName] NVARCHAR(MAX));
INSERT @lastNames SELECT DISTINCT * 
FROM [Commons].[Strings](@entity.query('/*/LastNames/Value/string'));

IF (EXISTS(SELECT TOP 1 * FROM @lastNames)) BEGIN 

    SELECT @exclude = [Entities].[Entity].value('(text())[1]', 'BIT')
    FROM @entity.nodes('/*/LastNames/Exclude') [Entities] ([Entity])

	IF (@isFiltered = 0)
	    IF (@exclude = 0)
		    INSERT [#entities] SELECT DISTINCT P.[PersonId] FROM [Owners].[Persons] P
		    INNER JOIN	@lastNames			FN	ON	P.[PersonLastName]	LIKE FN.[LastName];
		ELSE 
		    INSERT [#entities] SELECT DISTINCT P.[PersonId] FROM [Owners].[Persons] P
		    INNER JOIN	@lastNames			FN	ON	P.[PersonLastName]	NOT LIKE FN.[LastName];
	ELSE
	    IF (@exclude = 0)
		    DELETE [#entities] FROM [#entities] E
		    LEFT JOIN	(
		        SELECT DISTINCT P.[PersonId] FROM [Owners].[Persons] P
		        INNER JOIN	@lastNames			FN	ON	P.[PersonLastName]	LIKE FN.[LastName]
		    )	P	ON	E.[Id]				= P.[PersonId]
		    WHERE P.[PersonId] IS NULL;
		ELSE
		    DELETE [#entities] FROM [#entities] E
		    LEFT JOIN	(
		        SELECT DISTINCT P.[PersonId] FROM [Owners].[Persons] P
		        INNER JOIN	@lastNames			FN	ON	P.[PersonLastName]	NOT LIKE FN.[LastName]
		    )	P	ON	E.[Id]				= P.[PersonId]
		    WHERE P.[PersonId] IS NULL;

	SET @isFiltered = 1;

END

--	Filter by first names
DECLARE @firstNames TABLE ([FirstName] NVARCHAR(MAX));
INSERT @firstNames SELECT DISTINCT * 
FROM [Commons].[Strings](@entity.query('/*/FirstNames/Value/string'));

IF (EXISTS(SELECT TOP 1 * FROM @firstNames)) BEGIN 

    SELECT @exclude = [Entities].[Entity].value('(text())[1]', 'BIT')
    FROM @entity.nodes('/*/FirstNames/Exclude') [Entities] ([Entity])

	IF (@isFiltered = 0)
	    IF (@exclude = 0)
		    INSERT [#entities] SELECT DISTINCT P.[PersonId] FROM [Owners].[Persons] P
		    INNER JOIN	@firstNames			FN	ON	P.[PersonFirstName]	LIKE FN.[FirstName];
		ELSE 
		    INSERT [#entities] SELECT DISTINCT P.[PersonId] FROM [Owners].[Persons] P
		    INNER JOIN	@firstNames			FN	ON	P.[PersonFirstName]	NOT LIKE FN.[FirstName];
	ELSE
	    IF (@exclude = 0)
		    DELETE [#entities] FROM [#entities] E
		    LEFT JOIN	(
		        SELECT DISTINCT P.[PersonId] FROM [Owners].[Persons] P
		        INNER JOIN	@firstNames			FN	ON	P.[PersonFirstName]	LIKE FN.[FirstName]
		    )	P	ON	E.[Id]				= P.[PersonId]
		    WHERE P.[PersonId] IS NULL;
		ELSE
		    DELETE [#entities] FROM [#entities] E
		    LEFT JOIN	(
		        SELECT DISTINCT P.[PersonId] FROM [Owners].[Persons] P
		        INNER JOIN	@firstNames			FN	ON	P.[PersonFirstName]	NOT LIKE FN.[FirstName]
		    )	P	ON	E.[Id]				= P.[PersonId]
		    WHERE P.[PersonId] IS NULL;

	SET @isFiltered = 1;

END


SELECT * FROM [#entities] E
INNER JOIN [Owners].[Persons] P ON E.[Id] = P.[PersonId];



--SELECT COUNT(*) FROM [Owners].[Persons] P;

/*
SELECT * FROM [Owners].[Persons] P
WHERE 
    P.[PersonLastName] LIKE 'Duja' AND 
    P.[PersonFirstName] NOT LIKE 'Corneliu'
*/