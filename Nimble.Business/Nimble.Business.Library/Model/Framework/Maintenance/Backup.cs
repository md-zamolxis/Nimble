#region Usings

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;

#endregion Usings

namespace Nimble.Business.Library.Model.Framework.Maintenance
{
    [DataContract]
    public class BackupPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> Start { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Backup>> Backups { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Backup")]
    [DatabaseMapping(StoredProcedure = "[Maintenance].[Backup.Action]")]
    public class Backup : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BackupId", IsIdentity = true)]
        [DisplayName("Backup id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BackupStart")]
        [DisplayName("Backup start")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? Start { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BackupEnd")]
        [DisplayName("Backup end")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? End { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BackupData")]
        [DisplayName("Backup data")]
        [UndefinedValues(ConstantType.NullReference)]
        public int? Data { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BackupDestination")]
        [DisplayName("Backup destination")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmpty)]
        public string Destination { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BackupSize")]
        [DisplayName("Backup size")]
        [UndefinedValues(ConstantType.NullReference)]
        public long? Size { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}