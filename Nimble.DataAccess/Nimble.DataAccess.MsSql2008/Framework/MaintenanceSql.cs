#region Using

using System.Data;
using System.Data.SqlClient;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Maintenance;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Service.Core;

#endregion Using

namespace Nimble.DataAccess.MsSql2008.Framework
{
    public class MaintenanceSql : GenericSql
    {
        #region Private Members

        #region Properties

        private static readonly MaintenanceSql instance = new MaintenanceSql(Kernel.Instance.ServerConfiguration.GenericDatabase);

        #endregion Properties

        #region Methods

        private MaintenanceSql(string connectionString) : base(connectionString) { }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        public static MaintenanceSql Instance
        {
            get { return instance; }
        }

        #endregion Properties

        #region Methods

        public MaintenanceSql() { }

        public int? DatabaseSize()
        {
            var sqlCommand = new SqlCommand
            {
                CommandText = "[Maintenance].[Database.Size]",
                CommandType = CommandType.StoredProcedure
            };
            sqlCommand.Parameters.Add(new SqlParameter
            {
                ParameterName = "@name",
                Direction = ParameterDirection.Output,
                Value = string.Empty
            });
            var size = new SqlParameter
            {
                ParameterName = "@size",
                Direction = ParameterDirection.Output,
                DbType = DbType.Int32
            };
            sqlCommand.Parameters.Add(size);
            ExecuteNonQuery(sqlCommand);
            return (int?)size.Value;
        }

        #region Backup

        public Backup BackupCreate(Backup backup)
        {
            return EntityAction(PermissionType.BackupCreate, backup).Entity;
        }

        public Backup BackupRead(Backup backup)
        {
            return EntityAction(PermissionType.BackupRead, backup).Entity;
        }

        public GenericOutput<Backup> BackupDelete(GenericInput<Backup, BackupPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.BackupDelete;
            return EntityAction(genericInput);
        }

        public GenericOutput<Backup> BackupSearch(GenericInput<Backup, BackupPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.BackupSearch;
            return EntityAction(genericInput);
        }

        #endregion Backup

        #region Batch

        public Batch BatchCreate(Batch batch)
        {
            return EntityAction(PermissionType.BatchCreate, batch).Entity;
        }

        public Batch BatchRead(Batch batch)
        {
            return EntityAction(PermissionType.BatchRead, batch).Entity;
        }

        public GenericOutput<Batch> BatchDelete(GenericInput<Batch, BatchPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.BatchDelete;
            return EntityAction(genericInput);
        }

        public GenericOutput<Batch> BatchSearch(GenericInput<Batch, BatchPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.BatchSearch;
            return EntityAction(genericInput);
        }

        #endregion Batch

        #region Operation

        public GenericOutput<Operation> OperationSearch(GenericInput<Operation, OperationPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.OperationSearch;
            return EntityAction(genericInput);
        }

        #endregion Operation

        #endregion Methods

        #endregion Public Members
    }
}
