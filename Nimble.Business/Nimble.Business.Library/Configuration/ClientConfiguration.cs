#region Using

using System;
using System.Collections.Generic;
using System.Xml;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Server;

#endregion Using

namespace Nimble.Business.Library.Configuration
{
    public class ClientConfiguration : GenericConfiguration
    {
        #region Private Members

        #region Properties

        private bool useTranslationModule = true;
        private int resourceLastUsedLatencyDays = 10;
        private bool multilanguageCacheOnLoad = true;
        private int smtpPort = 25;
        private int smtpFailedTimeout = 5000;
        private readonly Dictionary<string, EndpointConfiguration> endpoints = new Dictionary<string, EndpointConfiguration>();
        private readonly Dictionary<string, LocationConfiguration> locations = new Dictionary<string, LocationConfiguration>();
        private readonly Dictionary<string, EndpointBehaviorConfiguration> endpointBehaviors = new Dictionary<string, EndpointBehaviorConfiguration>();

        #endregion Properties

        #region Methods

        private EndpointIdentityConfiguration ReadEndpointIdentity(XmlReader subtree)
        {
            var endpointIdentityConfiguration = new EndpointIdentityConfiguration();
            while (subtree.Read())
            {
                if (AddPathElement(subtree).Equals("identity"))
                {
                    endpointIdentityConfiguration.EndpointIdentityDnsConfiguration = ReadEndpointIdentityDns(subtree.ReadSubtree());
                }
                RemovePathElement(subtree);
            }
            return endpointIdentityConfiguration;
        }

        private EndpointIdentityDnsConfiguration ReadEndpointIdentityDns(XmlReader subtree)
        {
            var endpointIdentityDnsConfiguration = new EndpointIdentityDnsConfiguration();
            while (subtree.Read())
            {
                if (AddPathElement(subtree).Equals("dns"))
                {
                    endpointIdentityDnsConfiguration.Value = subtree.GetAttribute("value");
                }
                RemovePathElement(subtree);
            }
            return endpointIdentityDnsConfiguration;
        }

        private EndpointBehaviorDataContractSerializerConfiguration ReadEndpointBehaviorDataContractSerializer(XmlReader subtree)
        {
            var endpointBehaviorDataContractSerializerConfiguration = new EndpointBehaviorDataContractSerializerConfiguration();
            while (subtree.Read())
            {
                if (AddPathElement(subtree).Equals("dataContractSerializer"))
                {
                    endpointBehaviorDataContractSerializerConfiguration.MaxItemsInObjectGraph = subtree.GetAttribute("maxItemsInObjectGraph");
                }
                RemovePathElement(subtree);
            }
            return endpointBehaviorDataContractSerializerConfiguration;
        }

        private LocationSystemWebConfiguration ReadLocationSystemWeb(XmlReader subtree)
        {
            var locationSystemWebConfiguration = new LocationSystemWebConfiguration();
            while (subtree.Read())
            {
                if (AddPathElement(subtree).Equals("system.web"))
                {
                    locationSystemWebConfiguration.LocationSystemWebAuthorizationConfiguration = ReadLocationSystemWebAuthorization(subtree.ReadSubtree());
                }
                RemovePathElement(subtree);
            }
            return locationSystemWebConfiguration;
        }

        private LocationSystemWebAuthorizationConfiguration ReadLocationSystemWebAuthorization(XmlReader subtree)
        {
            var locationSystemWebAuthorizationConfiguration = new LocationSystemWebAuthorizationConfiguration();
            while (subtree.Read())
            {
                if (AddPathElement(subtree).Equals("authorization"))
                {
                    locationSystemWebAuthorizationConfiguration.LocationSystemWebAuthorizationAllowConfiguration = ReadLocationSystemWebAuthorizationAllow(subtree.ReadSubtree());
                }
                RemovePathElement(subtree);
            }
            return locationSystemWebAuthorizationConfiguration;
        }

        private LocationSystemWebAuthorizationAllowConfiguration ReadLocationSystemWebAuthorizationAllow(XmlReader subtree)
        {
            var locationSystemWebAuthorizationAllowConfiguration = new LocationSystemWebAuthorizationAllowConfiguration();
            while (subtree.Read())
            {
                if (AddPathElement(subtree).Equals("allow"))
                {
                    locationSystemWebAuthorizationAllowConfiguration.Users = subtree.GetAttribute("users");
                }
                RemovePathElement(subtree);
            }
            return locationSystemWebAuthorizationAllowConfiguration;
        }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        [ApplicationSetting("CachedEntityTypeNames")]
        public string CachedEntityTypeNames { get; set; }

        [ApplicationSetting("UseTranslationModule")]
        public bool UseTranslationModule
        {
            get { return useTranslationModule; }
            set { useTranslationModule = value; }
        }

        [ApplicationSetting("ResourceLastUsedLatencyDays")]
        public int ResourceLastUsedLatencyDays
        {
            get { return resourceLastUsedLatencyDays; }
            set { resourceLastUsedLatencyDays = value; }
        }

        [ApplicationSetting("CultureCode")]
        public string CultureCode { get; private set; }

        [ApplicationSetting("MultilanguageCacheOnLoad")]
        public bool MultilanguageCacheOnLoad
        {
            get { return multilanguageCacheOnLoad; }
            set { multilanguageCacheOnLoad = value; }
        }

        [ApplicationSetting("EmplacementCode")]
        public string EmplacementCode { get; private set; }

        [ApplicationSetting("ApplicationCode")]
        public string ApplicationCode { get; private set; }

        [ApplicationSetting("StoreIpInfo")]
        public bool StoreIpInfo { get; private set; }

