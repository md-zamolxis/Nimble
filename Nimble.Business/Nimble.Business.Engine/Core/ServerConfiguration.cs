#region Using

using System;
using System.Collections.Generic;
using System.Xml;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Configuration;

#endregion Using

namespace Nimble.Business.Engine.Core
{
    public class DatabaseConstraintConfiguration
    {
        #region Public Members

        #region Properties

        public string Key { get; set; }

        public string Primary { get; set; }

        public string Foreign { get; set; }

        public string Insert { get; set; }

        public string Update { get; set; }

        public string Delete { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    public class ServiceRolesConfiguration
    {
        #region Public Members

        #region Properties

        public string Role { get; set; }

        public string Emplacement { get; set; }

        public string Application { get; set; }

        public List<string> Permissions { get; set; }

        #endregion Properties

        #region Methods

        public override string ToString()
        {
            return string.Format("{0}{1}{2}", Role, Emplacement, Application);
        }

        #endregion Methods

        #endregion Public Members
    }

    public class ServerConfiguration : GenericConfiguration
    {
        #region Private Members

        #region Properties

        private bool useTranslationModule = true;
        private int resourceLastUsedLatencyDays = 10;
        private bool multilanguageCacheOnLoad = true;
        private int smtpPort = 25;
        private int smtpTimeout = 5000;
        private int smtpFailedTimeout = 5000;
        private string sessionInactivityTimeout = "00:30:00";
        private string sessionSaveTimeout = "00:03:00";
        private string accountLastUsedLatency = "00:30:00";
        private string hangfireJobExpiration = "00:30:00";
        protected readonly Dictionary<string, DatabaseConstraintConfiguration> databaseConstraints = new Dictionary<string, DatabaseConstraintConfiguration>();
        protected readonly Dictionary<string, ServiceRolesConfiguration> serviceRoles = new Dictionary<string, ServiceRolesConfiguration>();

        #endregion Properties

        #region Methods

        private ServiceRolesConfiguration ReadServiceRolesConfiguration(XmlReader xmlReader, XmlReader subtree)
        {
            ServiceRolesConfiguration serviceRolesConfiguration = null;
            var attribute = xmlReader.GetAttribute("code");
            if (!string.IsNullOrEmpty(attribute))
            {
                serviceRolesConfiguration = new ServiceRolesConfiguration
                {
                    Role = attribute,
                    Emplacement = xmlReader.GetAttribute("emplacement"),
                    Application = xmlReader.GetAttribute("application"),
                    Permissions = new List<string>()
                };
                while (subtree.Read())
                {
                    if (AddPathElement(subtree).Equals("permission"))
                    {
                        attribute = subtree.GetAttribute("code");
                        if (!serviceRolesConfiguration.Permissions.Contains(attribute))
                        {
                            serviceRolesConfiguration.Permissions.Add(attribute);
                        }
                    }
                    RemovePathElement(subtree);
                }
            }
            return serviceRolesConfiguration;
        }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        [ApplicationSetting("CachedEntityTypeNames")]
        public string CachedEntityTypeNames { get; set; }

        [ApplicationSetting("UseTranslationModule")]
        public bool UseTranslationModule
        {
            get { return useTranslationModule; }
            set { useTranslationModule = value; }
        }

        [ApplicationSetting("ResourceLastUsedLatencyDays")]
        public int ResourceLastUsedLatencyDays
        {
            get { return resourceLastUsedLatencyDays; }
            set { resourceLastUsedLatencyDays = value; }
        }

        [ApplicationSetting("CultureName")]
        public string CultureName { get; private set; }

        [ApplicationSetting("MultilanguageCacheOnLoad")]
        public bool MultilanguageCacheOnLoad
        {
            get { return multilanguageCacheOnLoad; }
            set { multilanguageCacheOnLoad = value; }
        }

        [ApplicationSetting("EmplacementCode")]
        public string EmplacementCode { get; private set; }

        [ApplicationSetting("ApplicationCode")]
        public string ApplicationCode { get; private set; }

        [ApplicationSetting("StoreIpInfo")]
        public bool StoreIpInfo { get; private set; }

        [ApplicationSetting("SmtpHost")]
        public string SmtpHost { get; private set; }

        [ApplicationSetting("SmtpPort")]
        public int SmtpPort
        {
            get { return smtpPort; }
            private set { smtpPort = value; }
        }

        [ApplicationSetting("SmtpUserName")]
        public string SmtpUserName { get; private set; }

        [ApplicationSetting("SmtpPassword")]
        public string SmtpPassword { get; private set; }

        [ApplicationSetting("SmtpEnableSsl")]
        public bool SmtpEnableSsl { get; private set; }

        [ApplicationSetting("SmtpUseDefaultCredentials")]
        public bool SmtpUseDefaultCredentials { get; private set; }

        [ApplicationSetting("SmtpTimeout")]
        public int SmtpTimeout
        {
            get { return smtpTimeout; }
            private set { smtpTimeout = value; }
        }

        [ApplicationSetting("SmtpFailedTimeout")]
        public int SmtpFailedTimeout
        {
            get { return smtpFailedTimeout; }
            private set { smtpFailedTimeout = value; }
        }

        [ApplicationSetting("IisStateType")]
        public IisStateType IisStateType { get; private set; }

        [ConnectionString("GenericDatabase")]
        public string GenericDatabase { get; private set; }

        [ConnectionString("GeolocationDatabase")]
        public string GeolocationDatabase { get; private set; }

        [ConnectionString("HangfireDatabase")]
        public string HangfireDatabase { get; private set; }

        [ApplicationSetting("DatabaseBackupsFolderPattern")]
        public string DatabaseBackupsFolderPattern { get; private set; }

        [ApplicationSetting("TemporaryDataFolder")]
        public string TemporaryDataFolder { get; private set; }

        [ApplicationSetting("TemporaryLogFolder")]
        public string TemporaryLogFolder { get; private set; }

        [ApplicationSetting("DatabaseCommandTimeout")]
        public int? DatabaseCommandTimeout { get; private set; }

        [ApplicationSetting("TransactionScopeTimeout")]
        public string TransactionScopeTimeout { get; private set; }

        [ApplicationSetting("TransactionLockTimeout")]
        public string TransactionLockTimeout { get; private set; }

        [ApplicationSetting("TransactionLockDelay")]
        public int TransactionLockDelay { get; private set; }

        [ApplicationSetting("SqlCommandDelay")]
        public string SqlCommandDelay { get; private set; }

        [ApplicationSetting("EventLogSource")]
        public string EventLogSource { get; private set; }

        [ApplicationSetting("EventLogName")]
        public string EventLogName { get; private set; }

        [ApplicationSetting("ForceRestoringDatabases")]
        public bool ForceRestoringDatabases { get; private set; }

        [ApplicationSetting("SessionContextType")]
        public SessionContextType SessionContextType { get; private set; }

        [ApplicationSetting("UseProcessToken")]
        public bool UseProcessToken { get; private set; }

        [ApplicationSetting("SessionInactivityTimeout")]
        public string SessionInactivityTimeout
        {
            get { return sessionInactivityTimeout; }
            private set { sessionInactivityTimeout = value; }
        }

        [ApplicationSetting("SessionSaveTimeout")]
        public string SessionSaveTimeout
        {
            get { return sessionSaveTimeout; }
            private set { sessionSaveTimeout = value; }
        }

        [ApplicationSetting("OpenTokensPath")]
        public string OpenTokensPath { get; private set; }

        [ApplicationSetting("OpenTokensRemoveCron")]
        public string OpenTokensRemoveCron { get; private set; }

        [ApplicationSetting("CultureCode")]
        public string CultureCode { get; private set; }

        [ApplicationSetting("DefineEmplacementCulture")]
        public bool DefineEmplacementCulture { get; private set; }

        [ApplicationSetting("DefineAccountCulture")]
        public bool DefineAccountCulture { get; private set; }

        [ApplicationSetting("AccountLastUsedLatency")]
        public string AccountLastUsedLatency
        {
            get { return accountLastUsedLatency; }
            private set { accountLastUsedLatency = value; }
        }

        [ApplicationSetting("MultilanguageCopy")]
        public bool MultilanguageCopy { get; private set; }

        [ApplicationSetting("EmplacementIsAdministrative")]
        public bool EmplacementIsAdministrative { get; private set; }

        [ApplicationSetting("UserCode")]
        public string UserCode { get; private set; }

        [ApplicationSetting("UserPassword")]
        public string UserPassword { get; private set; }

        [ApplicationSetting("ApplicationIsAdministrative")]
        public bool ApplicationIsAdministrative { get; private set; }

        [ApplicationSetting("RoleCode")]
        public string RoleCode { get; private set; }

        [ApplicationSetting("UpdatePermissions")]
        public bool? UpdatePermissions { get; private set; }

        [ApplicationSetting("UpdateEmployeeActorTypeRoles")]
        public bool UpdateEmployeeActorTypeRoles { get; private set; }

        [ApplicationSetting("MinDate")]
        public DateTime? MinDate { get; private set; }

        [ApplicationSetting("MaxDate")]
        public DateTime? MaxDate { get; private set; }

        [ApplicationSetting("ResetPasswordUrl")]
        public string ResetPasswordUrl { get; private set; }

        [ApplicationSetting("HangfireAuthorize")]
        public string HangfireAuthorize { get; private set; }

        [ApplicationSetting("HangfireDisabled")]
        public bool HangfireDisabled { get; private set; }

        [ApplicationSetting("HangfireJobExpration")]
        public string HangfireJobExpration
        {
            get { return hangfireJobExpiration; }
            private set { hangfireJobExpiration = value; }
        }

        [ApplicationSetting("HangfireInstance")]
        public string HangfireInstance { get; private set; }

        [ApplicationSetting("EmployeeAppliedOn")]
        public DateTime? EmployeeAppliedOn { get; private set; }

        #endregion Properties

        #region Methods

        public ServerConfiguration(XmlReader xmlReader) : base(xmlReader)
        {
        }

        public override bool ReadNodes(XmlReader xmlReader)
        {
            var found = false;
            switch (path)
            {
                case "configuration/database.constraints/add":
                {
                    var attribute = xmlReader.GetAttribute("key");
                    if (!string.IsNullOrEmpty(attribute) &&
                        !databaseConstraints.ContainsKey(attribute))
                    {
                        databaseConstraints.Add(attribute, new DatabaseConstraintConfiguration
                        {
                            Key = attribute,
                            Primary = xmlReader.GetAttribute("primary"),
                            Foreign = xmlReader.GetAttribute("foreign"),
                            Insert = xmlReader.GetAttribute("insert"),
                            Update = xmlReader.GetAttribute("update"),
                            Delete = xmlReader.GetAttribute("delete")
                        });
                    }
                    found = true;
                    break;
                }
                case "configuration/service.roles/role":
                {
                    var serviceRolesConfiguration = ReadServiceRolesConfiguration(xmlReader, xmlReader.ReadSubtree());
                    if (serviceRolesConfiguration != null)
                    {
                        var key = serviceRolesConfiguration.ToString();
                        if (!serviceRoles.ContainsKey(key))
                        {
                            serviceRoles.Add(key, serviceRolesConfiguration);
                        }
                    }
                    found = true;
                    break;
                }
            }
            return found;
        }

        public DatabaseConstraintConfiguration DatabaseConstraintFind(string sqlExceptionMessage)
        {
            DatabaseConstraintConfiguration databaseConstraintConfiguration = null;
            foreach (var databaseConstraint in databaseConstraints)
            {
                if (sqlExceptionMessage.IndexOf(databaseConstraint.Key, StringComparison.Ordinal) < 0) continue;
                databaseConstraintConfiguration = databaseConstraint.Value;
                break;
            }
            return databaseConstraintConfiguration;
        }

        public Dictionary<string, ServiceRolesConfiguration> ServiceRoles()
        {
            return serviceRoles;
        }

        #endregion Methods

        #endregion Public Members
    }
}