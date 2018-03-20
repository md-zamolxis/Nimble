#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model.Framework.Security;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Common
{
    [DataContract]
    public enum SplitEntityType
    {
        [EnumMember]
        [FieldCategory(Name = "undefined")]
        Undefined,
        [EnumMember]
        [FieldCategory(Name = "branch")]
        Branch
    }

    [DataContract]
    public enum SplitEntityCode
    {
        [EnumMember]
        [FieldCategory(Name = "undefined")]
        Undefined,
        [EnumMember]
        [FieldCategory(Name = "branch kitchen")]
        BranchKitchen,
        [EnumMember]
        [FieldCategory(Name = "branch state")]
        BranchState
    }

    [DataContract]
    public class SplitPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<SplitEntityType>> SplitEntityTypes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<SplitEntityCode>> SplitEntityCodes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Names { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? IsSystem { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? IsExclusive { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Split>> Splits { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public EmplacementPredicate EmplacementPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Split")]
    [DatabaseMapping(StoredProcedure = "[Common].[Split.Action]", Table = "Common.Split")]
    public class Split : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitId", IsIdentity = true)]
        [DisplayName("Split id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Split emplacement")]
        [UndefinedValues(ConstantType.NullReference)]
        public Emplacement Emplacement { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitEntityType")]
        [DisplayName("Split entity type")]
        [UndefinedValues(SplitEntityType.Undefined)]
        public SplitEntityType SplitEntityType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitEntityCode")]
        [DisplayName("Split entity code")]
        [UndefinedValues(SplitEntityCode.Undefined)]
        public SplitEntityCode SplitEntityCode { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitName")]
        [DisplayName("Split name")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Name { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitNames")]
        [DisplayName("Split names")]
        public KeyValue[] Names { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitIsSystem")]
        [DisplayName("Split is system")]
        public bool IsSystem { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitIsExclusive")]
        [DisplayName("Split is exclusive")]
        public bool IsExclusive { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitSettings")]
        [DisplayName("Split settings")]
        public KeyValue[] Settings { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(Emplacement) &&
                SplitEntityType != SplitEntityType.Undefined &&
                SplitEntityCode != SplitEntityCode.Undefined)
            {
                keys.Add(Emplacement.GetIdCode() + SplitEntityType.ToString().ToUpper() + SplitEntityCode.ToString().ToUpper());
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}