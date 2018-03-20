#region Usings

using System;
using System.Collections.Generic;
using System.Xml;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Reflection;

#endregion Usings

namespace Nimble.Business.Library.Configuration
{
    public class ConnectionStringConfiguration
    {
        #region Public Members

        #region Properties

        public string Name { get; set; }

        public string ConnectionString { get; set; }

        public string ProviderName { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    public class GenericConfiguration
    {
        #region Protected Members

        #region Properties

        protected string path;
        protected readonly XmlReader xmlReader;
        protected readonly List<string> elements = new List<string>();
        protected readonly Dictionary<string, string> appSettings = new Dictionary<string, string>();
        protected readonly Dictionary<string, ConnectionStringConfiguration> connectionStrings = new Dictionary<string, ConnectionStringConfiguration>();
        protected readonly Dictionary<string, BasicHttpBindingConfiguration> basicHttpBindings = new Dictionary<string, BasicHttpBindingConfiguration>();

        #endregion Properties

        #region Methods

        protected string GetPath()
        {
            return string.Join("/", elements.ToArray());
        }

        protected void ReadConfiguration()
        {
            while (xmlReader.Read())
            {
                AddPathElement(xmlReader);
                var found = ReadNodes();
                switch (path)
                {
                    case "configuration/appSettings/add":
                    {
                        var attribute = xmlReader.GetAttribute("key");
                        if (!string.IsNullOrEmpty(attribute) &&
                            !appSettings.ContainsKey(attribute))
                        {
                            appSettings.Add(attribute, xmlReader.GetAttribute("value"));
                        }
                        found = true;
                        break;
                    }
                    case "configuration/connectionStrings/add":
                    {
                        var attribute = xmlReader.GetAttribute("name");
                        if (!string.IsNullOrEmpty(attribute) &&
                            !connectionStrings.ContainsKey(attribute))
                        {
                            connectionStrings.Add(attribute, new ConnectionStringConfiguration
                            {
                                Name = attribute,
                                ConnectionString = xmlReader.GetAttribute("connectionString"),
                                ProviderName = xmlReader.GetAttribute("providerName")
                            });
                        }
                        found = true;
                        break;
                    }
                    case "configuration/system.serviceModel/bindings/basicHttpBinding/binding":
                    {
                        var attribute = xmlReader.GetAttribute("name");
                        if (!string.IsNullOrEmpty(attribute) &&
                            !basicHttpBindings.ContainsKey(attribute))
                        {
                            basicHttpBindings.Add(attribute, new BasicHttpBindingConfiguration
                            {
                                Name = attribute,
                                CloseTimeout = xmlReader.GetAttribute("closeTimeout"),
                                OpenTimeout = xmlReader.GetAttribute("openTimeout"),
                                ReceiveTimeout = xmlReader.GetAttribute("receiveTimeout"),
                                SendTimeout = xmlReader.GetAttribute("sendTimeout"),
                                BypassProxyOnLocal = xmlReader.GetAttribute("bypassProxyOnLocal"),
                                HostNameComparisonMode = xmlReader.GetAttribute("hostNameComparisonMode"),
                                MaxBufferSize = xmlReader.GetAttribute("maxBufferSize"),
                                MaxBufferPoolSize = xmlReader.GetAttribute("maxBufferPoolSize"),
                                MaxReceivedMessageSize = xmlReader.GetAttribute("maxReceivedMessageSize"),
                                MessageEncoding = xmlReader.GetAttribute("messageEncoding"),
                                TextEncoding = xmlReader.GetAttribute("textEncoding"),
                                TransferMode = xmlReader.GetAttribute("transferMode"),
                                UseDefaultWebProxy = xmlReader.GetAttribute("useDefaultWebProxy"),
                                AllowCookies = xmlReader.GetAttribute("allowCookies")
                            });
                            var basicHttpBindingConfiguration = ReadBasicHttpBinding(xmlReader.ReadSubtree());
                            basicHttpBindings[attribute].BasicHttpBindingReaderQuotasConfiguration = basicHttpBindingConfiguration.BasicHttpBindingReaderQuotasConfiguration;
                            basicHttpBindings[attribute].BasicHttpBindingSecurityConfiguration = basicHttpBindingConfiguration.BasicHttpBindingSecurityConfiguration;
                        }
                        found = true;
                        break;
                    }
                }
                if (found)
                {
                    elements.RemoveAt(elements.Count - 1);
                    path = GetPath();
                }
                else
                {
                    RemovePathElement(xmlReader);
                }
            }
        }

        protected string AddPathElement(XmlReader element)
        {
            var name = string.Empty;
            if (element.NodeType == XmlNodeType.Element)
            {
                elements.Add(element.Name);
                name = element.Name;
                path = GetPath();
            }
            return name;
        }

        protected void RemovePathElement(XmlReader element)
        {
            if (element.NodeType != XmlNodeType.EndElement) return;
            var index = elements.LastIndexOf(element.Name);
            if (index < 0) return;
            elements.RemoveRange(index, elements.Count - index);
            path = GetPath();
        }

        protected BasicHttpBindingConfiguration ReadBasicHttpBinding(XmlReader subtree)
        {
            var basicHttpBindingConfiguration = new BasicHttpBindingConfiguration();
            while (subtree.Read())
            {
                var name = AddPathElement(subtree);
                if (name.Equals("readerQuotas"))
                {
                    basicHttpBindingConfiguration.BasicHttpBindingReaderQuotasConfiguration = new BasicHttpBindingReaderQuotasConfiguration
                    {
                        MaxDepth = subtree.GetAttribute("maxDepth"),
                        MaxStringContentLength = subtree.GetAttribute("maxStringContentLength"),
                        MaxArrayLength = subtree.GetAttribute("maxArrayLength"),
                        MaxBytesPerRead = subtree.GetAttribute("maxBytesPerRead"),
                        MaxNameTableCharCount = subtree.GetAttribute("maxNameTableCharCount")
                    };
                }
                if (name.Equals("security"))
                {
                    basicHttpBindingConfiguration.BasicHttpBindingSecurityConfiguration = new BasicHttpBindingSecurityConfiguration
                    {
                        Mode = subtree.GetAttribute("mode")
                    };
                    var basicHttpBindingSecurityConfiguration = ReadBasicHttpBindingSecurity(subtree.ReadSubtree());
                    basicHttpBindingConfiguration.BasicHttpBindingSecurityConfiguration.BasicHttpBindingSecurityTransportConfiguration = basicHttpBindingSecurityConfiguration.BasicHttpBindingSecurityTransportConfiguration;
                    basicHttpBindingConfiguration.BasicHttpBindingSecurityConfiguration.BasicHttpBindingSecurityMessageConfiguration = basicHttpBindingSecurityConfiguration.BasicHttpBindingSecurityMessageConfiguration;
                }
                RemovePathElement(subtree);
            }
            return basicHttpBindingConfiguration;
        }

        protected BasicHttpBindingSecurityConfiguration ReadBasicHttpBindingSecurity(XmlReader subtree)
        {
            var basicHttpBindingSecurityConfiguration = new BasicHttpBindingSecurityConfiguration();
            while (subtree.Read())
            {
                var name = AddPathElement(subtree);
                if (name.Equals("transport"))
                {
                    basicHttpBindingSecurityConfiguration.BasicHttpBindingSecurityTransportConfiguration = new BasicHttpBindingSecurityTransportConfiguration
                    {
                        ClientCredentialType = subtree.GetAttribute("clientCredentialType"),
                        ProxyCredentialType = subtree.GetAttribute("proxyCredentialType"),
                        Realm = subtree.GetAttribute("realm")
                    };
                }
                if (name.Equals("message"))
                {
                    basicHttpBindingSecurityConfiguration.BasicHttpBindingSecurityMessageConfiguration = new BasicHttpBindingSecurityMessageConfiguration
                    {
                        AlgorithmSuite = subtree.GetAttribute("algorithmSuite"),
                        ClientCredentialType = subtree.GetAttribute("clientCredentialType")
                    };
                }
                RemovePathElement(subtree);
            }
            return basicHttpBindingSecurityConfiguration;
        }

        protected void SetProperties()
        {
            var typeDeclarator = new TypeDeclarator(GetType());
            foreach (var propertyDeclarator in typeDeclarator.PropertyDeclarators)
            {
                if (propertyDeclarator.ApplicationSetting != null &&
                    appSettings.ContainsKey(propertyDeclarator.ApplicationSetting.Key))
                {
                    var applicationSettingValue = appSettings[propertyDeclarator.ApplicationSetting.Key];
                    if (applicationSettingValue != null)
                    {
                        if (propertyDeclarator.PropertyInfo.PropertyType.IsGenericType &&
                            propertyDeclarator.PropertyInfo.PropertyType.GetGenericTypeDefinition() == ClientStatic.Nullable)
                        {
                            propertyDeclarator.PropertyInfo.SetValue(this, string.IsNullOrEmpty(applicationSettingValue) ? null : Convert.ChangeType(applicationSettingValue, Nullable.GetUnderlyingType(propertyDeclarator.PropertyInfo.PropertyType), null), null);
                        }
                        else if (propertyDeclarator.PropertyInfo.PropertyType.IsEnum)
                        {
                            if (propertyDeclarator.FlagsAttribute == null)
                            {
                                propertyDeclarator.PropertyInfo.SetValue(this, Enum.Parse(propertyDeclarator.PropertyInfo.PropertyType, applicationSettingValue, true), null);
                            }
                            else if (Enum.IsDefined(propertyDeclarator.PropertyInfo.PropertyType, applicationSettingValue))
                            {
                                propertyDeclarator.PropertyInfo.SetValue(this, Convert.ChangeType(applicationSettingValue, Enum.GetUnderlyingType(propertyDeclarator.PropertyInfo.PropertyType), null), null);
                            }
                        }
                        else
                        {
                            propertyDeclarator.PropertyInfo.SetValue(this, Convert.ChangeType(applicationSettingValue, propertyDeclarator.PropertyInfo.PropertyType, null), null);
                        }
                    }
                }
                if (propertyDeclarator.ConnectionString == null ||
                    !appSettings.ContainsKey(propertyDeclarator.ConnectionString.Name)) continue;
                var connectionStringApplicationSetting = appSettings[propertyDeclarator.ConnectionString.Name];
                if (string.IsNullOrEmpty(connectionStringApplicationSetting)) continue;
                propertyDeclarator.PropertyInfo.SetValue(this, connectionStrings[connectionStringApplicationSetting].ConnectionString, null);
            }
        }

        #endregion Methods

        #endregion Protected Members

        #region Public Members

        #region Methods

        public GenericConfiguration(XmlReader xmlReader)
        {
            this.xmlReader = xmlReader;
            if (xmlReader == null) return;
            ReadConfiguration();
            SetProperties();
        }

        public virtual bool ReadNodes()
        {
            return false;
        }

        public BasicHttpBindingConfiguration BasicHttpBindingConfigurationFind(string name)
        {
            BasicHttpBindingConfiguration basicHttpBindingConfiguration = null;
            foreach (var basicHttpBinding in basicHttpBindings)
            {
                if (string.Compare(basicHttpBinding.Value.Name, name, StringComparison.OrdinalIgnoreCase) != 0) continue;
                basicHttpBindingConfiguration = basicHttpBinding.Value;
                break;
            }
            return basicHttpBindingConfiguration;
        }

        #endregion Methods

        #endregion Public Members
    }
}
