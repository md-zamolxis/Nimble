#region Using

using System;
using System.Collections.Generic;
using System.ServiceModel;
using System.ServiceModel.Channels;
using System.Xml;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Configuration;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Business.Library.Model.Framework.Owner;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Library.Reflection;

#endregion Using

namespace Nimble.Business.Library.Server
{
    public enum BasicHttpBindingSecurityType
    {
        Default,
        Certificate
    }

    public abstract class GenericClientManager
    {
        #region Private Members

        #region Properties

        private readonly object semaphore = new object();

        #endregion Properties

        #endregion Private Members

        #region Public Members

        #region Properties

        public Dictionary<Type, EndpointConfiguration> EndpointConfigurations { get; set; }

        public Dictionary<Type, BasicHttpBinding> BasicHttpBindings { get; set; }

        public CustomMessageHeader CustomMessageHeader { get; set; }

        public ClientConfiguration ClientConfiguration { get; set; }

        public TypeDeclaratorManager TypeDeclaratorManager { get; set; }

        public GenericCache GenericCache { get; set; }

        public BasicHttpBindingSecurityType BasicHttpBindingSecurityType { get; set; }

        public string ServiceHost { get; set; }

        public Token Token { get; set; }

        #endregion Properties

        #region Methods

        public void Start(XmlReader xmlReader)
        {
            BeginStart();
            if (EndpointConfigurations == null)
            {
                EndpointConfigurations = new Dictionary<Type, EndpointConfiguration>();
            }
            if (BasicHttpBindings == null)
            {
                BasicHttpBindings = new Dictionary<Type, BasicHttpBinding>();
            }
            if (CustomMessageHeader == null)
            {
                CustomMessageHeader = new CustomMessageHeader();
            }
            if (string.IsNullOrEmpty(ServiceHost))
            {
                ServiceHost = "http://localhost/Nimble.Server.Iis/";
            }
            ClientConfiguration = new ClientConfiguration(xmlReader);
            if (xmlReader == null)
            {
                ClientConfiguration.UseTranslationModule = true;
                ClientConfiguration.MultilanguageCacheOnLoad = true;
                ClientConfiguration.ResourceLastUsedLatencyDays = 10;
                ClientConfiguration.CachedEntityTypeNames = "Culture; Resource; Translation";
                ClientConfiguration.ClientHostCheckUrl = "http://checkip.dyndns.org";
                ClientConfiguration.ClientHostCheckPattern = @"Current IP Address:\s(\d+.\d+.\d+.\d+)";
            }
            else
            {
                BasicHttpBindingSecurityType = ClientConfiguration.BasicHttpBindingSecurityType;
            }
            TypeDeclaratorManager = new TypeDeclaratorManager();
            GenericCache = new GenericCache(ClientConfiguration.CachedEntityTypeNames);
            if (!string.IsNullOrEmpty(ClientConfiguration.EmplacementCode))
            {
                CustomMessageHeader.EmplacementCode = new KeyValuePair<string, string>(CustomMessageHeader.EmplacementCode.Key, ClientConfiguration.EmplacementCode);
            }
            if (!string.IsNullOrEmpty(ClientConfiguration.ApplicationCode))
            {
                CustomMessageHeader.ApplicationCode = new KeyValuePair<string, string>(CustomMessageHeader.ApplicationCode.Key, ClientConfiguration.ApplicationCode);
            }
            CustomMessageHeader.CultureCode = new KeyValuePair<string, string>(CustomMessageHeader.CultureCode.Key, GetCultureCode());
            CustomMessageHeader.ClientHost = new KeyValuePair<string, string>(CustomMessageHeader.ClientHost.Key, GetClientHost());
            if (!string.IsNullOrEmpty(ClientConfiguration.ServiceHost))
            {
                ServiceHost = ClientConfiguration.ServiceHost;
            }
            EndStart();
            if (ClientConfiguration.UseTranslationModule)
            {
                MultilanguageLoad(
                    CultureSearch(new CulturePredicate()), 
                    ResourceSearch(new ResourcePredicate()), 
                    TranslationSearch(new TranslationPredicate
                        {
                            Translated = true
                        }));
            }
            Read();
        }

        public void Start()
        {
            Start((XmlReader)null);
        }

        public void Start(string serviceHost)
        {
            ServiceHost = serviceHost;
            Start();
        }

        public void Start(BasicHttpBindingSecurityType basicHttpBindingSecurityType)
        {
            BasicHttpBindingSecurityType = basicHttpBindingSecurityType;
            Start();
        }

        public void Start(string serviceHost, BasicHttpBindingSecurityType basicHttpBindingSecurityType)
        {
            ServiceHost = serviceHost;
            BasicHttpBindingSecurityType = basicHttpBindingSecurityType;
            Start();
        }

