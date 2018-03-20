SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'IF'			AND
			O.[name]	= 'Profile.Entity'))
	DROP FUNCTION [Common].[Profile.Entity];
GO

CREATE FUNCTION [Common].[Profile.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN
(
	SELECT
		X.[Entity].value('(Id/text())[1]',	'UNIQUEIDENTIFIER')	[Id],
		P.*
	FROM @entity.nodes('/*') X ([Entity])
	OUTER APPLY
	(
		SELECT
			X.[Entity].value('(Code/text())[1]',	'NVARCHAR(MAX)')	[Code],
			X.[Entity].value('(Value/text())[1]',	'NVARCHAR(MAX)')	[Value]
		FROM @entity.nodes('/*/Properties/Property') X ([Entity])
	) P
)
GO
