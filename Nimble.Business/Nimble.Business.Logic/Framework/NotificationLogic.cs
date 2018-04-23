#region Using

using System;
using System.Collections.Generic;
using Nimble.Business.Service.Core;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.DataAccess.MsSql2008.Framework;
using Nimble.Business.Library.Model.Framework.Notification;
using Nimble.Business.Library.Model.Framework.Owner;
using Hangfire;

#endregion Using

namespace Nimble.Business.Logic.Framework
{
    public class NotificationLogic : GenericLogic
    {
        #region Private Members

        #region Properties

        private static readonly NotificationLogic instance = new NotificationLogic();

        #endregion Properties

        #region Methods

        private Subscriber SubscriberCheck(Subscriber subscriber)
        {
            if (subscriber != null)
            {
                var session = Kernel.Instance.SessionManager.SessionRead();
                if (!TokenIsMaster(session.Token))
                {
                    if (!GenericEntity.HasValue(subscriber.Person))
                    {
                        subscriber.Person = OwnerSql.Instance.PersonRead(subscriber.Person);
                    }
                    if (GenericEntity.HasValue(subscriber.Person) &&
                        !subscriber.Person.Equals(session.Token.Person))
                    {
                        var employees = OwnerLogic.Instance.EmployeeSearch(new EmployeePredicate
                        {
                            PersonPredicate = new PersonPredicate
                            {
                                Persons = new Criteria<List<Person>>(new List<Person>
                                {
                                    subscriber.Person
                                })
                            }
                        }).Entities;
                        if (employees.Count == 0)
                        {
                            ThrowException("Only system administrators can create subscribers for not owned persons.");
                        }
                    }
                }
            }
            return subscriber;
        }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        internal static NotificationLogic Instance
        {
            get { return instance; }
        }

        #endregion Properties

        #region Methods

        public static NotificationLogic InstanceCheck(PermissionType permissionType)
        {
            GenericCheck(permissionType);
            return instance;
        }

        #region Publisher

        public Publisher PublisherCreate(Publisher publisher)
        {
            EntityPropertiesCheck(
                publisher,
                "NotificationType");
            publisher.Organisation = OrganisationCheck(publisher.Organisation);
            publisher.SetDefaults();
            return NotificationSql.Instance.PublisherCreate(publisher);
        }

        public Publisher PublisherRead(Publisher publisher)
        {
            EntityInstanceCheck(publisher);
            publisher = NotificationSql.Instance.PublisherRead(publisher);
            if (GenericEntity.HasValue(publisher))
            {
                OrganisationCheck(publisher.Organisation);
            }
            return publisher;
        }

        public Publisher PublisherUpdate(Publisher publisher)
        {
            EntityPropertiesCheck(
                publisher,
                "NotificationType");
            PublisherRead(publisher);
            return NotificationSql.Instance.PublisherUpdate(publisher);
        }

        public bool PublisherDelete(Publisher publisher)
        {
            PublisherRead(publisher);
            return NotificationSql.Instance.PublisherDelete(publisher);
        }

        public GenericOutput<Publisher> PublisherSearch(PublisherPredicate publisherPredicate)
        {
            return NotificationSql.Instance.PublisherSearch(GenericInputCheck<Publisher, PublisherPredicate>(publisherPredicate));
        }

        #endregion Publisher

        #region Subscriber

        public Subscriber SubscriberCreate(Subscriber subscriber)
        {
            EntityPropertiesCheck(
                subscriber,
                "Publisher",
                "Person",
                "NotificationType");
            SubscriberCheck(subscriber);
            subscriber.SetDefaults();
            return NotificationSql.Instance.SubscriberCreate(subscriber);
        }

        public Subscriber SubscriberRead(Subscriber subscriber)
        {
            EntityInstanceCheck(subscriber);
            subscriber = NotificationSql.Instance.SubscriberRead(subscriber);
            if (GenericEntity.HasValue(subscriber))
            {
                SubscriberCheck(subscriber);
            }
            return subscriber;
        }

        public Subscriber SubscriberUpdate(Subscriber subscriber)
        {
            EntityPropertiesCheck(
                subscriber,
                "NotificationType");
            SubscriberRead(subscriber);
            return NotificationSql.Instance.SubscriberUpdate(subscriber);
        }

