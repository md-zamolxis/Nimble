#region Using

using System;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Server.Iis.Extension
{
    public class JsonErrorHandler : Business.Engine.Common.JsonErrorHandler
    {
        #region Public Members

        #region Methods

        public override Exception HandleException(Exception error)
        {
            var faultExceptionDetail = FaultExceptionDetail.Create(error);
            ServerManager.Instance.Common.HandleException(faultExceptionDetail);
            return FaultExceptionDetail.Create(faultExceptionDetail);
        }

        #endregion Methods

        #endregion Public Members
    }
}
