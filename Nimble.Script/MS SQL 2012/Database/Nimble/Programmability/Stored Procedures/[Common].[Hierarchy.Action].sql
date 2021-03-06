SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF (EXISTS(
		SELECT * FROM [sys].[schemas]	S
		INNER JOIN	[sys].[objects]		O	ON	S.[schema_id]	= O.[schema_id]
		WHERE 
			S.[name]	= 'Common'	AND
			O.[type]	= 'P'		AND
			O.[name]	= 'Hierarchy.Action'))
	DROP PROCEDURE [Common].[Hierarchy.Action];
GO

CREATE PROCEDURE [Common].[Hierarchy.Action]
(
	@genericInput	XML,
	@number			INT	OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE 
		@permissionType	NVARCHAR(MAX),
		@entity			XML,
		@predicate		XML,
		@startNumber	INT,
		@endNumber		INT,
		@order			NVARCHAR(MAX),
		@emplacementId	UNIQUEIDENTIFIER,
		@applicationId	UNIQUEIDENTIFIER,
		@personId		UNIQUEIDENTIFIER,
		@organisations	XML,
		@isCountable	BIT,
		@guids			XML,
		@isExcluded		BIT,
		@isFiltered		BIT,
		@command		NVARCHAR(MAX);
	
	EXEC [Common].[GenericInput.Action] 
		@genericInput	= @genericInput,
		@permissionType = @permissionType	OUTPUT,
		@entity			= @entity			OUTPUT,
		@predicate		= @predicate		OUTPUT,
		@startNumber	= @startNumber		OUTPUT,
		@endNumber		= @endNumber		OUTPUT,
		@order			= @order			OUTPUT,
		@emplacementId	= @emplacementId	OUTPUT,
		@applicationId	= @applicationId	OUTPUT,
		@personId		= @personId			OUTPUT,
		@organisations	= @organisations	OUTPUT;

	DECLARE
		@code		NVARCHAR(MAX),
		@entityId	UNIQUEIDENTIFIER,
		@parentId	UNIQUEIDENTIFIER,
		@left		INT,
		@right		INT,
		@level		INT;

	SELECT
		@code		= H.[HierarchyCode],
		@entityId	= E.[EntityId],
		@parentId	= CASE WHEN E.[ParentId] = E.[EntityId] THEN NULL ELSE E.[ParentId] END,
		@left		= H.[HierarchyLeft],
		@right		= H.[HierarchyRight]
	FROM [Common].[Hierarchy.Entity](@entity)	E
	LEFT JOIN	[Common].[Hierarchy]			H	ON	E.[EntityId]	= H.[HierarchyEntityId];

	IF (@permissionType = 'HierarchySave') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			IF 
			(	@parentId IS NULL	OR
				EXISTS 
				(
					SELECT * FROM [Common].[Hierarchy] H
					WHERE H.[HierarchyEntityId] = @parentId
				)
			)
				IF 
				(
					@left IS NULL	OR
					@left > 0
				) BEGIN
					SET @parentId = ISNULL(@parentId, @entityId);
					IF (NOT EXISTS (
							SELECT * FROM [Common].[Hierarchy]	H
							INNER JOIN	[Common].[Hierarchy]	P	ON	H.[HierarchyCode]	= P.[HierarchyCode]
							WHERE 
								H.[HierarchyLeft] BETWEEN P.[HierarchyLeft] AND P.[HierarchyRight]	AND
								H.[HierarchyEntityId]	= @entityId									AND
								P.[HierarchyEntityId]	= @parentId									AND
								H.[HierarchyLevel]		= P.[HierarchyLevel] + 1
						)
					) BEGIN
--	Remove node
						IF (@left IS NOT NULL) BEGIN
							DELETE H FROM [Common].[Hierarchy] H
							WHERE H.[HierarchyEntityId] = @entityId;
							UPDATE H SET 
								H.[HierarchyLeft]	=	CASE 
															WHEN H.[HierarchyLeft] BETWEEN @left AND @right		THEN H.[HierarchyLeft] - 1
															WHEN H.[HierarchyLeft] > @right						THEN H.[HierarchyLeft] - 2
															ELSE H.[HierarchyLeft]	
														END,
								H.[HierarchyRight]	=	CASE
															WHEN H.[HierarchyRight] BETWEEN @left AND @right	THEN H.[HierarchyRight] - 1
															WHEN H.[HierarchyRight] > @right					THEN H.[HierarchyRight] - 2
															ELSE H.[HierarchyRight]	
														END,
								H.[HierarchyLevel] =	CASE 
															WHEN H.[HierarchyLeft] BETWEEN @left AND @right		THEN H.[HierarchyLevel] - 1 
															ELSE H.[HierarchyLevel] 
														END
							FROM [Common].[Hierarchy] H
							WHERE H.[HierarchyCode] = @code;
						END
--	Add node
						IF (@parentId = @entityId)
							SELECT 
								@code	= ISNULL(@code, CAST(NEWID() AS NVARCHAR(MAX))),
								@right	= 0,
								@level	= 0;
						ELSE BEGIN
							SELECT 
								@code	= H.[HierarchyCode],
								@right	= H.[HierarchyRight]
							FROM [Common].[Hierarchy] H
							WHERE H.[HierarchyEntityId] = @parentId;
							SELECT @level = COUNT(*)
							FROM [Common].[Hierarchy]			H
							INNER JOIN	[Common].[Hierarchy]	P	ON	H.[HierarchyCode]	= P.[HierarchyCode]
							WHERE 
								H.[HierarchyLeft] BETWEEN P.[HierarchyLeft] AND P.[HierarchyRight]	AND
								H.[HierarchyEntityId]	= @parentId;
							UPDATE H SET 
								H.[HierarchyLeft]	=	CASE	
															WHEN H.[HierarchyLeft] > @right		THEN H.[HierarchyLeft] + 2
															ELSE H.[HierarchyLeft]
														END,
								H.[HierarchyRight]	=	CASE
															WHEN H.[HierarchyRight] >= @right	THEN H.[HierarchyRight] + 2
															ELSE H.[HierarchyRight]
														END
							FROM [Common].[Hierarchy] H
							WHERE 
								H.[HierarchyCode] = @code		AND
								H.[HierarchyRight] >= @right;
						END
						INSERT [Common].[Hierarchy] 
						(
							[HierarchyCode],
							[HierarchyEntityId],
							[HierarchyLeft],
							[HierarchyRight],
							[HierarchyLevel]) 
						VALUES 
						(
							@code, 
							@entityId, 
							@right, 
							@right + 1, 
							@level
						);
						SET @number = @@ROWCOUNT;
					END 
				END
				ELSE
					RAISERROR 
					(
						'Root item cannot be modified.', 
						16, 
						0
					);
			ELSE
				RAISERROR 
				(
					'Invalid parent specified.', 
					16, 
					0
				);
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END
	
	IF (@permissionType = 'HierarchyRemove') BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			IF (@left = 0)
				RAISERROR 
				(
					'Root item cannot be modified.', 
					16, 
					0
				);
			ELSE
				IF (@left IS NOT NULL) BEGIN
					DELETE H FROM [Common].[Hierarchy] H
					WHERE H.[HierarchyEntityId] = @entityId;
					UPDATE H SET 
						H.[HierarchyLeft]	=	CASE 
													WHEN H.[HierarchyLeft] BETWEEN @left AND @right		THEN H.[HierarchyLeft] - 1
													WHEN H.[HierarchyLeft] > @right						THEN H.[HierarchyLeft] - 2
													ELSE H.[HierarchyLeft]	
												END,
						H.[HierarchyRight]	=	CASE
													WHEN H.[HierarchyRight] BETWEEN @left AND @right	THEN H.[HierarchyRight] - 1
													WHEN H.[HierarchyRight] > @right					THEN H.[HierarchyRight] - 2
													ELSE H.[HierarchyRight]	
												END,
						H.[HierarchyLevel] =	CASE 
													WHEN H.[HierarchyLeft] BETWEEN @left AND @right		THEN H.[HierarchyLevel] - 1 
													ELSE H.[HierarchyLevel] 
												END
					FROM [Common].[Hierarchy] H
					WHERE H.[HierarchyCode] = @code;
					SET @number = @@ROWCOUNT;
				END
			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC [Error].[General.Throw];
		END CATCH;	
	END

END
GO
