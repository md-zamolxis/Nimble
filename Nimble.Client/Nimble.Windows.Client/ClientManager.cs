#region Using

using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.ServiceModel;
using System.ServiceModel.Channels;
using System.ServiceModel.Description;
using System.ServiceModel.Security;
using System.Text;
using System.Text.RegularExpressions;
using System.Xml;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Configuration;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Library.Server;
using Nimble.Windows.Client.Common;
using Nimble.Windows.Client.Multicurrency;
using Nimble.Windows.Client.Geolocation;
using Nimble.Windows.Client.Maintenance;
using Nimble.Windows.Client.Multilanguage;
using Nimble.Windows.Client.Notification;
using Nimble.Windows.Client.Owner;
using Nimble.Windows.Client.Security;

#endregion Using

namespace Nimble.Windows.Client
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

        public override void EndStart()
        {
            if (BasicHttpBindingSecurityType == BasicHttpBindingSecurityType.Certificate)
            {
                ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };
            }
        }

        public override void SetClientEndpoint<T, I>(T client, EndpointConfiguration endpointConfiguration)
        {
            if (endpointConfiguration == null)
            {
                endpointConfiguration = EndpointConfigurations[typeof(T)];
                client.Endpoint.Address = new EndpointAddress(new Uri(ServiceHost + endpointConfiguration.ServiceHost), new DnsEndpointIdentity(endpointConfiguration.EndpointIdentityConfiguration.EndpointIdentityDnsConfiguration.Value), new AddressHeaderCollection());
                client.Endpoint.Contract = ContractDescription.GetContract(endpointConfiguration.ContractType);
                client.Endpoint.Name = endpointConfiguration.Name;
                client.Endpoint.Binding.Name = typeof(BasicHttpBinding).Name;
                foreach (var operationDescription in client.Endpoint.Contract.Operations)
                {
                    var dataContractSerializerOperationBehavior = operationDescription.Behaviors.Find<DataContractSerializerOperationBehavior>();
                    if (dataContractSerializerOperationBehavior == null)
                    {
                        dataContractSerializerOperationBehavior = new DataContractSerializerOperationBehavior(operationDescription);
                        operationDescription.Behaviors.Add(dataContractSerializerOperationBehavior);
                    }
                    dataContractSerializerOperationBehavior.MaxItemsInObjectGraph = 2147483647;
                }
            }
            else
            {
                client.Endpoint.Address = new EndpointAddress(new Uri(endpointConfiguration.Address), new DnsEndpointIdentity(endpointConfiguration.EndpointIdentityConfiguration.EndpointIdentityDnsConfiguration.Value), new AddressHeaderCollection());
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
                    basicHttpBinding.BypassProxyOnLocal = false;
                    basicHttpBinding.HostNameComparisonMode = HostNameComparisonMode.StrongWildcard;
                    basicHttpBinding.MaxBufferSize = 2147483647;
                    basicHttpBinding.MaxBufferPoolSize = 524288;
                    basicHttpBinding.MaxReceivedMessageSize = 2147483647;
                    basicHttpBinding.MessageEncoding = WSMessageEncoding.Text;
                    basicHttpBinding.TextEncoding = Encoding.UTF8;
                    basicHttpBinding.TransferMode = TransferMode.Streamed;
                    basicHttpBinding.UseDefaultWebProxy = true;
                    basicHttpBinding.AllowCookies = false;
                    basicHttpBinding.ReaderQuotas = new XmlDictionaryReaderQuotas
                        {
                            MaxDepth = 32,
                            MaxStringContentLength = 2147483647,
                            MaxArrayLength = 2147483647,
                            MaxBytesPerRead = 4096,
                            MaxNameTableCharCount = 16384
                        };
                    switch (BasicHttpBindingSecurityType)
                    {
                        case BasicHttpBindingSecurityType.Default:
                            {
                                basicHttpBinding.Security = new BasicHttpSecurity
                                    {
                                        Mode = BasicHttpSecurityMode.None,
                                        Transport = new HttpTransportSecurity
                                            {
                                                ClientCredentialType = HttpClientCredentialType.None,
                                                ProxyCredentialType = HttpProxyCredentialType.None
                                            },
                                        Message = new BasicHttpMessageSecurity
                                            {
                                                AlgorithmSuite = SecurityAlgorithmSuite.Default,
                                                ClientCredentialType = BasicHttpMessageCredentialType.UserName
                                            }
                                    };
                                break;
                            }
                        case BasicHttpBindingSecurityType.Certificate:
                            {
                                basicHttpBinding.Security = new BasicHttpSecurity
                                    {
                                        Mode = BasicHttpSecurityMode.Transport,
                                        Transport = new HttpTransportSecurity
                                            {
                                                ClientCredentialType = HttpClientCredentialType.None,
                                                ProxyCredentialType = HttpProxyCredentialType.None
                                            },
                                        Message = new BasicHttpMessageSecurity
                                            {
                                                AlgorithmSuite = SecurityAlgorithmSuite.Default,
                                                ClientCredentialType = BasicHttpMessageCredentialType.Certificate
                                            }
                                    };
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
                    basicHttpBinding.BypassProxyOnLocal = bool.Parse(basicHttpBindingConfiguration.BypassProxyOnLocal);
                    basicHttpBinding.HostNameComparisonMode = (HostNameComparisonMode)Enum.Parse(typeof(HostNameComparisonMode), basicHttpBindingConfiguration.HostNameComparisonMode);
                    basicHttpBinding.MaxBufferSize = int.Parse(basicHttpBindingConfiguration.MaxBufferSize);
                    basicHttpBinding.MaxBufferPoolSize = int.Parse(basicHttpBindingConfiguration.MaxBufferPoolSize);
                    basicHttpBinding.MaxReceivedMessageSize = int.Parse(basicHttpBindingConfiguration.MaxReceivedMessageSize);
                    basicHttpBinding.MessageEncoding = (WSMessageEncoding)Enum.Parse(typeof(WSMessageEncoding), basicHttpBindingConfiguration.MessageEncoding);
                    basicHttpBinding.TextEncoding = Encoding.GetEncoding(basicHttpBindingConfiguration.TextEncoding);
                    basicHttpBinding.TransferMode = (TransferMode)Enum.Parse(typeof(TransferMode), basicHttpBindingConfiguration.TransferMode);
                    basicHttpBinding.UseDefaultWebProxy = bool.Parse(basicHttpBindingConfiguration.UseDefaultWebProxy);
                    basicHttpBinding.AllowCookies = bool.Parse(basicHttpBindingConfiguration.AllowCookies);
                    basicHttpBinding.ReaderQuotas = new XmlDictionaryReaderQuotas
                        {
                            MaxDepth = int.Parse(basicHttpBindingConfiguration.BasicHttpBindingReaderQuotasConfiguration.MaxDepth),
                            MaxStringContentLength = int.Parse(basicHttpBindingConfiguration.BasicHttpBindingReaderQuotasConfiguration.MaxStringContentLength),
                            MaxArrayLength = int.Parse(basicHttpBindingConfiguration.BasicHttpBindingReaderQuotasConfiguration.MaxArrayLength),
                            MaxBytesPerRead = int.Parse(basicHttpBindingConfiguration.BasicHttpBindingReaderQuotasConfiguration.MaxBytesPerRead),
                            MaxNameTableCharCount = int.Parse(basicHttpBindingConfiguration.BasicHttpBindingReaderQuotasConfiguration.MaxNameTableCharCount)
                        };
                    basicHttpBinding.Security = new BasicHttpSecurity
                        {
                            Mode = (BasicHttpSecurityMode) Enum.Parse(typeof (BasicHttpSecurityMode), basicHttpBindingConfiguration.BasicHttpBindingSecurityConfiguration.Mode),
                            Transport = new HttpTransportSecurity
                                {
                                    ClientCredentialType = (HttpClientCredentialType) Enum.Parse(typeof (HttpClientCredentialType), basicHttpBindingConfiguration.BasicHttpBindingSecurityConfiguration.BasicHttpBindingSecurityTransportConfiguration.ClientCredentialType),
                                    ProxyCredentialType = (HttpProxyCredentialType) Enum.Parse(typeof (HttpProxyCredentialType), basicHttpBindingConfiguration.BasicHttpBindingSecurityConfiguration.BasicHttpBindingSecurityTransportConfiguration.ProxyCredentialType),
                                    Realm = basicHttpBindingConfiguration.BasicHttpBindingSecurityConfiguration.BasicHttpBindingSecurityTransportConfiguration.Realm
                                },
                            Message = new BasicHttpMessageSecurity
                                {
                                    AlgorithmSuite = SecurityAlgorithmSuite.Default,
                                    ClientCredentialType = (BasicHttpMessageCredentialType) Enum.Parse(typeof (BasicHttpMessageCredentialType), basicHttpBindingConfiguration.BasicHttpBindingSecurityConfiguration.BasicHttpBindingSecurityMessageConfiguration.ClientCredentialType),
                                }
                        };
                }
                BasicHttpBindings.Add(type, basicHttpBinding);
            }
        }

        public override string GetClientHost()
        {
            var clientHost = string.Empty;
            try
            {
                var webRequest = WebRequest.Create(ClientConfiguration.ClientHostCheckUrl);
                var stream = webRequest.GetResponse().GetResponseStream();
                if (stream != null)
                {
                    using (var streamReader = new StreamReader(stream))
                    {
                        var regex = new Regex(ClientConfiguration.ClientHostCheckPattern);
                        var match = regex.Match(streamReader.ReadToEnd());
                        if (match.Success)
                        {
                            clientHost = match.Groups[1].Value;
                        }
                    }
                }
            }
            catch
            {
                clientHost = string.Format(Constants.OBJECT_NOT_DEFINED, "Client host");
            }
            return clientHost;
        }

        public override Token TokenLogin(string userCode, string userPassword)
        {
            return Instance.Common.Login(userCode, userPassword);
        }

        public override bool TokenLogout()
        {
            return Instance.Common.Logout();
        }

        public override Token TokenRead()
        {
            return Instance.Common.TokenRead();
        }

        public override Token TokenUpdate(Token token)
        {
            return Instance.Common.TokenUpdate(token);
        }

        public override Culture CultureRead(Culture culture)
        {
            return Instance.Multilanguage.CultureRead(culture);
        }

        public override GenericOutput<Culture> CultureSearch(CulturePredicate culturePredicate)
        {
            return Instance.Multilanguage.CultureSearch(culturePredicate);
        }

        public override Resource ResourceRead(Resource resource)
        {
            return Instance.Multilanguage.ResourceRead(resource);
        }

        public override GenericOutput<Resource> ResourceSearch(ResourcePredicate resourcePredicate)
        {
            return Instance.Multilanguage.ResourceSearch(resourcePredicate);
        }

        public override Translation TranslationRead(Translation translation)
        {
            return Instance.Multilanguage.TranslationRead(translation);
        }

        public override GenericOutput<Translation> TranslationSearch(TranslationPredicate translationPredicate)
        {
            return Instance.Multilanguage.TranslationSearch(translationPredicate);
        }

        #endregion Virtual

        #endregion Methods

        #endregion Public Members
    }
}
