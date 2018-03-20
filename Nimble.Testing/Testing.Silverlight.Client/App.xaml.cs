using System;
using System.Net;
using System.Net.Browser;
using System.Windows;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Business.Library.Server;
using Nimble.Silverlight.Client;

namespace Testing.Silverlight.Client
{
    public partial class App : Application
    {
        private GenericOutput<Culture> genericOutputCulture;
        private GenericOutput<Resource> genericOutputResource;
        private GenericOutput<Translation> genericOutputTranslation;

        public App()
        {
            this.Startup += this.Application_Startup;
            this.Exit += this.Application_Exit;
            this.UnhandledException += this.Application_UnhandledException;
            WebRequest.RegisterPrefix("http://", WebRequestCreator.ClientHttp);
            WebRequest.RegisterPrefix("https://", WebRequestCreator.ClientHttp);

            InitializeComponent();
        }

        private void MultilanguageLoad()
        {
            if (genericOutputCulture != null &&
                genericOutputResource != null &&
                genericOutputTranslation != null)
            {
                ClientManager.Instance.MultilanguageLoad(genericOutputCulture, genericOutputResource, genericOutputTranslation);
            }
        }

        private void Application_Startup(object sender, StartupEventArgs startupEventArgs)
        {
            ClientManager.Instance.Start();
            //ClientManager.Instance.Start("https://localhost/Nimble.Server.Iis/", BasicHttpBindingSecurityType.Certificate);
            //ClientManager.Instance.Start("http://provectapos.com:8021/");
            //ClientManager.Instance.Start("https://provectapos.com/", BasicHttpBindingSecurityType.Certificate);
            var culture = ClientManager.Instance.Multilanguage;
            culture.CultureSearchCompleted += (s, e) =>
                {
                    if (e.Error != null)
                    {
                        throw e.Error;
                    }
                    genericOutputCulture = e.Result;
                    MultilanguageLoad();
                };
            culture.CultureSearchAsync(new CulturePredicate());
            culture.CloseAsync();
            var resource = ClientManager.Instance.Multilanguage;
            resource.ResourceSearchCompleted += (s, e) =>
                {
                    if (e.Error != null)
                    {
                        throw e.Error;
                    }
                    genericOutputResource = e.Result;
                    MultilanguageLoad();
                };
            resource.ResourceSearchAsync(new ResourcePredicate());
            resource.CloseAsync();
            var translation = ClientManager.Instance.Multilanguage;
            translation.TranslationSearchCompleted += (s, e) =>
                {
                    if (e.Error != null)
                    {
                        throw e.Error;
                    }
                    genericOutputTranslation = e.Result;
                    MultilanguageLoad();
                };
            translation.TranslationSearchAsync(new TranslationPredicate());
            translation.CloseAsync();
            this.RootVisual = new MainPage();
        }

        private void Application_Exit(object sender, EventArgs e)
        {

        }

        private void Application_UnhandledException(object sender, ApplicationUnhandledExceptionEventArgs e)
        {
            // If the app is running outside of the debugger then report the exception using
            // the browser's exception mechanism. On IE this will display it a yellow alert 
            // icon in the status bar and Firefox will display a script error.
            if (!System.Diagnostics.Debugger.IsAttached)
            {

                // NOTE: This will allow the application to continue running after an exception has been thrown
                // but not handled. 
                // For production applications this error handling should be replaced with something that will 
                // report the error to the website and stop the application.
                e.Handled = true;
                Deployment.Current.Dispatcher.BeginInvoke(delegate { ReportErrorToDOM(e); });
            }
        }

        private void ReportErrorToDOM(ApplicationUnhandledExceptionEventArgs e)
        {
            try
            {
                string errorMsg = e.ExceptionObject.Message + e.ExceptionObject.StackTrace;
                errorMsg = errorMsg.Replace('"', '\'').Replace("\r\n", @"\n");

                System.Windows.Browser.HtmlPage.Window.Eval("throw new Error(\"Unhandled Error in Silverlight Application " + errorMsg + "\");");
            }
            catch (Exception)
            {
            }
        }
    }
}
