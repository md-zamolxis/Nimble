SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Multicurrency'	AND
			O.[type]	= 'IF'				AND
			O.[name]	= 'Trade.Entity'))
	DROP FUNCTION [Multicurrency].[Trade.Entity];
GO

CREATE FUNCTION [Multicurrency].[Trade.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[TradeId], XOC.[TradeId], XOFT.[TradeId])	[Id],
		X.[OrganisationId],
		X.[Code],
		X.[CreatedOn],
		X.[Description],
		X.[From],
		X.[To],
		X.[Version],
		X.[AppliedOn]
	FROM
	(
		SELECT TOP 1
			X.[Id],
			O.[Id]	[OrganisationId],
			X.[Code],
			X.[CreatedOn],
			X.[Description],
			X.[From],
			X.[To],
			X.[Version],
			X.[AppliedOn]
		FROM
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',			'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Organisation')								[Organisation],
				X.[Entity].value('(Code/text())[1]',		'NVARCHAR(MAX)')	[Code],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('CreatedOn'))	[CreatedOn],
				X.[Entity].value('(Description/text())[1]',	'NVARCHAR(MAX)')	[Description],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('From'))		[From],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('To'))		[To],
				X.[Entity].value('(Version/text())[1]',		'VARBINARY(MAX)')	[Version],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('AppliedOn'))	[AppliedOn]
			FROM @entity.nodes('/*') X ([Entity])
		)															X
		OUTER APPLY [Owner].[Organisation.Entity](X.[Organisation])	O
	)									X
	LEFT JOIN	[Multicurrency].[Trade]	XI		ON	X.[Id]				= XI.[TradeId]
	LEFT JOIN	[Multicurrency].[Trade]	XOC		ON	X.[OrganisationId]	= XOC.[TradeOrganisationId]	AND
													X.[Code]			= XOC.[TradeCode]
	LEFT JOIN	[Multicurrency].[Trade]	XOFT	ON	X.[OrganisationId]	= XOFT.[TradeOrganisationId]	AND
													(XOFT.[TradeFrom] <= X.[AppliedOn] AND X.[AppliedOn] < XOFT.[TradeTo])
)
GO
