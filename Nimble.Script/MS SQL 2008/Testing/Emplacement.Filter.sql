SET NOCOUNT ON;

DECLARE 
	@predicate		XML,
	@emplacementId	UNIQUEIDENTIFIER = '88D50FF5-DB7C-E111-84A8-082E5F31C0FC',
	@isFiltered		BIT,
	@total			INT;

SET @predicate = 
'
<EmplacementPredicate>
    <Codes>
        <Value>
            <string>%Central1</string>
            <string>%Central2</string>
        </Value>
    </Codes>
    <Emplacements>
		<Emplacement>
			<Id>88D50FF5-DB7C-E111-84A8-082E5F31C0FC</Id>
		</Emplacement>
    </Emplacements>
</EmplacementPredicate>
';

DROP TABLE [#emplacement];
CREATE TABLE [#emplacement] ([Id] UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED);
EXEC [Security].[Emplacement.Filter]
	@predicate		= @predicate,
	@emplacementId	= @emplacementId,
	@isFiltered		= @isFiltered	OUTPUT,
	@total			= @total		OUTPUT;

SELECT
	@isFiltered,
	@total;

SELECT * FROM [#emplacement] X;

SELECT * FROM [Security].[Emplacement]