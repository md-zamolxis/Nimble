ALTER TABLE [Multicurrency].[Trade]  WITH CHECK ADD  CONSTRAINT [CK_Trade_OrganisationId_From_To] CHECK  (([Multicurrency].[Trade.IsValid]([TradeId],[TradeOrganisationId],[TradeFrom],[TradeTo])=(1)))
GO

ALTER TABLE [Multicurrency].[Trade] CHECK CONSTRAINT [CK_Trade_OrganisationId_From_To]
GO

ALTER TABLE [Owner].[EmployeeState]  WITH CHECK ADD  CONSTRAINT [CK_EmployeeState_EmployeeId_From_To] CHECK  (([Owner].[EmployeeState.IsValid]([EmployeeStateId],[EmployeeStateEmployeeId],[EmployeeFrom],[EmployeeTo])=(1)))
GO

ALTER TABLE [Owner].[EmployeeState] CHECK CONSTRAINT [CK_EmployeeState_EmployeeId_From_To]
GO
