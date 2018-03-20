#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model.Framework.Common;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Business.Library.Model.Framework.Owner;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Security
{
    [DataContract]
    public enum LockType
    {
        [EnumMember]
        [FieldCategory(Name = "undefined")]
        Undefined,
        [EnumMember]
        [FieldCategory(Name = "group")]
        Group,
        [EnumMember]
        [FieldCategory(Name = "source")]
        Source,
        [EnumMember]
        [FieldCategory(Name = "account")]
        Account,
        [EnumMember]
        [FieldCategory(Name = "person")]
        Person,
        [EnumMember]
        [FieldCategory(Name = "organisation")]
        Organisation,
        [EnumMember]
        [FieldCategory(Name = "branch group")]
        BranchGroup,
        [EnumMember]
        [FieldCategory(Name = "branch")]
        Branch,
        [EnumMember]
        [FieldCategory(Name = "employee")]
        Employee,
        [EnumMember]
        [FieldCategory(Name = "post group")]
        PostGroup,
        [EnumMember]
        [FieldCategory(Name = "post")]
        Post,
        [EnumMember]
        [FieldCategory(Name = "multicurrency")]
        Multicurrency,
        [EnumMember]
        [FieldCategory(Name = "filestream")]
        Filestream
    }

    [DataContract]
    public class TokenPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> LastUsedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<PermissionType>> PermissionTypes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Token>> Tokens { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public AccountPredicate AccountPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public PersonPredicate PersonPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Token")]
    public class Token : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token code")]
        [UndefinedValues(ConstantType.NullReference)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token locks")]
        [UndefinedValues(ConstantType.NullReference)]
        public List<string> Locks { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token emplacement")]
        [UndefinedValues(ConstantType.NullReference)]
        public Emplacement Emplacement { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token application")]
        [UndefinedValues(ConstantType.NullReference)]
        public Application Application { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token client host")]
        public string ClientHost { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token client geospatial")]
        public string ClientGeospatial { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token client UUID")]
        public string ClientUUID { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token client device")]
        public string ClientDevice { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token client platform")]
        public string ClientPlatform { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token client application")]
        public string ClientApplication { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token external reference")]
        public string ExternalReference { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token account")]
        [UndefinedValues(ConstantType.NullReference)]
        public Account Account { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Permissions")]
        public Dictionary<string, Permission> Permissions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Permission type")]
        public PermissionType PermissionType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Permission description")]
        public string PermissionDescription { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token last used on")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset LastUsedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token request host")]
        public string RequestHost { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token request port")]
        public int RequestPort { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Token presets")]
        public List<Preset> Presets { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Person")]
        public Person Person { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Employees")]
        public List<Employee> Employees { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Employee organisations")]
        public List<Organisation> EmployeeOrganisations { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Employee")]
        public Employee Employee { get; set; }

        [DisplayName("Employee branches")]
        public List<Branch> EmployeeBranches { get; set; }

        #region Common

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Common culture")]
        public Culture Culture { get; set; }

        #endregion Common

        #endregion Properties

        #region Methods

        public bool IsMaster()
        {
            return Person == null;
        }

        #endregion Methods

        #endregion Public Members
    }
}