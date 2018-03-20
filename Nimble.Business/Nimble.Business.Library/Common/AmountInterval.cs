#region Using

using System;
using System.Runtime.Serialization;

#endregion Using

namespace Nimble.Business.Library.Common
{
    [DataContract]
    public class AmountInterval
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public decimal? AmountFrom { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public decimal? AmountTo { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public DateTimeOffset? AmountDate { get; set; }

        #endregion Properties

        #region Methods

        public AmountInterval()
        {
        }

        public AmountInterval(decimal? amountFrom, decimal? amountTo)
        {
            AmountFrom = amountFrom;
            AmountTo = amountTo;
        }

        #endregion Methods

        #endregion Public Members
    }
}