#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Security
{
    [DataContract]
    public class AccountPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> LastUsedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<AmountInterval> Sessions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Account>> Accounts { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public UserPredicate UserPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public ApplicationPredicate ApplicationPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? Assigned { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Account")]
    [DatabaseMapping(StoredProcedure = "[Security].[Account.Action]")]
    public class Account : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "AccountId", IsIdentity = true, ForceValue = true)]
        [DisplayName("Account id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("User")]
        [UndefinedValues(ConstantType.NullReference)]
        public User User { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Application")]
        [UndefinedValues(ConstantType.NullReference)]
        public Application Application { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "AccountLockedOn")]
        [DisplayName("Account locked on")]
        public DateTimeOffset? LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "AccountLastUsedOn")]
        [DisplayName("Account last used on")]
        public DateTimeOffset? LastUsedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "AccountSessions")]
        [DisplayName("Account sessions")]
        public int? Sessions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "AccountVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Account roles")]
        public List<Role> Roles { get; set; }

        #region Profile

        [DataMember(EmitDefaultValue = false)]
        [ProfileProperty(ProfileCode = "CultureId", CommonPropertyType = CommonPropertyType.Culture)]
        [DisplayName("Culture id")]
        public Guid? CultureId { get; set; }

        #endregion Profile

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(User) &&
                HasValue(Application))
            {
                keys.Add(User.GetIdCode() + Application.GetIdCode());
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}