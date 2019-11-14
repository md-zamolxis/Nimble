#region Using

using System.ComponentModel;
using System.Configuration.Install;
using System.Diagnostics;

#endregion Using

namespace Nimble.Setup.Install
{
    [RunInstaller(true)]
    public class ProjectInstaller : Installer
    {
        #region Public Members

        #region Methods

        public ProjectInstaller()
        {
            const string log = "Nimble";
            var sources = new[]
            {
                "Nimble.Server.Iis",
                "Nimble.Web.Administration",
                "Nimble.Web.Operational",
                "Nimble.Wpf.Operational",
                "Nimble.Win.Operational"
            };
            foreach (var source in sources)
            {
                Installers.Add(new EventLogInstaller
                {
                    Source = source,
                    Log = log
                });
            }
        }

        #endregion Methods

        #endregion Public Members
    }
}