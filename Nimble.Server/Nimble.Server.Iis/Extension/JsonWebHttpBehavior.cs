#region Using

using System.ServiceModel.Description;
using System.ServiceModel.Dispatcher;

#endregion Using

namespace Nimble.Server.Iis.Extension
{
    public class JsonWebHttpBehavior : WebHttpBehavior
    {
        #region Protected Members

        #region Methods

        protected override void AddServerErrorHandlers(ServiceEndpoint endpoint, EndpointDispatcher endpointDispatcher)
        {
            endpointDispatcher.ChannelDispatcher.ErrorHandlers.Clear();
            endpointDispatcher.ChannelDispatcher.ErrorHandlers.Add(new JsonErrorHandler());
        }

        #endregion Methods

        #endregion Protected Members
    }
}
