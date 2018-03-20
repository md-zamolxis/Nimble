#region Using

using System;
using System.Collections.Generic;
using System.ServiceModel;
using System.ServiceModel.Channels;
using System.Text;
using Nimble.Business.Library.Configuration;
using Nimble.Business.Library.Server;
using Nimble.Portable.Client.Common;
using Nimble.Portable.Client.Multicurrency;
using Nimble.Portable.Client.Geolocation;
using Nimble.Portable.Client.Maintenance;
using Nimble.Portable.Client.Multilanguage;
using Nimble.Portable.Client.Notification;
using Nimble.Portable.Client.Owner;
using Nimble.Portable.Client.Security;

#endregion Using

namespace Nimble.Portable.Client
{
    public class ClientManager : GenericClientManager
    {
        #region Private Members

        #region Properties

        private static readonly ClientManager instance = new ClientManager();

        #endregion Properties

        #endregion Private Members

        #region Public Members

        #region Properties

        public static ClientManager Instance
        {
            get { return instance; }
        }

        public CommonClient Common
        {
            get
            {
                return GetClient<CommonClient, ICommon>(new CommonClient(new BasicHttpBinding(), new EndpointAddress(new Uri(ServiceHost))));
            }
        }

        public SecurityClient Security
        {
            get
            {
                return GetClient<SecurityClient, ISecurity>(new SecurityClient(new BasicHttpBinding(), new EndpointAddress(new Uri(ServiceHost))));
            }
        }

        public MultilanguageClient Multilanguage
        {
            get
            {
                return GetClient<MultilanguageClient, IMultilanguage>(new MultilanguageClient(new BasicHttpBinding(), new EndpointAddress(new Uri(ServiceHost))));
            }
        }

        public GeolocationClient Geolocation
        {
            get
            {
                return GetClient<GeolocationClient, IGeolocation>(new GeolocationClient(new BasicHttpBinding(), new EndpointAddress(new Uri(ServiceHost))));
            }
        }

        public MaintenanceClient Maintenance
        {
            get
            {
                return GetClient<MaintenanceClient, IMaintenance>(new MaintenanceClient(new BasicHttpBinding(), new EndpointAddress(new Uri(ServiceHost))));
            }
        }

        public OwnerClient Owner
        {
            get
            {
                return GetClient<OwnerClient, IOwner>(new OwnerClient(new BasicHttpBinding(), new EndpointAddress(new Uri(ServiceHost))));
            }
        }

        public NotificationClient Notification
        {
            get
            {
                return GetClient<NotificationClient, INotification>(new NotificationClient(new BasicHttpBinding(), new EndpointAddress(new Uri(ServiceHost))));
            }
        }

        public MulticurrencyClient Multicurrency
        {
            get
            {
                return GetClient<MulticurrencyClient, IMulticurrency>(new MulticurrencyClient(new BasicHttpBinding(), new EndpointAddress(new Uri(ServiceHost))));
            }
        }

        #endregion Properties

        #region Methods

        #region Virtual

        public override void BeginStart()
        {
            EndpointConfigurations = new Dictionary<Type, EndpointConfiguration>();
            var endpointIdentityConfiguration = new EndpointIdentityConfiguration
            {
                EndpointIdentityDnsConfiguration = new EndpointIdentityDnsConfiguration
                {
                    Value = "localhost"
                }
            };
            var endpoint = new EndpointConfiguration
            {
                ClientType = typeof(CommonClient),
                ServiceHost = "Framework/Common.svc",
                ContractType = typeof(ICommon),
                Name = "HttpBinding_ICommon",
                EndpointIdentityConfiguration = endpointIdentityConfiguration
            };
            EndpointConfigurations.Add(endpoint.ClientType, endpoint);
            endpoint = new EndpointConfiguration
            {
                ClientType = typeof(SecurityClient),
                ServiceHost = "Framework/Security.svc",
                ContractType = typeof(ISecurity),
                Name = "HttpBinding_ISecurity",
                EndpointIdentityConfiguration = endpointIdentityConfiguration
            };
            EndpointConfigurations.Add(endpoint.ClientType, endpoint);
            endpoint = new EndpointConfiguration
            {
                ClientType = typeof(MultilanguageClient),
                ServiceHost = "Framework/Multilanguage.svc",
                ContractType = typeof(IMultilanguage),
                Name = "HttpBinding_IMultilanguage",
                EndpointIdentityConfiguration = endpointIdentityConfiguration
            };
            EndpointConfigurations.Add(endpoint.ClientType, endpoint);
            endpoint = new EndpointConfiguration
            {
                ClientType = typeof(GeolocationClient),
                ServiceHost = "Framework/Geolocation.svc",
                ContractType = typeof(IGeolocation),
                Name = "HttpBinding_IGeolocation",
                EndpointIdentityConfiguration = endpointIdentityConfiguration
            };
            EndpointConfigurations.Add(endpoint.ClientType, endpoint);
            endpoint = new EndpointConfiguration
            {
                ClientType = typeof(MaintenanceClient),
                ServiceHost = "Framework/Maintenance.svc",
                ContractType = typeof(IMaintenance),
                Name = "HttpBinding_IMaintenance",
                EndpointIdentityConfiguration = endpointIdentityConfiguration
            };
            EndpointConfigurations.Add(endpoint.ClientType, endpoint);
            endpoint = new EndpointConfiguration
            {
                ClientType = typeof(OwnerClient),
                ServiceHost = "Framework/Owner.svc",
                ContractType = typeof(IOwner),
                Name = "HttpBinding_IOwner",
                EndpointIdentityConfiguration = endpointIdentityConfiguration
            };
            EndpointConfigurations.Add(endpoint.ClientType, endpoint);
            endpoint = new EndpointConfiguration
            {
                ClientType = typeof(NotificationClient),
                ServiceHost = "Framework/Notification.svc",
                ContractType = typeof(INotification),
                Name = "HttpBinding_INotification",
                EndpointIdentityConfiguration = endpointIdentityConfiguration
            };
            EndpointConfigurations.Add(endpoint.ClientType, endpoint);
            endpoint = new EndpointConfiguration
            {
                ClientType = typeof(MulticurrencyClient),
                ServiceHost = "Framework/Multicurrency.svc",
                ContractType = typeof(IMulticurrency),
                Name = "HttpBinding_IMulticurrency",
                EndpointIdentityConfiguration = endpointIdentityConfiguration
            };
            EndpointConfigurations.Add(endpoint.ClientType, endpoint);
            CustomMessageHeader = new CustomMessageHeader("Nimble.Central", "Nimble.Server.Iis");
        }

