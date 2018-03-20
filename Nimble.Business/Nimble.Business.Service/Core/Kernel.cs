#region Using

using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Web.UI;
using System.Xml;
using Microsoft.AspNetCore.Http;
using Microsoft.SqlServer.Management.Common;
using Microsoft.SqlServer.Management.Smo;
using Nimble.Business.Engine.Common;
using Nimble.Business.Engine.Core;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Common;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Library.Reflection;
using Nimble.Business.Library.Server;

#endregion Using

namespace Nimble.Business.Service.Core
{
    public sealed class Kernel
    {
        #region Private Members

        #region Properties

        private static readonly Kernel instance = new Kernel();

        #endregion Properties

        #endregion Private Members

        #region Public Members

        #region Properties

        public static Kernel Instance
        {
            get { return instance; }
        }

        public ServerConfiguration ServerConfiguration { get; set; }

        public Logging Logging { get; set; }

        public TypeDeclaratorManager TypeDeclaratorManager { get; set; }

        public GenericCache GenericCache { get; set; }

        public SessionManager SessionManager { get; set; }

        public MailManager MailManager { get; set; }

        #endregion Properties

        #region Methods

        #region Common

        public FaultExceptionDetail HandleException(Exception exception)
        {
            var faultExceptionDetail = FaultExceptionDetail.Create(exception);
            if (faultExceptionDetail.Unhandled)
            {
                Logging.Error(exception, false);
            }
            return faultExceptionDetail;
        }

        public void BeginEdit<T>(T entity) where T : GenericEntity
        {
            if (entity == null) return;
            entity.SetPrevious(ClientStatic.XmlClone(entity));
        }

        public void CancelEdit<T>(T entity) where T : GenericEntity
        {
            if (entity == null) return;
            var previous = entity.GetPrevious();
            if (previous == null) return;
            var typeDeclarator = TypeDeclaratorManager.Get(typeof(T));
            foreach (var propertyDeclarator in typeDeclarator.PropertyDeclarators)
            {
                if (!propertyDeclarator.PropertyInfo.CanWrite) continue;
                propertyDeclarator.PropertyInfo.SetValue(entity, propertyDeclarator.GetValue(previous), null);
            }
            entity.SetPrevious(null);
        }

        public void ApplyEdit<T>(T entity) where T : GenericEntity
        {
            if (entity == null) return;
            entity.SetPrevious(null);
        }

        public bool IsChanged<T>(T entity) where T : GenericEntity
        {
            var isChanged = false;
            if (entity != null)
            {
                var previous = entity.GetPrevious();
                if (previous != null)
                {
                    isChanged = (string.CompareOrdinal(ClientStatic.XmlSerialize(entity), ClientStatic.XmlSerialize(previous)) != 0);
                }
            }
            return isChanged;
        }

        public State StateGenerate(DateTimeOffset? dateTimeOffset, bool? isActive)
        {
            return new State
            {
                From = ServerConfiguration.MinDate,
                To = ServerConfiguration.MaxDate,
                AppliedOn = dateTimeOffset,
                IsActive = isActive
            };
        }

        public State StateGenerate(bool? isActive)
        {
            return StateGenerate(DateTimeOffset.Now, isActive);
        }

        public State StateGenerate()
        {
            return StateGenerate(false);
        }

        public State StateGenerate(State state)
        {
            if (state != null)
            {
                state.From = ServerConfiguration.MinDate;
                state.To = ServerConfiguration.MaxDate;
            }
            return state;
        }

        public bool IisStateIsDisabled(IisState iisState, IisStateType iisStateType)
        {
            var isDisabled = true;
            if (iisState != null)
            {
                if (iisState.IisStateType == 0)
                {
                    isDisabled = (ServerConfiguration.IisStateType & iisStateType) != iisStateType;
                }
                else
                {
                    isDisabled = (iisState.IisStateType & iisStateType) != iisStateType;
                }
            }
            return isDisabled;
        }

        #endregion Common

        #region Control State

