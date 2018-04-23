#region Using

using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Library.Model.Framework.Notification;
using Nimble.Business.Service.Core;

#endregion Using

namespace Nimble.DataAccess.MsSql2008.Framework
{
    public class NotificationSql : GenericSql
    {
        #region Private Members

        #region Properties

        private static readonly NotificationSql instance = new NotificationSql(Kernel.Instance.ServerConfiguration.GenericDatabase);

        #endregion Properties

        #region Methods

        private NotificationSql(string connectionString) : base(connectionString) { }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        public static NotificationSql Instance
        {
            get { return instance; }
        }

        #endregion Properties

        #region Methods

        public NotificationSql() { }

        #region Publisher

        public Publisher PublisherCreate(Publisher publisher)
        {
            return EntityAction(PermissionType.PublisherCreate, publisher).Entity;
        }

        public Publisher PublisherRead(Publisher publisher)
        {
            return EntityAction(PermissionType.PublisherRead, publisher).Entity;
        }

        public Publisher PublisherUpdate(Publisher publisher)
        {
            return EntityAction(PermissionType.PublisherUpdate, publisher).Entity;
        }

        public bool PublisherDelete(Publisher publisher)
        {
            return EntityDelete(PermissionType.PublisherDelete, publisher);
        }

        public GenericOutput<Publisher> PublisherSearch(GenericInput<Publisher, PublisherPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.PublisherSearch;
            return EntityAction(genericInput);
        }

        #endregion Publisher

        #region Subscriber

        public Subscriber SubscriberCreate(Subscriber subscriber)
        {
            return EntityAction(PermissionType.SubscriberCreate, subscriber).Entity;
        }

        public Subscriber SubscriberRead(Subscriber subscriber)
        {
            return EntityAction(PermissionType.SubscriberRead, subscriber).Entity;
        }

        public Subscriber SubscriberUpdate(Subscriber subscriber)
        {
            return EntityAction(PermissionType.SubscriberUpdate, subscriber).Entity;
        }

        public bool SubscriberDelete(Subscriber subscriber)
        {
            return EntityDelete(PermissionType.SubscriberDelete, subscriber);
        }

        public GenericOutput<Subscriber> SubscriberSearch(GenericInput<Subscriber, SubscriberPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.SubscriberSearch;
            return EntityAction(genericInput);
        }

        #endregion Subscriber

        #region Message

        public Message MessageCreate(Message message)
        {
            return EntityAction(PermissionType.MessageCreate, message).Entity;
        }

        public Message MessageRead(Message message)
        {
            return EntityAction(PermissionType.MessageRead, message).Entity;
        }

        public GenericOutput<Message> MessageSearch(GenericInput<Message, MessagePredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.MessageSearch;
            return EntityAction(genericInput);
        }

        #endregion Message

        #region Trace

        public Trace TraceCreate(Trace trace)
        {
            return EntityAction(PermissionType.TraceCreate, trace).Entity;
        }

        public Trace TraceRead(Trace trace)
        {
            return EntityAction(PermissionType.TraceRead, trace).Entity;
        }

        public Trace TraceUpdate(Trace trace)
        {
            return EntityAction(PermissionType.TraceUpdate, trace).Entity;
        }

        public GenericOutput<Trace> TraceSearch(GenericInput<Trace, TracePredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.TraceSearch;
            return EntityAction(genericInput);
        }

        #endregion Trace

        #endregion Methods

        #endregion Public Members
    }
}
