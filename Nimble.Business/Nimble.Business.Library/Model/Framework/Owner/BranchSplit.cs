#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Owner
{
    [DataContract]
    public enum SplitBranchType
    {
        [EnumMember]
        [FieldCategory(Name = "none")]
        None,
        [EnumMember]
        [FieldCategory(Name = "city")]
        City,
        [EnumMember]
        [FieldCategory(Name = "service")]
        Service
    }

    [DataContract]
    public class BranchSplitPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<SplitBranchType>> SplitBranchTypes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Names { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? IsSystem { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? IsExclusive { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<BranchSplit>> BranchSplits { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public OrganisationPredicate OrganisationPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Branch split")]
    [DatabaseMapping(StoredProcedure = "[Owner.Branch].[Split.Action]", Table = "Owner.Branch.Split")]
    public class BranchSplit : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitId", IsIdentity = true)]
        [DisplayName("Branch split id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Branch split organisation")]
        [UndefinedValues(ConstantType.NullReference)]
        public Organisation Organisation { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitCode")]
        [DisplayName("Branch split code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitBranchType")]
        [DisplayName("Branch split type")]
        public SplitBranchType? SplitBranchType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitName")]
        [DisplayName("Branch split name")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Name { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitNames")]
        [DisplayName("Branch split names")]
        public KeyValue[] Names { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitIsSystem")]
        [DisplayName("Branch split is system")]
        public bool IsSystem { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitIsExclusive")]
        [DisplayName("Branch split is exclusive")]
        public bool IsExclusive { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitSettings")]
        [DisplayName("Branch split settings")]
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
            if (HasValue(Organisation))
            {
                var organisationId = Organisation.GetIdCode();
                if (!string.IsNullOrEmpty(Code))
                {
                    keys.Add(organisationId + Code.ToUpper());
                }
                if (SplitBranchType.HasValue)
                {
                    keys.Add(organisationId + SplitBranchType.ToString().ToUpper());
                }
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}