        public void MultilanguageLoad(GenericOutput<Culture> cultureSearch, GenericOutput<Resource> resourceSearch, GenericOutput<Translation> translationSearch)
        {
            if (!ClientConfiguration.MultilanguageCacheOnLoad) return;
            lock (semaphore)
            {
                if (GenericCache.EntityIsCached(ClientStatic.Culture))
                {
                    GenericCache.Remove(ClientStatic.Culture);
                    if (cultureSearch != null &&
                        cultureSearch.Entities != null)
                    {
                        GenericCache.AddRange(cultureSearch.Entities.ToArray());
                    }
                }
                if (GenericCache.EntityIsCached(ClientStatic.Resource))
                {
                    GenericCache.Remove(ClientStatic.Resource);
                    if (resourceSearch != null &&
                        resourceSearch.Entities != null)
                    {
                        GenericCache.AddRange(resourceSearch.Entities.ToArray());
                    }
                }
                if (GenericCache.EntityIsCached(ClientStatic.Translation))
                {
                    GenericCache.Remove(ClientStatic.Translation);
                    if (translationSearch != null &&
                        translationSearch.Entities != null)
                    {
                        GenericCache.AddRange(translationSearch.Entities.ToArray());
                    }
                }
            }
        }

        public T GetClient<T, I>(T client)
            where T : ClientBase<I>, new()
            where I : class
        {
            lock (semaphore)
            {
                SetClientEndpoint<T, I>(client, ClientConfiguration.EndpointConfigurationFind(client.Endpoint.Contract.ConfigurationName));
                SetMessageHeader(client.InnerChannel);
                return client;
            }
        }

        public void SetMessageHeader(KeyValuePair<string, string> keyValuePair)
        {
            if (OperationContext.Current.OutgoingMessageHeaders.FindHeader(keyValuePair.Key, CustomMessageHeader.Namespace) < 0)
            {
                OperationContext.Current.OutgoingMessageHeaders.Add(MessageHeader.CreateHeader(keyValuePair.Key, CustomMessageHeader.Namespace, keyValuePair.Value));
            }
        }

        public void SetMessageHeader(IContextChannel contextChannel)
        {
            var operationContextScope = new OperationContextScope(contextChannel);
            SetMessageHeader(CustomMessageHeader.EmplacementCode);
            SetMessageHeader(CustomMessageHeader.ApplicationCode);
            SetMessageHeader(CustomMessageHeader.CultureCode);
            SetMessageHeader(CustomMessageHeader.ClientHost);
            SetMessageHeader(CustomMessageHeader.ClientGeospatial);
            SetMessageHeader(CustomMessageHeader.ClientUUID);
            SetMessageHeader(CustomMessageHeader.ClientDevice);
            SetMessageHeader(CustomMessageHeader.ClientPlatform);
            SetMessageHeader(CustomMessageHeader.ClientApplication);
            SetMessageHeader(CustomMessageHeader.ExternalReference);
            var index = OperationContext.Current.OutgoingMessageHeaders.FindHeader(CustomMessageHeader.TokenCode.Key, CustomMessageHeader.Namespace);
            var session = Token == null ? string.Empty : Token.Code;
            if (index >= 0 &&
                (string.IsNullOrEmpty(session) ||
                 string.CompareOrdinal(OperationContext.Current.OutgoingMessageHeaders.GetHeader<string>(index), session) != 0))
            {
                OperationContext.Current.OutgoingMessageHeaders.RemoveAt(index);
                index = -1;
            }
            if (!string.IsNullOrEmpty(session) &&
                index < 0)
            {
                OperationContext.Current.OutgoingMessageHeaders.Add(MessageHeader.CreateHeader(CustomMessageHeader.TokenCode.Key, CustomMessageHeader.Namespace, session));
            }
        }

        public Token Login(string userCode, string userPassword)
        {
            var token = TokenLogin(userCode, userPassword);
            if (token != null)
            {
                Token = token;
            }
            return token;
        }

        public bool Logout()
        {
            var isLogout = TokenLogout();
            if (isLogout)
            {
                Token = null;
            }
            return isLogout;
        }

        public Token Read()
        {
            var token = TokenRead();
            if (token != null)
            {
                Token = token;
            }
            return Token;
        }

        public Token Update()
        {
            if (Token != null)
            {
                Token = TokenUpdate(Token);
            }
            return Token;
        }

        public Token Update(Token token)
        {
            Read();
            Token = token;
            return Update();
        }

        public Token Update(Culture culture)
        {
            Read();
            if (Token != null &&
                Token.Account != null &&
                culture != null)
            {
                Token.Account.CultureId = culture.Id;
            }
            return Update();
        }

        public Token Update(Person person)
        {
            Read();
            if (Token != null &&
                Token.Person != null &&
                Token.Person.Equals(person))
            {
                Token.Person = person;
            }
            return Update();
        }

