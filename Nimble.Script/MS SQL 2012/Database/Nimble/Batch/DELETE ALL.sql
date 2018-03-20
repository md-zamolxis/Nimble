--BEGIN TRAN;

DELETE [Common].[Hierarchy];
DELETE [Common].[Preset];
DELETE [Common].[Profile];
DELETE [Common].[Group];
DELETE [Common].[Split];
DELETE [Common].[Filestream];

DELETE [Maintenance].[Backup];
DELETE [Maintenance].[Operation];
DELETE [Maintenance].[Batch];

DELETE [Multilanguage].[Translation];
DELETE [Multilanguage].[Resource];
DELETE [Multilanguage].[Culture];

DELETE [Multicurrency].[Rate];
DELETE [Multicurrency].[Trade];
DELETE [Multicurrency].[Currency];

DELETE [Owner.Branch].[Bond];
DELETE [Owner.Branch].[Group];
DELETE [Owner.Branch].[Split];

DELETE [Owner.Post].[Bond];
DELETE [Owner.Post].[Group];
DELETE [Owner.Branch].[Split];

DELETE [Notification].[Trace];
DELETE [Notification].[Message];
DELETE [Notification].[Subscriber];
DELETE [Notification].[Publisher];

DELETE [Owner].[EmployeeBranch];
DELETE [Owner].[EmployeeState];
DELETE [Owner].[Employee];
DELETE [Owner].[Range];
DELETE [Owner].[Branch];
DELETE [Owner].[Post];
DELETE [Owner].[Layout];
DELETE [Owner].[Organisation];
DELETE [Owner].[Person];

DELETE [Security].[Log];
DELETE [Security].[AccountRole];
DELETE [Security].[Account];
DELETE [Security].[User];
DELETE [Security].[RolePermission];
DELETE [Security].[Role];
DELETE [Security].[Permission];
DELETE [Security].[Application];
DELETE [Security].[Emplacement];

--COMMIT TRAN;
--ROLLBACK TRAN;