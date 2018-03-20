#region Usings

#endregion Usings

namespace Nimble.Business.Library.Configuration
{
    public class BasicHttpBindingConfiguration
    {
        #region Public Members

        #region Properties

        public string Name { get; set; }

        public string CloseTimeout { get; set; }

        public string OpenTimeout { get; set; }

        public string ReceiveTimeout { get; set; }

        public string SendTimeout { get; set; }

        public string BypassProxyOnLocal { get; set; }

        public string HostNameComparisonMode { get; set; }

        public string MaxBufferSize { get; set; }

        public string MaxBufferPoolSize { get; set; }

        public string MaxReceivedMessageSize { get; set; }

        public string MessageEncoding { get; set; }

        public string TextEncoding { get; set; }

        public string TransferMode { get; set; }

        public string UseDefaultWebProxy { get; set; }

        public string AllowCookies { get; set; }

        public BasicHttpBindingReaderQuotasConfiguration BasicHttpBindingReaderQuotasConfiguration { get; set; }

        public BasicHttpBindingSecurityConfiguration BasicHttpBindingSecurityConfiguration { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    public class BasicHttpBindingReaderQuotasConfiguration
    {
        #region Public Members

        #region Properties

        public string MaxDepth { get; set; }

        public string MaxStringContentLength { get; set; }

        public string MaxArrayLength { get; set; }

        public string MaxBytesPerRead { get; set; }

        public string MaxNameTableCharCount { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    public class BasicHttpBindingSecurityConfiguration
    {
        #region Public Members

        #region Properties

        public string Mode { get; set; }

        public BasicHttpBindingSecurityTransportConfiguration BasicHttpBindingSecurityTransportConfiguration { get; set; }

        public BasicHttpBindingSecurityMessageConfiguration BasicHttpBindingSecurityMessageConfiguration { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    public class BasicHttpBindingSecurityTransportConfiguration
    {
        #region Public Members

        #region Properties

        public string ClientCredentialType { get; set; }

        public string ProxyCredentialType { get; set; }

        public string Realm { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    public class BasicHttpBindingSecurityMessageConfiguration
    {
        #region Public Members

        #region Properties

        public string AlgorithmSuite { get; set; }

        public string ClientCredentialType { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}
