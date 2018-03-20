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
    [Flags]
    [DataContract]
    public enum OrganisationActionType
    {
        [EnumMember]
        [FieldCategory(Name = "none")]
        None = 0,
        [EnumMember]
        [FieldCategory(Name = "public")]
        Public = 1,
        [EnumMember]
        [FieldCategory(Name = "private")]
        Private = 2,
        [EnumMember]
        [FieldCategory(Name = "framework")]
        Framework = 4
    }

    [DataContract]
    public class OrganisationPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> IDNOs { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Names { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> RegisteredOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<Flags<OrganisationActionType>> OrganisationActionType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> LockedReasons { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Organisation>> Organisations { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public EmplacementPredicate EmplacementPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool LoadFilestreams { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Organisation")]
    [DatabaseMapping(StoredProcedure = "[Owner].[Organisation.Action]")]
    public class Organisation : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OrganisationId", IsIdentity = true)]
        [DisplayName("Organisation id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Organisation emplacement")]
        [UndefinedValues(ConstantType.NullReference)]
        public Emplacement Emplacement { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OrganisationCode")]
        [DisplayName("Organisation code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OrganisationIDNO")]
        [DisplayName("Organisation IDNO")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string IDNO { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OrganisationName")]
        [DisplayName("Organisation name")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Name { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OrganisationCreatedOn")]
        [DisplayName("Organisation created on")]
        public DateTimeOffset? CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OrganisationRegisteredOn")]
        [DisplayName("Organisation registered on")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? RegisteredOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OrganisationActionType")]
        [DisplayName("Organisation action type")]
        [UndefinedValues(ConstantType.NullReference)]
        public Flags<OrganisationActionType> OrganisationActionType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OrganisationLockedOn")]
        [DisplayName("Organisation locked on")]
        public DateTimeOffset? LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OrganisationLockedReason")]
        [DisplayName("Organisation locked reason")]
        public string LockedReason { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OrganisationSettings")]
        [DisplayName("Organisation settings")]
        public KeyValue[] Settings { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "OrganisationVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Organisation filestream")]
        public Filestream Filestream { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Organisation filestreams")]
        public List<Filestream> Filestreams { get; set; }

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
                if (!string.IsNullOrEmpty(IDNO))
                {
                    keys.Add(emplacementId + IDNO.ToUpper());
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
            return new Organisation
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