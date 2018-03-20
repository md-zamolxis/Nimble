#region Using

using System;
using System.ServiceModel.Channels;
using System.ServiceModel.Dispatcher;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Server.Iis.Extension
{
    public class ExceptionErrorHandler : IErrorHandler
    {
        #region Public Members

        #region Methods

        public bool HandleError(Exception error)
        {
            return true;
        }

        public void ProvideFault(Exception error, MessageVersion version, ref Message fault)
        {
            var faultExceptionDetail = FaultExceptionDetail.Create(error);
            if (!ServerManager.Instance.Common.HandleException(faultExceptionDetail)) return;
            var faultException = FaultExceptionDetail.Create(faultExceptionDetail);
            fault = Message.CreateMessage(version, faultException.CreateMessageFault(), faultException.Action);
        }

        #endregion Methods

        #endregion Public Members
    }
}
