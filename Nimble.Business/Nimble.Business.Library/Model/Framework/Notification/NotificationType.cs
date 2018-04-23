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
        [FieldCategory(Name = "none", Description = "Message has been created.")]
        None = 0,
        [EnumMember]
        [FieldCategory(Name = "information", Description = "Information has been created.")]
        Information = 1,
        [EnumMember]
        [FieldCategory(Name = "warning", Description = "Warning has been created.")]
        Warning = 2
    }
}
