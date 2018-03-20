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
    public class BatchPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> Start { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Batch>> Batches { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Batch")]
    [DatabaseMapping(StoredProcedure = "[Maintenance].[Batch.Action]")]
    public class Batch : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BatchId", IsIdentity = true)]
        [DisplayName("Batch id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BatchStart")]
        [DisplayName("Batch start")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? Start { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BatchEnd")]
        [DisplayName("Batch end")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? End { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BatchBefore")]
        [DisplayName("Batch before")]
        [UndefinedValues(ConstantType.NullReference)]
        public int? Before { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BatchAfter")]
        [DisplayName("Batch after")]
        [UndefinedValues(ConstantType.NullReference)]
        public int? After { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Batch maximum fragmentation")]
        public decimal? MaximumFragmentation { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}