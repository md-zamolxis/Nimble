#region Using

using System;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Maintenance;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.DataAccess.MsSql2008.Framework;
using Nimble.Business.Engine.Core;
using Nimble.Business.Service.Core;

#endregion Using

namespace Nimble.Business.Logic.Framework
{
    public class MaintenanceLogic : GenericLogic
    {
        #region Private Members

        #region Properties

        private static readonly MaintenanceLogic instance = new MaintenanceLogic();

        #endregion Properties

        #endregion Private Members

        #region Public Members

        #region Properties

        internal static MaintenanceLogic Instance
        {
            get { return instance; }
        }

        #endregion Properties

        #region Methods

        public static MaintenanceLogic InstanceCheck(PermissionType permissionType)
        {
            GenericCheck(permissionType);
            return instance;
        }

        public int? DatabaseSize()
        {
            return MaintenanceSql.Instance.DatabaseSize();
        }

        #region Backup

        public Backup BackupCreate(Backup backup)
        {
            EntityInstanceCheck(backup);
            if (string.IsNullOrEmpty(backup.Destination))
            {
                var dateTimeOffsetNow = DateTimeOffset.Now;
                backup.Destination = string.Format("{0}-{1}-{2}-{3}-{4}-{5}-{6}",
                    dateTimeOffsetNow.Year,
                    dateTimeOffsetNow.Month,
                    dateTimeOffsetNow.Day,
                    dateTimeOffsetNow.Hour,
                    dateTimeOffsetNow.Minute,
                    dateTimeOffsetNow.Second,
                    dateTimeOffsetNow.Millisecond);
            }
            if (string.IsNullOrEmpty(Kernel.Instance.ServerConfiguration.DatabaseBackupsFolderPattern))
            {
                ThrowException("Cannot backup database - backup's forder not defined.");
            }
            else
            {
                backup.Destination = string.Format(Kernel.Instance.ServerConfiguration.DatabaseBackupsFolderPattern, backup.Destination);
            }
            return MaintenanceSql.Instance.BackupCreate(backup);
        }

        public Backup BackupRead(Backup backup)
        {
            EntityInstanceCheck(backup);
            return MaintenanceSql.Instance.BackupRead(backup);
        }

        public GenericOutput<Backup> BackupDelete(BackupPredicate backupPredicate)
        {
            return MaintenanceSql.Instance.BackupDelete(GenericInputCheck<Backup, BackupPredicate>(backupPredicate));
        }

        public GenericOutput<Backup> BackupSearch(BackupPredicate backupPredicate)
        {
            return MaintenanceSql.Instance.BackupSearch(GenericInputCheck<Backup, BackupPredicate>(backupPredicate));
        }

        #endregion Backup

        #region Batch

        public Batch BatchCreate(Batch batch)
        {
            EntityInstanceCheck(batch);
            return MaintenanceSql.Instance.BatchCreate(batch);
        }

        public Batch BatchRead(Batch batch)
        {
            EntityInstanceCheck(batch);
            return MaintenanceSql.Instance.BatchRead(batch);
        }

        public GenericOutput<Batch> BatchDelete(BatchPredicate batchPredicate)
        {
            return MaintenanceSql.Instance.BatchDelete(GenericInputCheck<Batch, BatchPredicate>(batchPredicate));
        }

        public GenericOutput<Batch> BatchSearch(BatchPredicate batchPredicate)
        {
            return MaintenanceSql.Instance.BatchSearch(GenericInputCheck<Batch, BatchPredicate>(batchPredicate));
        }

        #endregion Batch

        #region Operation

        public GenericOutput<Operation> OperationSearch(OperationPredicate operationPredicate)
        {
            return MaintenanceSql.Instance.OperationSearch(GenericInputCheck<Operation, OperationPredicate>(operationPredicate));
        }

        #endregion Operation

        #endregion Methods

        #endregion Public Members
    }
}