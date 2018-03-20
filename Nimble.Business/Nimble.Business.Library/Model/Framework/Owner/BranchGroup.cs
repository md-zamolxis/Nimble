#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model.Framework.Common;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Owner
{
    [DataContract]
    public class BranchGroupPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Names { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Descriptions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? IsDefault { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<AmountInterval> Index { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<BranchGroup>> BranchGroups { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public BranchSplitPredicate BranchSplitPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public BranchPredicate BranchPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool BranchSplitIntersect { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool LoadBranches { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool LoadFilestreams { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Branch group")]
    [DatabaseMapping(StoredProcedure = "[Owner.Branch].[Group.Action]", Table = "Owner.Branch.Group")]
    public class BranchGroup : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupId", IsIdentity = true)]
        [DisplayName("Branch group id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Branch group split")]
        [UndefinedValues(ConstantType.NullReference)]
        public BranchSplit BranchSplit { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupCode")]
        [DisplayName("Branch group code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupName")]
        [DisplayName("Branch group name")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Name { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupNames")]
        [DisplayName("Branch group names")]
        public KeyValue[] Names { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupDescription")]
        [DisplayName("Branch group description")]
        public string Description { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupDescriptions")]
        [DisplayName("Branch group descriptions")]
        public KeyValue[] Descriptions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupIsDefault")]
        [DisplayName("Branch group is default")]
        public bool IsDefault { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupIndex")]
        [DisplayName("Branch group index")]
        public int? Index { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupSettings")]
        [DisplayName("Branch group settings")]
        public KeyValue[] Settings { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Branch group branches")]
        public List<Branch> Branches { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Branch group filestream")]
        public Filestream Filestream { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Branch group filestreams")]
        public List<Filestream> Filestreams { get; set; }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(BranchSplit))
            {
                var branchSplitId = BranchSplit.GetIdCode();
                if (!string.IsNullOrEmpty(Code))
                {
                    keys.Add(branchSplitId + Code.ToUpper());
                }
                if (IsDefault)
                {
                    keys.Add(branchSplitId);
                }
                if (Index.HasValue)
                {
                    keys.Add(branchSplitId + Index);
                }
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}