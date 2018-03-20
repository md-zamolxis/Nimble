#region Usings

using System;

#endregion Usings

namespace Nimble.Business.Library.Configuration
{
    public class EndpointConfiguration
    {
        #region Public Members

        #region Properties

        public string Address { get; set; }

        public string Binding { get; set; }

        public string BindingConfiguration { get; set; }

        public string Contract { get; set; }

        public string Name { get; set; }

        public string BehaviorConfiguration { get; set; }

        public EndpointIdentityConfiguration EndpointIdentityConfiguration { get; set; }

        public Type ClientType { get; set; }

        public Type ContractType { get; set; }

        public string ServiceHost { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    public class EndpointIdentityConfiguration
    {
        #region Public Members

        #region Properties

        public EndpointIdentityDnsConfiguration EndpointIdentityDnsConfiguration { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    public class EndpointIdentityDnsConfiguration
    {
        #region Public Members

        #region Properties

        public string Value { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    public class EndpointBehaviorConfiguration
    {
        #region Public Members

        #region Properties

        public string Name { get; set; }

        public EndpointBehaviorDataContractSerializerConfiguration EndpointBehaviorDataContractSerializerConfiguration { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    public class EndpointBehaviorDataContractSerializerConfiguration
    {
        #region Public Members

        #region Properties

        public string MaxItemsInObjectGraph { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}
