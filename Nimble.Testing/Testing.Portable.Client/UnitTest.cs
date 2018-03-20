using System;
using System.Xml;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Portable.Client;

namespace Testing.Portable.Client
{
    [TestClass]
    public class UnitTest
    {
        [TestMethod]
        public void TestClient()
        {
            //ClientManager.Instance.Start(XmlReader.Create(AppDomain.CurrentDomain.SetupInformation.ConfigurationFile));
			//ClientManager.Instance.Start("http://80.245.81.59:50004/");
            ClientManager.Instance.Start();
            ClientManager.Instance.Login("sa", "1");
            var genericOutput = ClientManager.Instance.CultureSearch(new CulturePredicate());
        }
    }
}
