#region Using

using System.ServiceModel;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Maintenance;

#endregion Using

namespace Nimble.Server.Iis.Framework.Interface
{
    [ServiceContract]
    public interface IMaintenance
    {
        [OperationContract]
        int? DatabaseSize();

        #region Backup

        [OperationContract]
        Backup BackupCreate(Backup backup);

        [OperationContract]
        Backup BackupRead(Backup backup);

        [OperationContract]
        GenericOutput<Backup> BackupDelete(BackupPredicate backupPredicate);

        [OperationContract]
        GenericOutput<Backup> BackupSearch(BackupPredicate backupPredicate);

        #endregion Backup

        #region Batch

        [OperationContract]
        Batch BatchCreate(Batch batch);

        [OperationContract]
        Batch BatchRead(Batch batch);

        [OperationContract]
        GenericOutput<Batch> BatchDelete(BatchPredicate batchPredicate);

        [OperationContract]
        GenericOutput<Batch> BatchSearch(BatchPredicate batchPredicate);

        #endregion Batch

        #region Operation

        [OperationContract]
        GenericOutput<Operation> OperationSearch(OperationPredicate operationPredicate);

        #endregion Operation
    }
}