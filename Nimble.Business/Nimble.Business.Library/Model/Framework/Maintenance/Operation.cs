#region Usings

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;

#endregion Usings

namespace Nimble.Business.Library.Model.Framework.Maintenance
{
    [DataContract]
    public enum OperationTuningType
    {
        [EnumMember]
        [FieldCategory(Name = "undefined")]
        Undefined,
        [EnumMember]
        [FieldCategory(Name = "checkpoint")]
        Checkpoint,
        [EnumMember]
        [FieldCategory(Name = "update usage")]
        UpdateUsage,
        [EnumMember]
        [FieldCategory(Name = "show contig")]
        ShowContig,
        [EnumMember]
        [FieldCategory(Name = "reindex database")]
        DbReindex,
        [EnumMember]
        [FieldCategory(Name = "shrink database")]
        ShrinkDatabase,
        [EnumMember]
        [FieldCategory(Name = "backup log")]
        BackupLog,
        [EnumMember]
        [FieldCategory(Name = "shrink file")]
        ShrinkFile,
        [EnumMember]
        [FieldCategory(Name = "update statistics")]
        UpdateStatistics
    }

    [DataContract]
    public class OperationPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<OperationTuningType>> OperationTuningTypes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public BatchPredicate BatchPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Operation")]
    [DatabaseMapping(StoredProcedure = "[Maintenance].[Operation.Action]")]
    public class Operation : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OperationId", IsIdentity = true)]
        [DisplayName("Operation id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Operation batch")]
        [UndefinedValues(ConstantType.NullReference)]
        public Batch Batch { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OperationCode")]
        [DisplayName("Operation code")]
        [UndefinedValues(ConstantType.NullReference)]
        public int? Code { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OperationTuningType")]
        [DisplayName("Operation tuning type")]
        [UndefinedValues(OperationTuningType.Undefined)]
        public OperationTuningType OperationTuningType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OperationStart")]
        [DisplayName("Operation start")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? Start { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OperationEnd")]
        [DisplayName("Operation end")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? End { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OperationBefore")]
        [DisplayName("Operation before")]
        [UndefinedValues(ConstantType.NullReference)]
        public int? Before { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OperationAfter")]
        [DisplayName("Operation after")]
        [UndefinedValues(ConstantType.NullReference)]
        public int? After { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OperationResults")]
        [DisplayName("Operation results")]
        public string Results { get; set; }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(Batch) &&
                Code.HasValue)
            {
                keys.Add(Batch.GetIdCode() + Code);
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}