#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model.Framework.Common;
using Nimble.Business.Library.Model.Framework.Security;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Owner
{
    [DataContract]
    public enum EmployeeActorType
    {
        [EnumMember]
        [FieldCategory(Name = "undefined")]
        Undefined,
        [EnumMember]
        [FieldCategory(Name = "operational administrator")]
        OperationalAdministrator,
        [EnumMember]
        [FieldCategory(Name = "operational viewer")]
        OperationalViewer
    }

    [DataContract]
    public class EmployeePredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Functions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<EmployeeActorType>> EmployeeActorTypes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? IsDefault { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<State> State { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Employee>> Employees { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public PersonPredicate PersonPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public OrganisationPredicate OrganisationPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public BranchPredicate BranchPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Employee")]
    [DatabaseMapping(StoredProcedure = "[Owner].[Employee.Action]")]
    public class Employee : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "EmployeeId", IsIdentity = true)]
        [DisplayName("Employee id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Employee person")]
        [UndefinedValues(ConstantType.NullReference)]
        public Person Person { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Employee organisation")]
        [UndefinedValues(ConstantType.NullReference)]
        public Organisation Organisation { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "EmployeeCode")]
        [DisplayName("Employee code")]
        [UndefinedValues(ConstantType.NullReference)]
        public string Code { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "EmployeeFunction")]
        [DisplayName("Employee function")]
        [UndefinedValues(ConstantType.NullReference)]
        public string Function { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "EmployeeCreatedOn")]
        [DisplayName("Employee created on")]
        public DateTimeOffset? CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "EmployeeActorType")]
        [DisplayName("Employee actor type")]
        [UndefinedValues(EmployeeActorType.Undefined)]
        public EmployeeActorType EmployeeActorType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "EmployeeIsDefault")]
        [DisplayName("Employee is default")]
        public bool IsDefault { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "EmployeeVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Prefix = "Employee")]
        [DisplayName("Employee state")]
        public State State { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Employee branches")]
        public List<Branch> Branches { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Employee filestream")]
        public Filestream Filestream { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Employee filestreams")]
        public List<Filestream> Filestreams { get; set; }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(Organisation))
            {
                var organisationId = Organisation.GetIdCode();
                if (HasValue(Person) &&
                    !string.IsNullOrEmpty(Function))
                {
                    keys.Add(Person.GetIdCode() + organisationId + Function.ToUpper());
                }
                if (!string.IsNullOrEmpty(Code))
                {
                    keys.Add(organisationId + Code.ToUpper());
                }
                if (IsDefault)
                {
                    keys.Add(organisationId);
                }
            }
            return keys;
        }

        public override string ToString()
        {
            return string.Format("{0} | {1}", Organisation.Name, Function);
        }

        public override void SetDefaults()
        {
            CreatedOn = DateTimeOffset.Now;
        }

        #endregion Methods

        #endregion Public Members
    }
}