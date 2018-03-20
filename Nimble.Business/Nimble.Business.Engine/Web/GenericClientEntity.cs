#region Using

using System;
using System.Net;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Engine.Web
{
    public class GenericClientEntity<T>
    {
        #region Public Members

        #region Properties

        public string Endpoint { get; set; }

        public string Method { get; set; }

        public string MethodType { get; set; }

        public T Entity { get; set; }

        public string Json { get; set; }

        public WebHeaderCollection Headers { get; set; }

        public Exception Exception { get; set; }

        public FaultExceptionDetail FaultExceptionDetail { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}
