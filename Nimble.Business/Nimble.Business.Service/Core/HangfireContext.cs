#region Using

using System.Web;
using Hangfire;
using Hangfire.Dashboard;
using Hangfire.SqlServer;
using Microsoft.Owin;
using Nimble.Business.Engine.Core;
using Nimble.Business.Library.Common;
using Nimble.Business.Service.Core;
using Owin;

#endregion Using

[assembly: OwinStartup(typeof(HangfireContext))]
namespace Nimble.Business.Service.Core
{
    public class HangfireContext
    {
        #region Public Members

        #region Methods

        public void Configuration(IAppBuilder appBuilder)
        {
            if (string.IsNullOrEmpty(Kernel.Instance.ServerConfiguration.HangfireDatabase)) return;
            GlobalConfiguration.Configuration.UseSqlServerStorage(Kernel.Instance.ServerConfiguration.HangfireDatabase, new SqlServerStorageOptions
            {
                SchemaName = Kernel.Instance.ServerConfiguration.HangfireInstance
            });
            appBuilder.UseHangfireDashboard("/Hangfire", new DashboardOptions
            {
                Authorization = new[] {new DashboardAuthorizationFilter()}
            });
            appBuilder.UseHangfireServer(new BackgroundJobServerOptions
            {
                ServerName = Kernel.Instance.ServerConfiguration.HangfireInstance
            });
        }

        public static void Start()
        {
            if (string.IsNullOrEmpty(Kernel.Instance.ServerConfiguration.HangfireDatabase)) return;
            JobStorage.Current = new SqlServerStorage(Kernel.Instance.ServerConfiguration.HangfireDatabase, new SqlServerStorageOptions
            {
                SchemaName = Kernel.Instance.ServerConfiguration.HangfireInstance
            });
        }

        #endregion Methods

        #endregion Public Members
    }

    public class DashboardAuthorizationFilter : IDashboardAuthorizationFilter
    {
        #region Public Members

        #region Methods

        public bool Authorize(DashboardContext dashboardContext)
        {
            var authorize = !string.IsNullOrEmpty(Kernel.Instance.ServerConfiguration.HangfireAuthorize);
            if (authorize &&
                HttpContext.Current != null)
            {
                var host = HttpContext.Current.Request.ServerVariables[Constants.REMOTE_IP_ADDRESS];
                if (string.IsNullOrEmpty(host))
                {
                    host = HttpContext.Current.Request.ServerVariables[Constants.REMOTE_IP_ADDRESS];
                }
                authorize = Kernel.Instance.ServerConfiguration.HangfireAuthorize.Contains(host);
            }
            return authorize;
            // In case you need an OWIN context, use the next line,
            // `OwinContext` class is the part of the `Microsoft.Owin` package.
            //var context = new OwinContext();

            // Allow all authenticated users to see the Dashboard (potentially dangerous).
            //return context.Authentication.User.Identity.IsAuthenticated;
        }

        #endregion Methods

        #endregion Public Members
    }
}