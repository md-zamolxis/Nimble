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
    public enum PersonSexType
    {
        [EnumMember]
        [FieldCategory(Name = "undefined")]
        Undefined,
        [EnumMember]
        [FieldCategory(Name = "male")]
        Male,
        [EnumMember]
        [FieldCategory(Name = "female")]
        Female
    }

    [DataContract]
    public class PersonPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> IDNPs { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> FirstNames { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> LastNames { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Patronymics { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> BornOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<PersonSexType>> PersonSexTypes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Emails { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Person>> Persons { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public EmplacementPredicate EmplacementPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public UserPredicate UserPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Person")]
    [DatabaseMapping(StoredProcedure = "[Owner].[Person.Action]")]
    public class Person : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PersonId", IsIdentity = true)]
        [DisplayName("Person id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Person emplacement")]
        [UndefinedValues(ConstantType.NullReference)]
        public Emplacement Emplacement { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Person user")]
        public User User { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PersonCode")]
        [DisplayName("Person code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PersonIDNP")]
        [DisplayName("Person IDNP")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string IDNP { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PersonFirstName")]
        [DisplayName("Person first name")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string FirstName { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PersonLastName")]
        [DisplayName("Person last name")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string LastName { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PersonPatronymic")]
        [DisplayName("Person patronymic")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Patronymic { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PersonBornOn")]
        [DisplayName("Person born on")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? BornOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PersonSexType")]
        [DisplayName("Person sex type")]
        [UndefinedValues(PersonSexType.Undefined)]
        public PersonSexType PersonSexType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PersonEmail")]
        [DisplayName("Person e-mail")]
        public string Email { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PersonLockedOn")]
        [DisplayName("Person locked on")]
        public DateTimeOffset? LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PersonSettings")]
        [DisplayName("Person settings")]
        public KeyValue[] Settings { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PersonVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Person filestream")]
        public Filestream Filestream { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Person filestreams")]
        public List<Filestream> Filestreams { get; set; }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(Emplacement) &&
                !string.IsNullOrEmpty(Code))
            {
                var emplacementId = Emplacement.GetIdCode();
                if (!string.IsNullOrEmpty(Code))
                {
                    keys.Add(emplacementId + Code.ToUpper());
                }
                if (!string.IsNullOrEmpty(IDNP))
                {
                    keys.Add(emplacementId + IDNP.ToUpper());
                }
                if (!string.IsNullOrEmpty(Email))
                {
                    keys.Add(emplacementId + Email.ToUpper());
                }
            }
            if (HasValue(User))
            {
                keys.Add(User.GetIdCode());
            }
            return keys;
        }

        public override FaultExceptionDetail Validate()
        {
            var faultExceptionDetail = new FaultExceptionDetail();
            if (!EmailIsValid(Email, true))
            {
                faultExceptionDetail.Items.Add(new FaultExceptionDetail("E-mail not valid."));
            }
            return faultExceptionDetail;
        }

        public override string ToString()
        {
            return string.Format("{0} {1} {2}", FirstName, LastName, Patronymic);
        }

        public override GenericEntity Clone()
        {
            return new Person
                {
                    Id = Id,
                    Emplacement = (Emplacement == null ? Emplacement : Emplacement.Clone<Emplacement>()),
                    User = (User == null ? User : User.Clone<User>()),
                    FirstName = FirstName,
                    LastName = LastName,
                    Email = Email
                };
        }

        #endregion Methods

        #endregion Public Members
    }
}