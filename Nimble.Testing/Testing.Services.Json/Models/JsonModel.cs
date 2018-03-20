#region Using

using System.Configuration;

#endregion Using

namespace Testing.Services.Json.Models
{
    public class JsonModel
    {
        #region Public Members

        #region Properties

        public string ServiceEndpoint { get; set; }

        public string ResourceLatencyDays { get; set; }

        public string EmplacementCode { get; set; }
        
        public string ApplicationCode { get; set; }

        public string CultureCode { get; set; }
        
        public string TokenCode { get; set; }
        
        public string UserCode { get; set; }
        
        public string UserPassword { get; set; }

        public string ReferenceId { get; set; }
        
        public string RequestStatus { get; set; }

        #endregion Properties

        #region Methods

        public JsonModel()
        {
            ServiceEndpoint = ConfigurationManager.AppSettings["ServiceEndpoint"];
            ResourceLatencyDays = ConfigurationManager.AppSettings["ResourceLatencyDays"];
            EmplacementCode = ConfigurationManager.AppSettings["EmplacementCode"];
            ApplicationCode = ConfigurationManager.AppSettings["ApplicationCode"];
            CultureCode = ConfigurationManager.AppSettings["CultureCode"];
            UserCode = ConfigurationManager.AppSettings["UserCode"];
            UserPassword = ConfigurationManager.AppSettings["UserPassword"];
            ReferenceId = ConfigurationManager.AppSettings["ReferenceId"];
        }

        #endregion Methods

        #endregion Public Members
    }
}