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
    public class UserPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? HasFacebook { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? HasGmail { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<User>> Users { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public EmplacementPredicate EmplacementPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("User")]
    [DatabaseMapping(StoredProcedure = "[Security].[User.Action]")]
    public class User : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "UserId", IsIdentity = true)]
        [DisplayName("User id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("User emplacement")]
        [UndefinedValues(ConstantType.NullReference)]
        public Emplacement Emplacement { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "UserCode")]
        [DisplayName("User code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "UserPassword")]
        [DisplayName("User password")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrim)]
        public string Password { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "UserCreatedOn")]
        [DisplayName("User created on")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "UserLockedOn")]
        [DisplayName("User locked on")]
        public DateTimeOffset? LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "UserFacebookId")]
        [DisplayName("User facebook id")]
        public string FacebookId { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "UserGmailId")]
        [DisplayName("User gmail id")]
        public string GmailId { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "UserVersion")]
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
            if (HasValue(Emplacement))
            {
                var emplacementId = Emplacement.GetIdCode();
                if (!string.IsNullOrEmpty(Code))
                {
                    keys.Add(emplacementId + Code.ToUpper());
                }
                if (!string.IsNullOrEmpty(FacebookId))
                {
                    keys.Add(emplacementId + FacebookId);
                }
                if (!string.IsNullOrEmpty(GmailId))
                {
                    keys.Add(emplacementId + GmailId);
                }
            }
            return keys;
        }

        public override void SetDefaults()
        {
            CreatedOn = DateTimeOffset.Now;
        }

        public override GenericEntity Clone()
        {
            return new User
                {
                    Id = Id,
                    Emplacement = (Emplacement == null ? Emplacement : Emplacement.Clone<Emplacement>()),
                    Code = Code
                };
        }

        #endregion Methods

        #endregion Public Members
    }
}