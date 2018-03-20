#region Using

using System;
using System.Net;
using System.Runtime.Serialization.Json;
using System.ServiceModel.Channels;
using System.ServiceModel.Dispatcher;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Engine.Common
{
    public class JsonErrorHandler : IErrorHandler
    {
        #region Public Members

        #region Methods

        public bool HandleError(Exception error)
        {
            return true;
        }

        public void ProvideFault(Exception error, MessageVersion version, ref Message fault)
        {
            error = HandleException(error);
            fault = Message.CreateMessage(
                version, 
                string.Empty, 
                FaultExceptionDetail.Create(error), 
                new DataContractJsonSerializer(typeof(FaultExceptionDetail)));
            fault.Properties.Add(WebBodyFormatMessageProperty.Name, new WebBodyFormatMessageProperty(WebContentFormat.Json));
            fault.Properties.Add(HttpResponseMessageProperty.Name, new HttpResponseMessageProperty
                {
                    StatusCode = HttpStatusCode.BadRequest,
                    StatusDescription = string.Empty
                });
        }

        public virtual Exception HandleException(Exception error)
        {
            return error;
        }

        #endregion Methods

        #endregion Public Members
    }
}