        [ApplicationSetting("SmtpHost")]
        public string SmtpHost { get; private set; }

        [ApplicationSetting("SmtpPort")]
        public int SmtpPort
        {
            get { return smtpPort; }
            private set { smtpPort = value; }
        }

        [ApplicationSetting("SmtpUserName")]
        public string SmtpUserName { get; private set; }

        [ApplicationSetting("SmtpPassword")]
        public string SmtpPassword { get; private set; }

        [ApplicationSetting("SmtpFailedTimeout")]
        public int SmtpFailedTimeout
        {
            get { return smtpFailedTimeout; }
            private set { smtpFailedTimeout = value; }
        }

        [ApplicationSetting("IisStateType")]
        public IisStateType IisStateType { get; private set; }

        [ApplicationSetting("DenyBrowserPageCache")]
        public bool DenyBrowserPageCache { get; private set; }

        [ApplicationSetting("LogPageVisits")]
        public bool LogPageVisits { get; private set; }

        [ApplicationSetting("DateFormat")]
        public string DateFormat { get; private set; }

        [ApplicationSetting("DateMask")]
        public string DateMask { get; private set; }

        [ApplicationSetting("ServiceHost")]
        public string ServiceHost { get; private set; }

        [ApplicationSetting("BasicHttpBindingSecurityType")]
        public BasicHttpBindingSecurityType BasicHttpBindingSecurityType { get; private set; }

        [ApplicationSetting("ClientHostCheckUrl")]
        public string ClientHostCheckUrl { get; set; }

        [ApplicationSetting("ClientHostCheckPattern")]
        public string ClientHostCheckPattern { get; set; }

        #endregion Properties

        #region Methods

        public ClientConfiguration(XmlReader xmlReader) : base(xmlReader)
        {
        }

        public override bool ReadNodes()
        {
            var found = false;
            switch (path)
            {
                case "configuration/system.serviceModel/client/endpoint":
                {
                    var attribute = xmlReader.GetAttribute("address");
                    if (!string.IsNullOrEmpty(attribute) &&
                        !endpoints.ContainsKey(attribute))
                    {
                        endpoints.Add(attribute, new EndpointConfiguration
                        {
                            Address = attribute,
                            Binding = xmlReader.GetAttribute("binding"),
                            BindingConfiguration = xmlReader.GetAttribute("bindingConfiguration"),
                            Contract = xmlReader.GetAttribute("contract"),
                            Name = xmlReader.GetAttribute("name"),
                            BehaviorConfiguration = xmlReader.GetAttribute("behaviorConfiguration"),
                            EndpointIdentityConfiguration = ReadEndpointIdentity(xmlReader.ReadSubtree())
                        });
                    }
                    found = true;
                    break;
                }
                case "configuration/system.serviceModel/behaviors/endpointBehaviors/behavior":
                {
                    var attribute = xmlReader.GetAttribute("name");
                    if (!string.IsNullOrEmpty(attribute) &&
                        !endpointBehaviors.ContainsKey(attribute))
                    {
                        endpointBehaviors.Add(attribute, new EndpointBehaviorConfiguration
                        {
                            Name = attribute,
                            EndpointBehaviorDataContractSerializerConfiguration = ReadEndpointBehaviorDataContractSerializer(xmlReader.ReadSubtree())
                        });
                    }
                    found = true;
                    break;
                }
                case "configuration/location":
                {
                    var attribute = xmlReader.GetAttribute("path");
                    if (!string.IsNullOrEmpty(attribute) &&
                        !locations.ContainsKey(attribute))
                    {
                        locations.Add(attribute, new LocationConfiguration
                        {
                            Path = attribute,
                            LocationSystemWebConfiguration = ReadLocationSystemWeb(xmlReader.ReadSubtree())
                        });
                    }
                    found = true;
                    break;
                }
            }
            return found;
        }

        public EndpointConfiguration EndpointConfigurationFind(string contract)
        {
            EndpointConfiguration endpointConfiguration = null;
            foreach (var endpoint in endpoints)
            {
                if (string.Compare(endpoint.Value.Contract, contract, StringComparison.OrdinalIgnoreCase) != 0) continue;
                endpointConfiguration = endpoint.Value;
                break;
            }
            return endpointConfiguration;
        }

        public bool LocationAllowAnonymous(string locationPath)
        {
            var allowAnonymous = false;
            foreach (var location in locations)
            {
                if (locationPath.Length - locationPath.IndexOf(location.Key, StringComparison.OrdinalIgnoreCase) != location.Key.Length ||
                    location.Value == null ||
                    location.Value.LocationSystemWebConfiguration == null ||
                    location.Value.LocationSystemWebConfiguration.LocationSystemWebAuthorizationConfiguration == null ||
                    location.Value.LocationSystemWebConfiguration.LocationSystemWebAuthorizationConfiguration.LocationSystemWebAuthorizationAllowConfiguration == null ||
                    string.IsNullOrEmpty(location.Value.LocationSystemWebConfiguration.LocationSystemWebAuthorizationConfiguration.LocationSystemWebAuthorizationAllowConfiguration.Users)) continue;
                var users = location.Value.LocationSystemWebConfiguration.LocationSystemWebAuthorizationConfiguration.LocationSystemWebAuthorizationAllowConfiguration.Users;
                allowAnonymous = string.Compare(users, "?", StringComparison.OrdinalIgnoreCase) == 0 || string.Compare(users, "*", StringComparison.OrdinalIgnoreCase) == 0;
                break;
            }
            return allowAnonymous;
        }

        #endregion Methods

        #endregion Public Members
    }
}