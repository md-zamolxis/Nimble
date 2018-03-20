#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Notification
{
    [DataContract]
    public enum MessageActionType
    {
        [EnumMember]
        [FieldCategory(Name = "undefined")]
        Undefined,
        [EnumMember]
        [FieldCategory(Name = "regular")]
        Regular,
        [EnumMember]
        [FieldCategory(Name = "important")]
        Important
    }

    [DataContract]
    public class MessagePredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<Flags<NotificationType>> NotificationType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<MessageActionType>> MessageActionTypes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Texts { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Guid?>> EntityIds { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Message>> Messages { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public PublisherPredicate PublisherPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Message")]
    [DatabaseMapping(StoredProcedure = "[Notification].[Message.Action]")]
    public class Message : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MessageId", IsIdentity = true)]
        [DisplayName("Message id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Message publisher")]
        [UndefinedValues(ConstantType.NullReference)]
        public Publisher Publisher { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MessageCode")]
        [DisplayName("Message code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MessageNotificationType")]
        [DisplayName("Message notification type")]
        [UndefinedValues(ConstantType.NullReference)]
        public Flags<NotificationType> NotificationType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MessageActionType")]
        [DisplayName("Message action type")]
        [UndefinedValues(MessageActionType.Undefined)]
        public MessageActionType MessageActionType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MessageCreatedOn")]
        [DisplayName("Message created on")]
        public DateTimeOffset? CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MessageText")]
        [DisplayName("Message text")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Text { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MessageEntityId")]
        [DisplayName("Message entity id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? EntityId { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MessageSettings")]
        [DisplayName("Message settings")]
        public KeyValue[] Settings { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MessageVersion")]
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
            if (HasValue(Publisher) &&
                !string.IsNullOrEmpty(Code))
            {
                keys.Add(Publisher.GetIdCode() + Code.ToUpper());
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