#region Using

#endregion Using

namespace Nimble.Business.Engine.Common
{
    public class MailContext
    {
        #region Public Members

        #region Properties

        public string Host { get; set; }

        public int Port { get; set; }

        public string UserName { get; set; }

        public string Password { get; set; }

        public bool EnableSsl { get; set; }

        public bool UseDefaultCredentials { get; set; }

        public int Timeout { get; set; }

        public int FailedTimeout { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}