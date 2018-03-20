#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model.Framework.Owner;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Notification
{
    [DataContract]
    public class SubscriberPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<Flags<NotificationType>> NotificationType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Subscriber>> Subscribers { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public PublisherPredicate PublisherPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public PersonPredicate PersonPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Subscriber")]
    [DatabaseMapping(StoredProcedure = "[Notification].[Subscriber.Action]")]
    public class Subscriber : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SubscriberId", IsIdentity = true)]
        [DisplayName("Subscriber id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Subscriber publisher")]
        [UndefinedValues(ConstantType.NullReference)]
        public Publisher Publisher { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Subscriber person")]
        [UndefinedValues(ConstantType.NullReference)]
        public Person Person { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SubscriberNotificationType")]
        [DisplayName("Subscriber notification type")]
        [UndefinedValues(ConstantType.NullReference)]
        public Flags<NotificationType> NotificationType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SubscriberCreatedOn")]
        [DisplayName("Subscriber created on")]
        public DateTimeOffset? CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SubscriberLockedOn")]
        [DisplayName("Subscriber locked on")]
        public DateTimeOffset? LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SubscriberSettings")]
        [DisplayName("Subscriber settings")]
        public KeyValue[] Settings { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SubscriberVersion")]
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
                HasValue(Person))
            {
                keys.Add(Publisher.GetIdCode() + Person.GetIdCode());
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