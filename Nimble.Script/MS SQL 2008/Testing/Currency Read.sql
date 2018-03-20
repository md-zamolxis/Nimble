--SELECT * FROM [Owner].[Organisation] O;

--SELECT * FROM [Security].[Emplacement] E;

--SELECT * FROM [Multicurrency].[Currency] C;

DECLARE @genericInput XML = 
N'
<GenericInput>
	<PermissionType>CurrencyRead</PermissionType>
	<Entity>
		<Organisation>
			<Code>Nimble</Code>
			<Emplacement>
				<Code>Nimble.Central</Code>
			</Emplacement>
		</Organisation>
		<IsDefault>true</IsDefault>
	</Entity>
</GenericInput>
';

EXEC [Multicurrency].[Currency.Action] 
	@genericInput	= @genericInput, -- xml
    @number			= 0 -- int
