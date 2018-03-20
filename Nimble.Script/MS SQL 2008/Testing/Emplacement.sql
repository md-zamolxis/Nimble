DECLARE 
	@genericInput	XML,
	@number			INT,
	@permissionType	NVARCHAR(MAX),
	@entity			XML,
	@predicate		XML,
	@startNumber	INT,
	@endNumber		INT,
	@isExclude		BIT,
	@order			NVARCHAR(MAX),
	@emplacementId	UNIQUEIDENTIFIER,
	@organisations	XML;

SET @genericInput = 
N'
	<GenericInput>
		<PermissionType>EmplacementSearch</PermissionType>
		<Entity>
			<Id></Id>
			<Code>Nimble.Central</Code>
			<Description></Description>
			<IsAdministrative>true</IsAdministrative>
			<Version>AAAAAAAAB94=</Version>
		</Entity>
		<Predicate>
			<Order>ORDER BY [EmplacementCode] ASC</Order>
			<Pager>
				<Index>0</Index>
				<Size>2</Size>
				<StartLag>0</StartLag>
			</Pager>
			<Codes>
				<Value>
					<string>%Central%</string>
				</Value>
			</Codes>
			<Emplacements>
				<Emplacement>
					<Id>88D50FF5-DB7C-E111-84A8-082E5F31C0FC</Id>
				</Emplacement>
			</Emplacements>
		</Predicate>
		<Emplacement>
			<Id>88D50FF5-DB7C-E111-84A8-082E5F31C0F1</Id>
		</Emplacement>
	</GenericInput>
';

EXEC [Common].[GenericInput.Map] 
	@genericInput	= @genericInput,
	@permissionType = @permissionType	OUTPUT,
	@entity			= @entity			OUTPUT,
	@predicate		= @predicate		OUTPUT,
	@startNumber	= @startNumber		OUTPUT,
	@endNumber		= @endNumber		OUTPUT,
	@isExclude		= @isExclude		OUTPUT,
	@order			= @order			OUTPUT,
	@emplacementId	= @emplacementId	OUTPUT,
	@organisations	= @organisations	OUTPUT;

SELECT 
	@permissionType,
	@entity,
	@predicate,
	@startNumber,
	@endNumber,
	@isExclude,
	@order,
	@emplacementId,
	@organisations;

--SELECT * FROM [Security].[Emplacement] FOR XML RAW('Emplacement'), ELEMENTS;

EXEC [Security].[Emplacement.Action] 
	@genericInput	= @genericInput,
	@number			= @number		OUTPUT;

SELECT @number;


DECLARE @genericInput XML = 
N'
<GenericInputOfEmplacementEmplacementPredicateP6V9blsD xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
  <Application xmlns:d2p1="http://schemas.datacontract.org/2004/07/Nimble.Client.Model.Framework.Security" i:nil="true" />
  <Emplacement xmlns:d2p1="http://schemas.datacontract.org/2004/07/Nimble.Client.Model.Framework.Security" i:nil="true" />
  <Entity xmlns:d2p1="http://schemas.datacontract.org/2004/07/Nimble.Client.Model.Framework.Security" i:nil="true" />
  <PermissionType>EmplacementSearch</PermissionType>
  <Predicate xmlns:d2p1="http://schemas.datacontract.org/2004/07/Nimble.Client.Model.Framework.Security">
    <Hierarchy xmlns:d3p1="http://schemas.datacontract.org/2004/07/Nimble.Client.Common" i:nil="true" />
    <Order i:nil="true" />
    <Pager>
      <Count>0</Count>
      <Index>0</Index>
      <Number>0</Number>
      <Size>2</Size>
      <StartLag>0</StartLag>
    </Pager>
    <Sorts i:nil="true" />
    <Codes xmlns:d3p1="http://schemas.datacontract.org/2004/07/Nimble.Client.Model">
      <Value xmlns:d4p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
        <string>Nimble%</string>
      </Value>
    </Codes>
    <Descriptions xmlns:d3p1="http://schemas.datacontract.org/2004/07/Nimble.Client.Model" i:nil="true" />
    <Emplacements xmlns:d3p1="http://schemas.datacontract.org/2004/07/Nimble.Client.Model">
      <Value>
        <Emplacement>
          <Code>Nimble.Central</Code>
          <CultureId i:nil="true" />
          <Description i:nil="true" />
          <Id i:nil="true" />
          <IsAdministrative>false</IsAdministrative>
          <Version i:nil="true" />
        </Emplacement>
      </Value>
    </Emplacements>
    <IsAdministrative i:nil="true" />
  </Predicate>
</GenericInputOfEmplacementEmplacementPredicateP6V9blsD>
', @number INT;

EXEC [Security].[Emplacement.Action] 
	@genericInput	= @genericInput,
    @number			= @number	OUTPUT
SELECT @number;
