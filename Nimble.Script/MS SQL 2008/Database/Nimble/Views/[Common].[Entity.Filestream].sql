SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'V'		AND
			O.[name]	= 'Entity.Filestream'))
	DROP VIEW [Common].[Entity.Filestream];
GO

CREATE VIEW [Common].[Entity.Filestream]
AS
SELECT 
	F.[FilestreamId],
	F.[FilestreamEmplacementId],
	F.[FilestreamPersonId],
	F.[FilestreamOrganisationId],
	F.[FilestreamEntityId],
	F.[FilestreamCode],
	F.[FilestreamReferenceId],
	F.[FilestreamCreatedOn],
	F.[FilestreamName],
	F.[FilestreamDescription],
	F.[FilestreamExtension],
	F.[FilestreamIsDefault],
	F.[FilestreamUrl],
	F.[FilestreamThumbnailId],
	F.[FilestreamThumbnailWidth],
	F.[FilestreamThumbnailHeight],
	F.[FilestreamThumbnailExtension],
	F.[FilestreamThumbnailUrl]
FROM [Common].[Filestream] F
GO
