#region Using

using System;
using System.IO;
using System.Web;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Engine.Common
{
    public class JsonHttpModule : IHttpModule
    {
        #region Private Members

        #region Methods

        private static void context_AcquireRequestState(object sender, EventArgs e)
        {
            var httpApplication = sender as HttpApplication;
            if (httpApplication == null ||
                !SessionExists()) return;
            var stream = httpApplication.Request.InputStream;
            var streamReader = new StreamReader(stream);
            RequestBody = streamReader.ReadToEnd();
            stream.Position = 0;
        }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Methods

        public void Dispose()
        {
        }

        public void Init(HttpApplication context)
        {
            context.AcquireRequestState += context_AcquireRequestState;
        }

        public static bool SessionExists()
        {
            return HttpContext.Current != null && HttpContext.Current.Session != null;
        }

        public static string RequestBody
        {
            get
            {
                string requestBody = null;
                if (SessionExists())
                {
                    requestBody = HttpContext.Current.Session[Constants.JSON_HTTP_MODULE_REQUEST_BODY_KEY].ToString();
                }
                return requestBody;
            }
            set
            {
                if (SessionExists())
                {
                    HttpContext.Current.Session[Constants.JSON_HTTP_MODULE_REQUEST_BODY_KEY] = value;
                }
            }
        }

        #endregion Methods

        #endregion Public Members
    }
}