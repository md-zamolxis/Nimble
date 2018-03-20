#region Using

using System.Collections.Generic;
using System.Net;
using System.ServiceModel;
using System.ServiceModel.Channels;
using System.ServiceModel.Dispatcher;

#endregion Using

namespace Nimble.Business.Engine.Common
{
    public class CorsDispatchMessageInspector : IDispatchMessageInspector
    {
        #region Public Members

        #region Properties

        public Dictionary<string, string> Headers { get; set; }

        #endregion Properties

        #region Methods

        public CorsDispatchMessageInspector(Dictionary<string, string> headers)
        {
            Headers = headers ?? new Dictionary<string, string>();
        }

        public object AfterReceiveRequest(ref Message request, IClientChannel channel, InstanceContext instanceContext)
        {
            HttpRequestMessageProperty httpRequest = null;
            if (request.Properties.ContainsKey(HttpRequestMessageProperty.Name))
            {
                httpRequest = request.Properties[HttpRequestMessageProperty.Name] as HttpRequestMessageProperty;
            }
            return httpRequest;
        }

        public void BeforeSendReply(ref Message reply, object correlationState)
        {
            if (reply == null ||
                !reply.Properties.ContainsKey(HttpResponseMessageProperty.Name)) return;
            var httpResponse = reply.Properties[HttpResponseMessageProperty.Name] as HttpResponseMessageProperty;
            if (httpResponse == null) return;
            foreach (var item in Headers)
            {
                httpResponse.Headers.Add(item.Key, item.Value);
            }
            var httpRequest = correlationState as HttpRequestMessageProperty;
            if (httpRequest == null ||
                httpRequest.Method.ToLower() != "options") return;
            httpResponse.StatusCode = HttpStatusCode.NoContent;
        }

        #endregion Methods

        #endregion Public Members
    }
}
