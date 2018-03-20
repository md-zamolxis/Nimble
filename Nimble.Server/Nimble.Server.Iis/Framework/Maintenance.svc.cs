#region Using

using System.ServiceModel.Activation;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Maintenance;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Logic.Framework;
using Nimble.Server.Iis.Framework.Interface;

#endregion Using

namespace Nimble.Server.Iis.Framework
{
    [AspNetCompatibilityRequirements(RequirementsMode = AspNetCompatibilityRequirementsMode.Allowed)]
    public class Maintenance : IMaintenance
    {
        public int? DatabaseSize()
        {
            return MaintenanceLogic.InstanceCheck(PermissionType.BackupCreate).DatabaseSize();
        }

        #region Backup

        public Backup BackupCreate(Backup backup)
        {
            return MaintenanceLogic.InstanceCheck(PermissionType.BackupCreate).BackupCreate(backup);
        }

        public Backup BackupRead(Backup backup)
        {
            return MaintenanceLogic.InstanceCheck(PermissionType.BackupRead).BackupRead(backup);
        }

        public GenericOutput<Backup> BackupDelete(BackupPredicate backupPredicate)
        {
            return MaintenanceLogic.InstanceCheck(PermissionType.BackupDelete).BackupDelete(backupPredicate);
        }

        public GenericOutput<Backup> BackupSearch(BackupPredicate backupPredicate)
        {
            return MaintenanceLogic.InstanceCheck(PermissionType.BackupSearch).BackupSearch(backupPredicate);
        }

        #endregion Backup

        #region Batch

        public Batch BatchCreate(Batch batch)
        {
            return MaintenanceLogic.InstanceCheck(PermissionType.BatchCreate).BatchCreate(batch);
        }

        public Batch BatchRead(Batch batch)
        {
            return MaintenanceLogic.InstanceCheck(PermissionType.BatchRead).BatchRead(batch);
        }

        public GenericOutput<Batch> BatchDelete(BatchPredicate batchPredicate)
        {
            return MaintenanceLogic.InstanceCheck(PermissionType.BatchDelete).BatchDelete(batchPredicate);
        }

        public GenericOutput<Batch> BatchSearch(BatchPredicate batchPredicate)
        {
            return MaintenanceLogic.InstanceCheck(PermissionType.BatchSearch).BatchSearch(batchPredicate);
        }

        #endregion Batch

        #region Operation

        public GenericOutput<Operation> OperationSearch(OperationPredicate operationPredicate)
        {
            return MaintenanceLogic.InstanceCheck(PermissionType.OperationSearch).OperationSearch(operationPredicate);
        }

        #endregion Operation
    }
}