#region Using

using System;
using System.Runtime.Serialization;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Library.Attributes
{
    [DataContract]
    public enum CommonPropertyType
    {
        [EnumMember]
        Culture
    }

    [AttributeUsage(AttributeTargets.Property)]
    public sealed class ProfileProperty : Attribute
    {
        #region Public Members

        #region Properties

        public string ProfileCode { get; set; }

        public CommonPropertyType CommonPropertyType { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}