        public override void SetClientEndpoint<T, I>(T client, EndpointConfiguration endpointConfiguration)
        {
            if (endpointConfiguration == null)
            {
                endpointConfiguration = EndpointConfigurations[typeof(T)];
                client.Endpoint.Address = new EndpointAddress(new Uri(ServiceHost + endpointConfiguration.ServiceHost), new AddressHeader[] {});
                client.Endpoint.Name = endpointConfiguration.Name;
                client.Endpoint.Binding.Name = typeof(BasicHttpBinding).Name;
            }
            else
            {
                client.Endpoint.Address = new EndpointAddress(new Uri(endpointConfiguration.Address), new AddressHeader[] {});
                client.Endpoint.Name = endpointConfiguration.Name;
                client.Endpoint.Binding.Name = endpointConfiguration.BindingConfiguration;
            }
            var type = typeof(T);
            if (BasicHttpBindings.ContainsKey(type))
            {
                client.Endpoint.Binding = BasicHttpBindings[type];
            }
            else
            {
                var basicHttpBinding = (BasicHttpBinding)client.Endpoint.Binding;
                var basicHttpBindingConfiguration = ClientConfiguration.BasicHttpBindingConfigurationFind(endpointConfiguration.BindingConfiguration);
                if (basicHttpBindingConfiguration == null)
                {
                    var timeSpan = new TimeSpan(0, 1, 0, 0);
                    basicHttpBinding.CloseTimeout = timeSpan;
                    basicHttpBinding.OpenTimeout = timeSpan;
                    basicHttpBinding.ReceiveTimeout = timeSpan;
                    basicHttpBinding.SendTimeout = timeSpan;
                    basicHttpBinding.MaxBufferSize = 2147483647;
                    basicHttpBinding.MaxReceivedMessageSize = 2147483647;
                    basicHttpBinding.TextEncoding = Encoding.UTF8;
                    switch (BasicHttpBindingSecurityType)
                    {
                        case BasicHttpBindingSecurityType.Certificate:
                            {
                                basicHttpBinding.Security.Mode = BasicHttpSecurityMode.Transport;
                                break;
                            }
                    }
                }
                else
                {
                    basicHttpBinding.CloseTimeout = TimeSpan.Parse(basicHttpBindingConfiguration.CloseTimeout);
                    basicHttpBinding.OpenTimeout = TimeSpan.Parse(basicHttpBindingConfiguration.OpenTimeout);
                    basicHttpBinding.ReceiveTimeout = TimeSpan.Parse(basicHttpBindingConfiguration.ReceiveTimeout);
                    basicHttpBinding.SendTimeout = TimeSpan.Parse(basicHttpBindingConfiguration.SendTimeout);
                    basicHttpBinding.MaxBufferSize = int.Parse(basicHttpBindingConfiguration.MaxBufferSize);
                    basicHttpBinding.MaxReceivedMessageSize = int.Parse(basicHttpBindingConfiguration.MaxReceivedMessageSize);
                    basicHttpBinding.TextEncoding = Encoding.GetEncoding(basicHttpBindingConfiguration.TextEncoding);
                }
                BasicHttpBindings.Add(type, basicHttpBinding);
            }
        }

        #endregion Virtual

        #endregion Methods

        #endregion Public Members
    }
}
