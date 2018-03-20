#region Using

using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Common
{
    [DataContract]
    [DisplayName("Property")]
    public class Property
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "ProfileCode")]
        [DisplayName("Profile code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmpty)]
        public string Code { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "ProfileValue")]
        [DisplayName("Profile value")]
        public string Value { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}