        public void LoadControlState(object userControl, Type type, Dictionary<string, object> controlState, bool isPostBack)
        {
            var customAttributes = ClientStatic.GetCustomAttributes<IisState>(type, BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Instance, false);
            foreach (var customAttribute in customAttributes)
            {
                if (customAttribute.Value == null ||
                    IisStateIsDisabled(customAttribute.Value, IisStateType.Control)) continue;
                var fieldInfoValue = controlState.ContainsKey(customAttribute.Key.Name) ? controlState[customAttribute.Key.Name] : null;
                if (!isPostBack &&
                    fieldInfoValue == null &&
                    customAttribute.Value.CreateNew)
                {
                    customAttribute.Key.SetValue(userControl, ClientStatic.CreateInstance(customAttribute.Key.FieldType));
                }
                else
                {
                    customAttribute.Key.SetValue(userControl, fieldInfoValue);
                }
            }
        }

        public object SaveControlState(object userControl, Type type, Dictionary<string, object> controlState)
        {
            var customAttributes = ClientStatic.GetCustomAttributes<IisState>(type, BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Instance, false);
            foreach (var customAttribute in customAttributes)
            {
                if (customAttribute.Value == null ||
                    IisStateIsDisabled(customAttribute.Value, IisStateType.Control)) continue;
                controlState.Add(customAttribute.Key.Name, customAttribute.Key.GetValue(userControl));
            }
            return controlState;
        }

        #endregion Control State

        #region View State

        public void LoadViewState(bool enableViewState, object userControl, StateBag viewState, bool isPostBack)
        {
            if (!enableViewState) return;
            var customAttributes = ClientStatic.GetCustomAttributes<IisState>(userControl.GetType(), BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Instance, false);
            foreach (var customAttribute in customAttributes)
            {
                if (customAttribute.Value == null ||
                    IisStateIsDisabled(customAttribute.Value, IisStateType.View)) continue;
                var fieldInfoValue = viewState[customAttribute.Key.Name];
                if (!isPostBack &&
                    fieldInfoValue == null &&
                    customAttribute.Value.CreateNew)
                {
                    customAttribute.Key.SetValue(userControl, ClientStatic.CreateInstance(customAttribute.Key.FieldType));
                }
                else
                {
                    customAttribute.Key.SetValue(userControl, fieldInfoValue);
                }
            }
        }

        public void SaveViewState(bool enableViewState, object userControl, StateBag viewState)
        {
            if (!enableViewState) return;
            var customAttributes = ClientStatic.GetCustomAttributes<IisState>(userControl.GetType(), BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Instance, false);
            foreach (var customAttribute in customAttributes)
            {
                if (customAttribute.Value == null ||
                    IisStateIsDisabled(customAttribute.Value, IisStateType.View)) continue;
                viewState[customAttribute.Key.Name] = customAttribute.Key.GetValue(userControl);
            }
        }

        #endregion View State

        #region Global

        public void Start()
        {
            if (ServerConfiguration != null) return;
            ServerConfiguration = new ServerConfiguration(XmlReader.Create(AppDomain.CurrentDomain.SetupInformation.ConfigurationFile));
            Logging = new Logging(ServerConfiguration.ApplicationEventLogSource);
            Logging.Information("Service configuration loaded.");
            TypeDeclaratorManager = new TypeDeclaratorManager();
            Logging.Information("Type declarators manager loaded.");
            GenericCache = new GenericCache(ServerConfiguration.CachedEntityTypeNames);
            Logging.Information("Generic entity cache loaded.");
            SessionManager = new SessionManager(
                new CustomMessageHeader(ServerConfiguration.EmplacementCode, ServerConfiguration.ApplicationCode),
                new SessionContext
                {
                    SessionContextType = ServerConfiguration.SessionContextType,
                    UseProcessToken = ServerConfiguration.UseProcessToken,
                    InactivityTimeout = TimeSpan.Parse(ServerConfiguration.SessionInactivityTimeout),
                    ScopeTimeout = TimeSpan.Parse(ServerConfiguration.TransactionScopeTimeout),
                    LockTimeout = TimeSpan.Parse(ServerConfiguration.TransactionLockTimeout),
                    LockDelay = ServerConfiguration.TransactionLockDelay,
                    SqlCommandDelay = TimeSpan.Parse(ServerConfiguration.SqlCommandDelay),
                    OpenTokens = ServerConfiguration.OpenTokens
                },
                new HttpContextAccessor()
            );
            if (ServerConfiguration.UseProcessToken)
            {
                SessionManager.SessionUpdate(new Session
                {
                    Token = new Token
                    {
                        Code = Process.GetCurrentProcess().Id.ToString(CultureInfo.InvariantCulture)
                    }
                });
            }
            MailManager = new MailManager
            {
                MailContext = new MailContext
                {
                    Host = ServerConfiguration.SmtpHost,
                    Port = ServerConfiguration.SmtpPort,
                    UserName = ServerConfiguration.SmtpUserName,
                    Password = ServerConfiguration.SmtpPassword,
                    EnableSsl = ServerConfiguration.SmtpEnableSsl,
                    UseDefaultCredentials = ServerConfiguration.SmtpUseDefaultCredentials,
                    Timeout = ServerConfiguration.SmtpTimeout,
                    FailedTimeout = ServerConfiguration.SmtpFailedTimeout
                }
            };
        }

