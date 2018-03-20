#region Using

using System;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Notification
{
    [Flags]
    [DataContract]
    public enum NotificationType
    {
        [EnumMember]
        [FieldCategory(Name = "none")]
        None = 0,
        [EnumMember]
        [FieldCategory(Name = "information")]
        Information = 1,
        [EnumMember]
        [FieldCategory(Name = "warning")]
        Warning = 2
    }
}
