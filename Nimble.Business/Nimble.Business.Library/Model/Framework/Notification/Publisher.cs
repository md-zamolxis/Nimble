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
    public class PublisherPredicate : GenericPredicate
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
        public Criteria<List<Publisher>> Publishers { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public OrganisationPredicate OrganisationPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Publisher")]
    [DatabaseMapping(StoredProcedure = "[Notification].[Publisher.Action]")]
    public class Publisher : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PublisherId", IsIdentity = true)]
        [DisplayName("Publisher id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Publisher organisation")]
        [UndefinedValues(ConstantType.NullReference)]
        public Organisation Organisation { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PublisherNotificationType")]
        [DisplayName("Publisher notification type")]
        [UndefinedValues(ConstantType.NullReference)]
        public Flags<NotificationType> NotificationType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PublisherCreatedOn")]
        [DisplayName("Publisher created on")]
        public DateTimeOffset? CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PublisherLockedOn")]
        [DisplayName("Publisher locked on")]
        public DateTimeOffset? LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PublisherSettings")]
        [DisplayName("Publisher settings")]
        public KeyValue[] Settings { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PublisherVersion")]
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
            if (HasValue(Organisation))
            {
                keys.Add(Organisation.GetIdCode());
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