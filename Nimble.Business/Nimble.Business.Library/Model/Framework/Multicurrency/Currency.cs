#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model.Framework.Owner;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Multicurrency
{
    [DataContract]
    public class CurrencyPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Descriptions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? IsDefault { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Currency>> Currencies { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public OrganisationPredicate OrganisationPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Currency")]
    [DatabaseMapping(StoredProcedure = "[Multicurrency].[Currency.Action]")]
    public class Currency : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "CurrencyId", IsIdentity = true)]
        [DisplayName("Currency id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Currency organisation")]
        [UndefinedValues(ConstantType.NullReference)]
        public Organisation Organisation { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "CurrencyCode")]
        [DisplayName("Currency code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmpty)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "CurrencyCreatedOn")]
        [DisplayName("Currency created on")]
        public DateTimeOffset? CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "CurrencyName")]
        [DisplayName("Currency name")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmpty)]
        public string Description { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "CurrencyIsDefault")]
        [DisplayName("Currency is default")]
        public bool IsDefault { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "CurrencyLockedOn")]
        [DisplayName("Currency locked on")]
        public DateTimeOffset? LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "CurrencyVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Currency rates")]
        public List<Rate> Rates { get; set; }

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
                if (IsDefault)
                {
                    keys.Add(organisationId);
                }
            }
            return keys;
        }

        public override void SetDefaults()
        {
            CreatedOn = DateTimeOffset.Now;
        }

        #endregion Methods

        #endregion Public Members
    }
}