        public bool SubscriberDelete(Subscriber subscriber)
        {
            SubscriberRead(subscriber);
            return NotificationSql.Instance.SubscriberDelete(subscriber);
        }

        public GenericOutput<Subscriber> SubscriberSearch(SubscriberPredicate subscriberPredicate)
        {
            return NotificationSql.Instance.SubscriberSearch(GenericInputCheck<Subscriber, SubscriberPredicate>(subscriberPredicate));
        }

        public Subscriber SubscriberSave(Organisation organisation, Person person)
        {
            var publisher = new Publisher
            {
                Organisation = organisation,
                NotificationType = Flags<NotificationType>.SetAllValues(),
                CreatedOn = DateTimeOffset.Now
            };
            var publisherEntity = NotificationSql.Instance.PublisherRead(publisher);
            if (!GenericEntity.HasValue(publisherEntity))
            {
                publisherEntity = NotificationSql.Instance.PublisherCreate(publisher);
            }
            var subscriber = new Subscriber
            {
                Publisher = publisherEntity,
                Person = person,
                NotificationType = Flags<NotificationType>.SetAllValues(),
                CreatedOn = DateTimeOffset.Now
            };
            var subscriberEntity = NotificationSql.Instance.SubscriberRead(subscriber);
            if (!GenericEntity.HasValue(subscriberEntity))
            {
                subscriberEntity = NotificationSql.Instance.SubscriberCreate(subscriber);
            }
            return subscriberEntity;
        }

        #endregion Subscriber

        #region Message

        public Message MessageCreate(Message message)
        {
            EntityPropertiesCheck(
                message,
                "NotificationType",
                "MessageActionType",
                "MessageEntityType");
            message.Publisher = PublisherRead(message.Publisher);
            message.SetDefaults();
            message = NotificationSql.Instance.MessageCreate(message);
            if (Kernel.Instance.ServerConfiguration.HangfireDisabled)
            {
                MessageSend(message);
            }
            else
            {
                BackgroundJob.Enqueue(() => MessageSend(message));
            }
            return message;
        }

        public Message MessageRead(Message message)
        {
            EntityInstanceCheck(message);
            message = NotificationSql.Instance.MessageRead(message);
            if (GenericEntity.HasValue(message))
            {
                OrganisationCheck(message.Publisher.Organisation);
            }
            return message;
        }

        public GenericOutput<Message> MessageSearch(MessagePredicate messagePredicate)
        {
            return NotificationSql.Instance.MessageSearch(GenericInputCheck<Message, MessagePredicate>(messagePredicate));
        }

        public Message MessageSend(Message message)
        {
            if (!GenericEntity.HasValue(message.Publisher))
            {
                message.Publisher = NotificationSql.Instance.PublisherRead(message.Publisher);
            }
            if (!GenericEntity.HasValue(message))
            {
                message.SetDefaults();
                message = NotificationSql.Instance.MessageCreate(message);
            }
            if (message.Publisher.NotificationType.HasValues(message.NotificationType.GetValues()))
            {
            }
            return message;
        }

        #endregion Message

        #region Trace

        public Trace TraceCreate(Trace trace)
        {
            EntityPropertiesCheck(
                trace,
                "NotificationType");
            trace.Message = MessageRead(trace.Message);
            trace.Subscriber = SubscriberRead(trace.Subscriber);
            trace.SetDefaults();
            return NotificationSql.Instance.TraceCreate(trace);
        }

        public Trace TraceRead(Trace trace)
        {
            EntityInstanceCheck(trace);
            trace = NotificationSql.Instance.TraceRead(trace);
            if (GenericEntity.HasValue(trace))
            {
                SubscriberRead(trace.Subscriber);
            }
            return trace;
        }

        public Trace TraceUpdate(Trace trace)
        {
            EntityInstanceCheck(trace);
            TraceRead(trace);
            return NotificationSql.Instance.TraceUpdate(trace);
        }

        public GenericOutput<Trace> TraceSearch(TracePredicate tracePredicate)
        {
            return NotificationSql.Instance.TraceSearch(GenericInputCheck<Trace, TracePredicate>(tracePredicate));
        }

        #endregion Trace

        #endregion Methods

        #endregion Public Members
    }
}