        public Token Update(Employee employee)
        {
            Read();
            if (Token != null &&
                Token.Employees != null)
            {
                for (var index = 0; index < Token.Employees.Count; index++)
                {
                    if (!Token.Employees[index].Equals(employee)) continue;
                    Token.Employees[index] = employee;
                    break;
                }
            }
            return Update();
        }

        public Translation Translation(Resource resource)
        {
            Translation translation = null;
            if (resource != null &&
                ClientConfiguration.UseTranslationModule)
            {
                if (Token == null)
                {
                    resource.Emplacement = new Emplacement {Code = CustomMessageHeader.EmplacementCode.Value};
                    resource.Application = new Application {Code = CustomMessageHeader.ApplicationCode.Value};
                }
                else
                {
                    resource.Emplacement = Token.Emplacement;
                    resource.Application = Token.Application;
                }
                resource.Category = resource.Category ?? string.Empty;
                if (GenericCache.EntityIsCached(ClientStatic.Resource))
                {
                    var resourceEntity = GenericCache.GetEntity(resource);
                    if (resourceEntity == null ||
                        (resourceEntity.LastUsedOn.HasValue &&
                        resourceEntity.LastUsedOn.Value.AddDays(ClientConfiguration.ResourceLastUsedLatencyDays) < DateTimeOffset.Now))
                    {
                        resource = ResourceRead(resource);
                        GenericCache.Add(resource);
                    }
                    else
                    {
                        resource = resourceEntity;
                    }
                }
                else
                {
                    resource = ResourceRead(resource);
                }
                translation = new Translation
                    {
                        Resource = resource
                    };
                if (Token == null ||
                    Token.Culture == null)
                {
                    translation.Culture = new Culture
                        {
                            Emplacement = resource.Emplacement,
                            Code = CustomMessageHeader.CultureCode.Value
                        };
                    translation.Culture = ClientConfiguration.MultilanguageCacheOnLoad ? GenericCache.GetEntity(translation.Culture) : CultureRead(translation.Culture);
                }
                else
                {
                    translation.Culture = Token.Culture;
                }
                if (ClientConfiguration.MultilanguageCacheOnLoad)
                {
                    translation = GenericCache.GetEntity(translation);
                }
                else
                {
                    translation = TranslationRead(translation);
                    if (GenericCache.EntityIsCached(ClientStatic.Translation))
                    {
                        GenericCache.Add(translation);
                    }
                }
            }
            return translation;
        }

        public string Translate(string code, string category, params object[] parameters)
        {
            var translated = code;
            var translation = Translation(new Resource
                {
                    Code = code,
                    Category = category
                });
            if (GenericEntity.HasValue(translation))
            {
                translated = translation.Sense;
            }
            if (parameters != null &&
                parameters.Length > 0)
            {
                translated = string.Format(translated, parameters);
            }
            return translated;
        }

        public string Translate(string code, params object[] parameters)
        {
            return Translate(code, string.Empty, parameters);
        }

        public string Translate(string code, ResourceCategoryType stringCategoryType, params object[] parameters)
        {
            return Translate(code, stringCategoryType.ToString(), parameters);
        }

        public bool TokenIsMaster(Token token)
        {
            return token != null && token.Person == null;
        }

        public bool TokenIsMaster()
        {
            return TokenIsMaster(Token);
        }

        #region Virtual

        public virtual void BeginStart()
        {
        }

        public virtual void EndStart()
        {
        }

        public virtual void SetClientEndpoint<T, I>(T client, EndpointConfiguration endpointConfiguration)
            where T : ClientBase<I>, new()
            where I : class
        {
        }

        public virtual string GetCultureCode()
        {
            return ClientConfiguration.CultureCode;
        }

        public virtual string GetClientHost()
        {
            return string.Empty;
        }

        public virtual Token TokenLogin(string userCode, string userPassword)
        {
            return null;
        }

        public virtual bool TokenLogout()
        {
            return false;
        }

        public virtual Token TokenRead()
        {
            return null;
        }

        public virtual Token TokenUpdate(Token token)
        {
            return null;
        }

        public virtual Culture CultureRead(Culture culture)
        {
            return null;
        }

        public virtual GenericOutput<Culture> CultureSearch(CulturePredicate culturePredicate)
        {
            return null;
        }

        public virtual Resource ResourceRead(Resource resource)
        {
            return null;
        }

        public virtual GenericOutput<Resource> ResourceSearch(ResourcePredicate resourcePredicate)
        {
            return null;
        }

        public virtual Translation TranslationRead(Translation translation)
        {
            return null;
        }

        public virtual GenericOutput<Translation> TranslationSearch(TranslationPredicate translationPredicate)
        {
            return null;
        }

        #endregion Virtual

        #endregion Methods

        #endregion Public Members
    }
}