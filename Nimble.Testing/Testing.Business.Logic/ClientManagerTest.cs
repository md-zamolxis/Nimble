using Microsoft.VisualStudio.TestTools.UnitTesting;
using Nimble.Business.Engine.Web;
using Nimble.Business.Library.Server;
using Nimble.Business.Service.Core;
using Nimble.Server.Iis;

namespace Testing.Business.Logic
{
    [TestClass]
    public class ClientManagerTest
    {
        [TestMethod]
        public void TestLogin()
        {
            ServerManager.ApplicationStart(false);
            var clientManager = new ClientManager
            {
                ServiceHost = "http://localhost/Nimble.Server.Iis/",
                RequestContentType = "application/json",
                CustomMessageHeader = new CustomMessageHeader(Kernel.Instance.ServerConfiguration.EmplacementCode, Kernel.Instance.ServerConfiguration.ApplicationCode)
            };
            var login = clientManager.Login("sa", "1");
            var tokenIsExpired = clientManager.TokenIsExpired();
        }
    }
}
