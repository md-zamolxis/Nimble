#region Using

using System;
using System.Web;

#endregion Using

namespace Nimble.Server.Iis
{
    public class Global : HttpApplication
    {
        #region Protected Members

        #region Methods

        protected void Application_Start(object sender, EventArgs e)
        {
            ServerManager.ApplicationStart(true);
        }

        protected void Session_Start(object sender, EventArgs e)
        {
            var sessionId = Session.SessionID;
        }

        protected void Application_BeginRequest(object sender, EventArgs e)
        {

        }

        protected void Application_AuthenticateRequest(object sender, EventArgs e)
        {

        }

        protected void Application_Error(object sender, EventArgs e)
        {

        }

        protected void Session_End(object sender, EventArgs e)
        {

        }

        protected void Application_End(object sender, EventArgs e)
        {
            ServerManager.ApplicationEnd();
        }

        #endregion Methods

        #endregion Protected Members
    }
}