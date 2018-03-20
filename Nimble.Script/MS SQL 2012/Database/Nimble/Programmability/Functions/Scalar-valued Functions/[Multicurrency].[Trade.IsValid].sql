SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multicurrency'	AND
			O.[type]	= 'C'				AND
			O.[name]	= 'CK_Trade_Id_OrganisationId_From_To'))
	ALTER TABLE [Multicurrency].[Trade] DROP CONSTRAINT [CK_Trade_Id_OrganisationId_From_To];
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multicurrency'	AND
			O.[type]	= 'FN'				AND
			O.[name]	= 'Trade.IsValid'))
	DROP FUNCTION [Multicurrency].[Trade.IsValid];
GO

CREATE FUNCTION [Multicurrency].[Trade.IsValid]
(
	@id				UNIQUEIDENTIFIER,
	@organisationId	UNIQUEIDENTIFIER,
	@from			DATETIMEOFFSET,
	@to				DATETIMEOFFSET
)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 1;
	IF (EXISTS (
			SELECT * FROM [Multicurrency].[Trade] T
			WHERE 
				T.[TradeId]				<>	@id				AND
				T.[TradeOrganisationId] =	@organisationId	AND 
				(
					(T.[TradeFrom] <= @from AND @from < T.[TradeTo])	OR
					(@from <= T.[TradeFrom] AND T.[TradeFrom] < @to)
				)
		)
	) SET @isValid = 0;
	RETURN @isValid;
END
GO

ALTER TABLE [Multicurrency].[Trade] WITH CHECK ADD CONSTRAINT [CK_Trade_Id_OrganisationId_From_To] CHECK ((
	[Multicurrency].[Trade.IsValid]
	(
		[TradeId],
		[TradeOrganisationId],
		[TradeFrom],
		[TradeTo]
	)=(1)
))
GO

ALTER TABLE [Multicurrency].[Trade] CHECK CONSTRAINT [CK_Trade_Id_OrganisationId_From_To]
GO
