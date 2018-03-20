#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Model.Framework.Owner;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Multicurrency
{
    [DataContract]
    public class TradePredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateTimeOffset?> CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Descriptions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateTimeOffset?> From { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateTimeOffset?> To { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateTimeOffset?> AppliedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Trade>> Trades { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public OrganisationPredicate OrganisationPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Trade")]
    [DatabaseMapping(StoredProcedure = "[Multicurrency].[Trade.Action]")]
    public class Trade : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "TradeId", IsIdentity = true)]
        [DisplayName("Trade id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Trade organisation")]
        [UndefinedValues(ConstantType.NullReference)]
        public Organisation Organisation { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "TradeCode")]
        [DisplayName("Trade code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmpty)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "TradeCreatedOn")]
        [DisplayName("Trade created on")]
        public DateTimeOffset? CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "TradeDescription")]
        [DisplayName("Trade description")]
        public string Description { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "TradeFrom")]
        [DisplayName("Trade from")]
        public DateTimeOffset? From { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "TradeTo")]
        [DisplayName("Trade to")]
        public DateTimeOffset? To { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "TradeVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Trade applied on")]
        public DateTimeOffset? AppliedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Trade rates")]
        public List<Rate> Rates { get; set; }

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

        public override void SetDefaults()
        {
            CreatedOn = DateTimeOffset.Now;
        }

        #endregion Methods

        #endregion Public Members
    }
}