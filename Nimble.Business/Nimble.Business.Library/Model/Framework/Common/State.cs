#region Using

using System;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Common
{
    [DataContract]
    [DisplayName("State")]
    public class State : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "From")]
        [DisplayName("State from")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? From { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "To")]
        [DisplayName("State to")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? To { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "AppliedOn")]
        [DisplayName("State applied on")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? AppliedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "IsActive")]
        [DisplayName("State is active")]
        public bool? IsActive { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}
