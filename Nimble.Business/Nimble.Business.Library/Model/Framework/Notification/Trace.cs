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
    public class TracePredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> ReadOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Trace>> Traces { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public MessagePredicate MessagePredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public SubscriberPredicate SubscriberPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Trace")]
    [DatabaseMapping(StoredProcedure = "[Notification].[Trace.Action]")]
    public class Trace : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "TraceId", IsIdentity = true)]
        [DisplayName("Trace id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Trace message")]
        [UndefinedValues(ConstantType.NullReference)]
        public Message Message { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Trace subscriber")]
        [UndefinedValues(ConstantType.NullReference)]
        public Subscriber Subscriber { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "TraceCreatedOn")]
        [DisplayName("Trace created on")]
        public DateTimeOffset? CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "TraceReadOn")]
        [DisplayName("Trace read on")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? ReadOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "TraceSettings")]
        [DisplayName("Trace settings")]
        public KeyValue[] Settings { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "TraceVersion")]
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
            if (HasValue(Message) &&
                HasValue(Subscriber))
            {
                keys.Add(Message.GetIdCode() + Subscriber.GetIdCode());
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