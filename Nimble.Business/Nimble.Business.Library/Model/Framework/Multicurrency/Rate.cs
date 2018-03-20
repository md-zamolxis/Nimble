#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Multicurrency
{
    [DataContract]
    public class RatePredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<AmountInterval> Value { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Rate>> Rates { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public TradePredicate TradePredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public CurrencyPredicate CurrencyFromPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public CurrencyPredicate CurrencyToPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Rate")]
    [DatabaseMapping(StoredProcedure = "[Multicurrency].[Rate.Action]")]
    public class Rate : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "RateId", IsIdentity = true)]
        [DisplayName("Rate id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Rate trade")]
        [UndefinedValues(ConstantType.NullReference)]
        public Trade Trade { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Prefix = "From")]
        [DisplayName("Rate currency from")]
        [UndefinedValues(ConstantType.NullReference)]
        public Currency CurrencyFrom { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Prefix = "To")]
        [DisplayName("Rate currency to")]
        [UndefinedValues(ConstantType.NullReference)]
        public Currency CurrencyTo { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "RateValue")]
        [DisplayName("Rate value")]
        [UndefinedValues(ConstantType.NullReference)]
        public decimal? Value { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "RateVersion")]
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
            if (HasValue(Trade) &&
                HasValue(CurrencyFrom) &&
                HasValue(CurrencyTo))
            {
                keys.Add(Trade.GetIdCode() + CurrencyFrom.GetIdCode() + CurrencyTo.GetIdCode());
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}