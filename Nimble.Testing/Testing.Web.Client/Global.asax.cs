#region Using

using System;
using System.Web;
using Nimble.Business.Library.Model.Framework.Owner;
using Nimble.Server.Iis;

#endregion Using

namespace Testing.Web.Client
{
    public class Global : HttpApplication
    {
        #region Protected Members

        #region Methods

        protected void Application_Start(object sender, EventArgs e)
        {
            ServerManager.ApplicationStart(false);
        }

        protected void Session_Start(object sender, EventArgs e)
        {
            var sessionId = Session.SessionID;
        }

        protected void Application_BeginRequest(object sender, EventArgs e)
        {
            var posts = ServerManager.Instance.Owner.PostSearchPublic(new PostPredicate());
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