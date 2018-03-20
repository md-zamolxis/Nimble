#region Using

using System.ServiceModel.Activation;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Notification;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Logic.Framework;
using Nimble.Server.Iis.Framework.Interface;

#endregion Using

namespace Nimble.Server.Iis.Framework
{
    [AspNetCompatibilityRequirements(RequirementsMode = AspNetCompatibilityRequirementsMode.Allowed)]
    public class Notification : INotification
    {
        #region Publisher

        public Publisher PublisherCreate(Publisher publisher)
        {
            return NotificationLogic.InstanceCheck(PermissionType.PublisherCreate).PublisherCreate(publisher);
        }

        public Publisher PublisherRead(Publisher publisher)
        {
            return NotificationLogic.InstanceCheck(PermissionType.PublisherRead).PublisherRead(publisher);
        }

        public Publisher PublisherUpdate(Publisher publisher)
        {
            return NotificationLogic.InstanceCheck(PermissionType.PublisherUpdate).PublisherUpdate(publisher);
        }

        public bool PublisherDelete(Publisher publisher)
        {
            return NotificationLogic.InstanceCheck(PermissionType.PublisherDelete).PublisherDelete(publisher);
        }

        public GenericOutput<Publisher> PublisherSearch(PublisherPredicate publisherPredicate)
        {
            return NotificationLogic.InstanceCheck(PermissionType.PublisherSearch).PublisherSearch(publisherPredicate);
        }

        #endregion Publisher

        #region Subscriber

        public Subscriber SubscriberCreate(Subscriber subscriber)
        {
            return NotificationLogic.InstanceCheck(PermissionType.SubscriberCreate).SubscriberCreate(subscriber);
        }

        public Subscriber SubscriberRead(Subscriber subscriber)
        {
            return NotificationLogic.InstanceCheck(PermissionType.SubscriberRead).SubscriberRead(subscriber);
        }

        public Subscriber SubscriberUpdate(Subscriber subscriber)
        {
            return NotificationLogic.InstanceCheck(PermissionType.SubscriberUpdate).SubscriberUpdate(subscriber);
        }

        public bool SubscriberDelete(Subscriber subscriber)
        {
            return NotificationLogic.InstanceCheck(PermissionType.SubscriberDelete).SubscriberDelete(subscriber);
        }

        public GenericOutput<Subscriber> SubscriberSearch(SubscriberPredicate subscriberPredicate)
        {
            return NotificationLogic.InstanceCheck(PermissionType.SubscriberSearch).SubscriberSearch(subscriberPredicate);
        }

        #endregion Subscriber

        #region Message

        public Message MessageCreate(Message message)
        {
            return NotificationLogic.InstanceCheck(PermissionType.MessageCreate).MessageCreate(message);
        }

        public Message MessageRead(Message message)
        {
            return NotificationLogic.InstanceCheck(PermissionType.MessageRead).MessageRead(message);
        }

        public GenericOutput<Message> MessageSearch(MessagePredicate messagePredicate)
        {
            return NotificationLogic.InstanceCheck(PermissionType.MessageSearch).MessageSearch(messagePredicate);
        }

        #endregion Message

        #region Trace

        public Trace TraceCreate(Trace trace)
        {
            return NotificationLogic.InstanceCheck(PermissionType.TraceCreate).TraceCreate(trace);
        }

        public Trace TraceRead(Trace trace)
        {
            return NotificationLogic.InstanceCheck(PermissionType.TraceRead).TraceRead(trace);
        }

        public Trace TraceUpdate(Trace trace)
        {
            return NotificationLogic.InstanceCheck(PermissionType.TraceUpdate).TraceUpdate(trace);
        }

        public GenericOutput<Trace> TraceSearch(TracePredicate tracePredicate)
        {
            return NotificationLogic.InstanceCheck(PermissionType.TraceSearch).TraceSearch(tracePredicate);
        }

        #endregion Trace
    }
}