        public void CheckConnections()
        {
            var typeDeclarator = TypeDeclaratorManager.Get(EngineStatic.ServerConfiguration);
            foreach (var propertyDeclarator in typeDeclarator.PropertyDeclarators)
            {
                if (propertyDeclarator.ConnectionString == null ||
                    propertyDeclarator.GetValue(ServerConfiguration) == null) continue;
                try
                {
                    using (var sqlConnection = new SqlConnection((string) propertyDeclarator.GetValue(ServerConfiguration)))
                    {
                        var databaseName = sqlConnection.Database;
                        var databaseBackupPath = typeDeclarator.GetValue(sqlConnection.Database, ServerConfiguration);
                        if (databaseBackupPath != null &&
                            File.Exists((string) databaseBackupPath))
                        {
                            try
                            {
                                using (var sqlConnectionMaster = new SqlConnection(sqlConnection.ConnectionString.Replace(databaseName, Constants.MASTER_DATABASE_NAME)))
                                {
                                    var server = new Server(new ServerConnection(sqlConnectionMaster));
                                    var notExists = server.Databases[databaseName] == null;
                                    try
                                    {
                                        if (notExists)
                                        {
                                            var database = new Database(server, databaseName);
                                            database.Create();
                                            Logging.Information("Database [{0}] created.", databaseName);
                                        }
                                        if (notExists ||
                                            ServerConfiguration.ForceRestoringDatabases)
                                        {
                                            var restore = new Restore {Database = databaseName, Action = RestoreActionType.Database, ReplaceDatabase = true};
                                            var backupDeviceItem = new BackupDeviceItem((string) databaseBackupPath, DeviceType.File);
                                            restore.Devices.Add(backupDeviceItem);
                                            restore.SqlRestore(server);
                                            if (server.Databases.Contains(databaseName))
                                            {
                                                server.Databases[databaseName].SetOnline();
                                            }
                                            server.Refresh();
                                            Logging.Information("Database [{0}] restored from backup [{1}].", databaseName, (string) databaseBackupPath);
                                        }
                                    }
                                    catch (Exception exception)
                                    {
                                        Logging.Error(exception, false);
                                    }
                                }
                            }
                            catch (Exception exception)
                            {
                                Logging.Information("Cannot proceed restore pattern due account access restriction on server for creating database - see exception: {0}.", exception.Message);
                            }
                        }
                        sqlConnection.Open();
                    }
                }
                catch (Exception exception)
                {
                    Logging.Error(exception, string.Format("Cannot connect to [{0}] database - see exception.", propertyDeclarator.ConnectionString.Name));
                }
            }
        }

        public void End()
        {
            SessionManager.Save();
            Logging.Information("Unloading modules...");
            SessionManager = null;
            GenericCache = null;
            TypeDeclaratorManager = null;
            Logging = null;
            ServerConfiguration = null;
        }

        #endregion Global

        #endregion Methods

        #endregion Public Members
    }
}