SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Owner'	AND
			O.[type]	= 'IF'		AND
			O.[name]	= 'Range.Entity'))
	DROP FUNCTION [Owner].[Range.Entity];
GO

CREATE FUNCTION [Owner].[Range.Entity](@entity XML)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		COALESCE(XI.[RangeId], XBC.[RangeId], XNF.[RangeId], XNT.[RangeId]) [Id],
		X.[BranchId],
		X.[Code],
		X.[IpDataFrom],
		X.[IpDataTo],
		X.[IpNumberFrom],
		X.[IpNumberTo],
		X.[LockedOn],
		X.[Description],
		X.[Version]
	FROM 
	(
		SELECT TOP 1
			X.[Id],
			B.[Id]	[BranchId],
			X.[Code],
			X.[IpDataFrom],
			X.[IpDataTo],
			X.[IpNumberFrom],
			X.[IpNumberTo],
			X.[LockedOn],
			X.[Description],
			X.[Version]
		FROM 
		(
			SELECT
				X.[Entity].value('(Id/text())[1]',				'UNIQUEIDENTIFIER')	[Id],
				X.[Entity].query('Branch')											[Branch],
				X.[Entity].value('(Code/text())[1]',			'NVARCHAR(MAX)')	[Code],
				X.[Entity].value('(IpDataFrom/text())[1]',		'NVARCHAR(MAX)')	[IpDataFrom],
				X.[Entity].value('(IpDataTo/text())[1]',		'NVARCHAR(MAX)')	[IpDataTo],
				X.[Entity].value('(IpNumberFrom/text())[1]',	'BIGINT')			[IpNumberFrom],
				X.[Entity].value('(IpNumberTo/text())[1]',		'BIGINT')			[IpNumberTo],
				[Common].[DateTimeOffset.Entity](X.[Entity].query('LockedOn'))		[LockedOn],
				X.[Entity].value('(Description/text())[1]',		'NVARCHAR(MAX)')	[Description],
				X.[Entity].value('(Version/text())[1]',			'VARBINARY(MAX)')	[Version]
			FROM @entity.nodes('/*') X ([Entity])
		)												X
		OUTER APPLY [Owner].[Branch.Entity](X.[Branch])	B
	)								X
	LEFT JOIN	[Owner].[Range]		XI	ON	X.[Id]				= XI.[RangeId]
	LEFT JOIN	[Owner].[Range]		XBC	ON	X.[BranchId]		= XBC.[RangeBranchId]	AND
											X.[Code]			= XBC.[RangeCode]
	LEFT JOIN	[Owner].[Range]		XNF	ON	X.[BranchId]		= XNF.[RangeBranchId]	AND
											X.[IpNumberFrom]	BETWEEN	XNF.[RangeIpNumberFrom] AND XNF.[RangeIpNumberTo]
	LEFT JOIN	[Owner].[Range]		XNT	ON	X.[BranchId]		= XNT.[RangeBranchId]	AND
											X.[IpNumberTo]		BETWEEN	XNT.[RangeIpNumberFrom] AND XNT.[RangeIpNumberTo]
)
GO
