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
    [Flags]
    [DataContract]
    public enum BranchActionType
    {
        [EnumMember]
        [FieldCategory(Name = "none")]
        None = 0
    }

    [DataContract]
    public class BranchPredicate : GenericPredicate
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
        public Criteria<DateInterval> LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<Flags<BranchActionType>> BranchActionType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Addresses { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Branch>> Branches { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public OrganisationPredicate OrganisationPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public GroupPredicate GroupPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public EmployeePredicate EmployeePredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public BranchGroupPredicate BranchGroupPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool BranchGroupExclude { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool LoadGroups { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool LoadBranchGroups { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool LoadFilestreams { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Branch")]
    [DatabaseMapping(StoredProcedure = "[Owner].[Branch.Action]")]
    public class Branch : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BranchId", IsIdentity = true)]
        [DisplayName("Branch id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Branch organisation")]
        [UndefinedValues(ConstantType.NullReference)]
        public Organisation Organisation { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BranchCode")]
        [DisplayName("Branch code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BranchName")]
        [DisplayName("Branch name")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmpty)]
        public string Name { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BranchDescription")]
        [DisplayName("Branch description")]
        public string Description { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BranchActionType")]
        [DisplayName("Branch action type")]
        [UndefinedValues(ConstantType.NullReference)]
        public Flags<BranchActionType> BranchActionType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BranchLockedOn")]
        [DisplayName("Branch locked on")]
        public DateTimeOffset? LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BranchAddress")]
        [DisplayName("Branch address")]
        public string Address { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BranchVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Branch employees")]
        public List<Employee> Employees { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Branch groups")]
        public List<Group> Groups { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Branch branch's groups")]
        public List<BranchGroup> BranchGroups { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Branch filestream")]
        public Filestream Filestream { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Branch filestreams")]
        public List<Filestream> Filestreams { get; set; }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(Organisation) &&
                !string.IsNullOrEmpty(Code))
            {
                keys.Add(Organisation.GetIdCode() + Code.ToUpper());
            }
            return keys;
        }

        public override GenericEntity Clone()
        {
            return new Branch
                {
                    Id = Id,
                    Organisation = (Organisation == null ? Organisation : Organisation.Clone<Organisation>()),
                    Code = Code
                };
        }

        #endregion Methods

        #endregion Public Members
    }
}