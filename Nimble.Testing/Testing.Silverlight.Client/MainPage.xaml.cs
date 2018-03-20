using System.Windows;
using System.Windows.Controls;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Silverlight.Client;

namespace Testing.Silverlight.Client
{
    public partial class MainPage : UserControl
    {
        public MainPage()
        {
            InitializeComponent();
        }

        private void buttonStart_Click(object sender, RoutedEventArgs routedEventArgs)
        {
            textBoxStart.Text = string.Format(
                "Culture - {0}; Resource - {1}; Translation - {2}",
                ClientManager.Instance.GenericCache.GetEntities<Culture>().Count,
                ClientManager.Instance.GenericCache.GetEntities<Resource>().Count,
                ClientManager.Instance.GenericCache.GetEntities<Translation>().Count
                );
        }

        private void buttonLogin_Click(object sender, RoutedEventArgs routedEventArgs)
        {
            var client = ClientManager.Instance.Common;
            client.LoginCompleted += (s, e) =>
            {
                if (e.Error != null)
                {
                    throw e.Error;
                }
                ClientManager.Instance.Token = e.Result;
                if (ClientManager.Instance.Token != null)
                {
                    textBoxLogin.Text = ClientManager.Instance.Token.Code;
                }
            };
            client.LoginAsync("sa", "1");
            client.CloseAsync();
        }

        private void buttonTokenRead_Click(object sender, RoutedEventArgs routedEventArgs)
        {
            var client = ClientManager.Instance.Common;
            client.TokenReadCompleted += (s, e) =>
            {
                if (e.Error != null)
                {
                    throw e.Error;
                }
                ClientManager.Instance.Token = e.Result;
                if (ClientManager.Instance.Token != null)
                {
                    textBoxTokenRead.Text = ClientManager.Instance.Token.Code;
                }
            };
            client.TokenReadAsync();
            client.CloseAsync();
        }
    }
}
