#region Using

using System.Collections.Generic;

#endregion Using

namespace Nimble.Business.Library.Server
{
    public class CustomMessageHeader
    {
        #region Public Members

        #region Properties

        public string Namespace { get; set; }

        public KeyValuePair<string, string> EmplacementCode { get; set; }

        public KeyValuePair<string, string> ApplicationCode { get; set; }

        public KeyValuePair<string, string> CultureCode { get; set; }

        public KeyValuePair<string, string> ClientHost { get; set; }

        public KeyValuePair<string, string> ClientGeospatial { get; set; }

        public KeyValuePair<string, string> ClientUUID { get; set; }

        public KeyValuePair<string, string> ClientDevice { get; set; }

        public KeyValuePair<string, string> ClientPlatform { get; set; }

        public KeyValuePair<string, string> ClientApplication { get; set; }

        public KeyValuePair<string, string> ExternalReference { get; set; }

        public KeyValuePair<string, string> TokenCode { get; set; }

        #endregion Properties

        #region Methods

        public CustomMessageHeader()
        {
            Namespace = "http://www.royaldujagroup.com/";
            EmplacementCode = new KeyValuePair<string, string>("EmplacementCode", string.Empty);
            ApplicationCode = new KeyValuePair<string, string>("ApplicationCode", string.Empty);
            CultureCode = new KeyValuePair<string, string>("CultureCode", string.Empty);
            ClientHost = new KeyValuePair<string, string>("ClientHost", string.Empty);
            ClientGeospatial = new KeyValuePair<string, string>("ClientGeospatial", string.Empty);
            ClientUUID = new KeyValuePair<string, string>("ClientUUID", string.Empty);
            ClientDevice = new KeyValuePair<string, string>("ClientDevice", string.Empty);
            ClientPlatform = new KeyValuePair<string, string>("ClientPlatform", string.Empty);
            ClientApplication = new KeyValuePair<string, string>("ClientApplication", string.Empty);
            ExternalReference = new KeyValuePair<string, string>("ExternalReference", string.Empty);
            TokenCode = new KeyValuePair<string, string>("TokenCode", string.Empty);
        }

        public CustomMessageHeader(string emplacementCode, string applicationCode) : this()
        {
            EmplacementCode = new KeyValuePair<string, string>(EmplacementCode.Key, emplacementCode);
            ApplicationCode = new KeyValuePair<string, string>(ApplicationCode.Key, applicationCode);
        }

        #endregion Methods

        #endregion Public Members
    }
}
