#region Using

using System;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Logic.Framework;
using Nimble.Business.Engine.Core;
using Nimble.Business.Service.Core;
using Nimble.Server.Iis.Framework;

#endregion Using

namespace Nimble.Server.Iis
{
    public class ServerManager
    {
        #region Private Members

        #region Properties

        private static readonly ServerManager instance = new ServerManager();
        private readonly Common common = new Common();
        private readonly Security security = new Security();
        private readonly Multilanguage multilanguage = new Multilanguage();
        private readonly Maintenance maintenance = new Maintenance();
        private readonly Geolocation geolocation = new Geolocation();
        private readonly Owner owner = new Owner();
        private readonly Notification notification = new Notification();
        private readonly Multicurrency multicurrency = new Multicurrency();

        #endregion Properties

        #endregion Private Members

        #region Public Members

        #region Properties

        public static ServerManager Instance
        {
            get { return instance; }
        }

        public Common Common
        {
            get { return common; }
        }

        public Security Security
        {
            get { return security; }
        }

        public Multilanguage Multilanguage
        {
            get { return multilanguage; }
        }

        public Maintenance Maintenance
        {
            get { return maintenance; }
        }

        public Geolocation Geolocation
        {
            get { return geolocation; }
        }

        public Owner Owner
        {
            get { return owner; }
        }

        public Notification Notification
        {
            get { return notification; }
        }

        public Multicurrency Multicurrency
        {
            get { return multicurrency; }
        }

        public static Token Token { get; set; }

        public static DateTimeOffset? StartedOn { get; set; }

        #endregion Properties

        #region Methods

        public static void ApplicationStart(bool start)
        {
            CommonLogic.ApplicationStart(start);
            StartedOn = DateTimeOffset.Now;
        }

        public static void ApplicationEnd()
        {
            CommonLogic.ApplicationEnd();
        }

        public static Token TokenRead()
        {
            return Token ?? (Token = Instance.Common.TokenRead());
        }

        public static Token TokenLoad()
        {
            return Token = Instance.Common.TokenRead();
        }

        public static Token TokenUpdate()
        {
            if (Token != null)
            {
                Token = Instance.Common.TokenUpdate(Token);
            }
            return Token;
        }

        public static Token TokenUpdate(Token token)
        {
            if (Kernel.Instance.SessionManager.SessionContext.Session != null)
            {
                Kernel.Instance.SessionManager.SessionContext.Session.Token = token;
            }
            return Token = token;
        }

        public static Translation Translation(Resource resource)
        {
            return Instance.Common.Translation(resource);
        }

        public static string Translate(string code, string category, params object[] parameters)
        {
            return Instance.Common.Translate(code, category, parameters);
        }

        public static string Translate(string code, params object[] parameters)
        {
            return Translate(code, string.Empty, parameters);
        }

        public static string Translate(string code, ResourceCategoryType stringCategoryType, params object[] parameters)
        {
            return Translate(code, stringCategoryType.ToString(), parameters);
        }

        #endregion Methods

        #endregion Public Members
    }
}