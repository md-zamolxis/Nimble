SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Maintenance'	AND
			O.[type]	= 'P'			AND
			O.[name]	= 'Database.Size'))
	DROP PROCEDURE [Maintenance].[Database.Size];
GO

CREATE PROCEDURE [Maintenance].[Database.Size]
(
	@name	NVARCHAR(MAX)	OUTPUT,
	@size	INT				OUTPUT
)
AS
BEGIN

	SET @name = ISNULL(@name, DB_NAME());

	DECLARE @databases TABLE 
	(
		[Name]		NVARCHAR(MAX),
		[Size]		INT,
		[Remarks]	NVARCHAR(MAX)
	)

	INSERT @databases EXEC [dbo].[sp_databases];

	SELECT @size = D.[Size] FROM @databases D WHERE D.[Name] = @name;

END
GO
