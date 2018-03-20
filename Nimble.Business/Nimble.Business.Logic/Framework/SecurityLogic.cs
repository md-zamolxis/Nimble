#region Using

using System;
using System.Collections.Generic;
using System.Globalization;
using Hangfire;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Business.Library.Model.Framework.Owner;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Engine.Common;
using Nimble.DataAccess.MsSql2008.Framework;
using Nimble.Business.Engine.Core;
using Nimble.Business.Service.Core;

#endregion Using

namespace Nimble.Business.Logic.Framework
{
    public class SecurityLogic : GenericLogic
    {
        #region Private Members

        #region Properties

        private static readonly SecurityLogic instance = new SecurityLogic();

        #endregion Properties

        #endregion Private Members

        #region Public Members

        #region Properties

        internal static SecurityLogic Instance
        {
            get { return instance; }
        }

        #endregion Properties

        #region Methods

        public static SecurityLogic InstanceCheck(PermissionType permissionType)
        {
            GenericCheck(permissionType);
            return instance;
        }

        #region Emplacement

        public Emplacement EmplacementCreate(Emplacement emplacement)
        {
            EntityPropertiesCheck(
                emplacement,
                "Code");
            CultureCheck(new Culture {Id = emplacement.CultureId}, emplacement);
            return SecuritySql.Instance.EmplacementCreate(emplacement);
        }

        public Emplacement EmplacementRead(Emplacement emplacement)
        {
            EntityInstanceCheck(emplacement);
            emplacement = SecuritySql.Instance.EmplacementRead(emplacement);
            if (GenericEntity.HasValue(emplacement))
            {
                EmplacementCheck(emplacement);
            }
            return emplacement;
        }

        public Emplacement EmplacementUpdate(Emplacement emplacement)
        {
            EntityPropertiesCheck(
                emplacement,
                "Code");
            EmplacementRead(emplacement);
            CultureCheck(new Culture {Id = emplacement.CultureId}, emplacement);
            return SecuritySql.Instance.EmplacementUpdate(emplacement);
        }

        public bool EmplacementDelete(Emplacement emplacement)
        {
            EmplacementRead(emplacement);
            return SecuritySql.Instance.EmplacementDelete(emplacement);
        }

        public GenericOutput<Emplacement> EmplacementSearch(EmplacementPredicate emplacementPredicate)
        {
            return SecuritySql.Instance.EmplacementSearch(GenericInputCheck<Emplacement, EmplacementPredicate>(emplacementPredicate));
        }

        #endregion Emplacement

        #region Application

        public Application ApplicationCreate(Application application)
        {
            EntityPropertiesCheck(
                application,
                "Code");
            return SecuritySql.Instance.ApplicationCreate(application);
        }

        public Application ApplicationRead(Application application)
        {
            EntityInstanceCheck(application);
            application = SecuritySql.Instance.ApplicationRead(application);
            if (GenericEntity.HasValue(application))
            {
                ApplicationCheck(application);
            }
            return application;
        }

        public Application ApplicationUpdate(Application application)
        {
            EntityPropertiesCheck(
                application,
                "Code");
            ApplicationRead(application);
            return SecuritySql.Instance.ApplicationUpdate(application);
        }

        public bool ApplicationDelete(Application application)
        {
            ApplicationRead(application);
            return SecuritySql.Instance.ApplicationDelete(application);
        }

        public GenericOutput<Application> ApplicationSearch(ApplicationPredicate applicationPredicate)
        {
            return SecuritySql.Instance.ApplicationSearch(GenericInputCheck<Application, ApplicationPredicate>(applicationPredicate));
        }

        #endregion Application

        #region User

        public User UserCreate(User user)
        {
            EntityInstanceCheck(user);
            EntityPropertiesCheck(
                user,
                "Code",
                "Password");
            user.Emplacement = EmplacementCheck(user.Emplacement);
            user.SetDefaults();
            return SecuritySql.Instance.UserCreate(user);
        }

        public User UserRead(User user)
        {
            EntityInstanceCheck(user);
            user = SecuritySql.Instance.UserRead(user);
            if (GenericEntity.HasValue(user))
            {
                EmplacementCheck(user.Emplacement);
            }
            return user;
        }

        public User UserUpdate(User user)
        {
            EntityInstanceCheck(user);
            EntityPropertiesCheck(
                user,
                "Code",
                "Password");
            UserRead(user);
            return SecuritySql.Instance.UserUpdate(user);
        }

        public bool UserDelete(User user)
        {
            UserRead(user);
            return SecuritySql.Instance.UserDelete(user);
        }

        public GenericOutput<User> UserSearch(UserPredicate userPredicate)
        {
            return SecuritySql.Instance.UserSearch(GenericInputCheck<User, UserPredicate>(userPredicate));
        }

        public User UserChange(User user, string oldPassword, string newPassword)
        {
            user = UserRead(user);
            EntityInstanceCheck(user);
            if (string.CompareOrdinal(user.Password, EngineStatic.EncryptMd5(oldPassword)) == 0)
            {
                user.Password = newPassword;
                EntityPropertiesCheck(
                    user,
                    "Password");
                user = SecuritySql.Instance.UserUpdate(user);
            }
            else
            {
                ThrowException("Old password does not match.");
            }
            return user;
        }

        public static User UserSave(User user, EmployeeActorType employeeActorType, bool create)
        {
            EntityPropertiesCheck(
                user,
                "Code",
                "Password");
            var userEntity = SecuritySql.Instance.UserRead(user);
            if (create ||
                !GenericEntity.HasValue(userEntity))
            {
                user.SetDefaults();
                user.Emplacement = EmplacementCheck(user.Emplacement);
                user = SecuritySql.Instance.UserCreate(user);
            }
            else
            {
                EmplacementCheck(user.Emplacement);
                if (!user.Equals(userEntity) ||
                    !user.Code.Equals(userEntity.Code) ||
                    !user.Password.Equals(userEntity.Password))
                {
                    user = SecuritySql.Instance.UserUpdate(user);
                }
            }
            var roles = SecuritySql.Instance.RoleSearch(new GenericInput<Role, RolePredicate>
            {
                Predicate = new RolePredicate
                {
                    Codes = new Criteria<List<string>>(new List<string> {employeeActorType.ToString()})
                },
                Emplacement = user.Emplacement
            }).Entities;
            foreach (var role in roles)
            {
                var account = new Account
                {
                    User = user,
                    Application = role.Application,
                    Roles = new List<Role> {role}
                };
                var accountEntity = SecuritySql.Instance.AccountRead(account);
                if (GenericEntity.HasValue(accountEntity))
                {
                    accountEntity.Roles = account.Roles;
                    SecuritySql.Instance.AccountUpdate(accountEntity);
                }
                else
                {
                    SecuritySql.Instance.AccountCreate(account);
                }
            }
            return user;
        }

        #endregion User

        #region Account

        public Account AccountCreate(Account account)
        {
            account.User = SecuritySql.Instance.UserRead(account.User);
            EntityPropertiesCheck(
                account,
                "User");
            account.User.Emplacement = EmplacementCheck(account.User.Emplacement);
            account.Application = ApplicationCheck(account.Application);
            CultureCheck(new Culture {Id = account.CultureId}, account.User.Emplacement);
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType> {LockType.Account});
                account = SecuritySql.Instance.AccountCreate(account);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return account;
        }

        public Account AccountRead(Account account)
        {
            EntityInstanceCheck(account);
            account = SecuritySql.Instance.AccountRead(account);
            if (GenericEntity.HasValue(account))
            {
                EmplacementCheck(account.User.Emplacement);
                ApplicationCheck(account.Application);
            }
            return account;
        }

        public Account AccountUpdate(Account account)
        {
            AccountRead(account);
            CultureCheck(new Culture {Id = account.CultureId}, account.User.Emplacement);
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType> {LockType.Account});
                account = SecuritySql.Instance.AccountUpdate(account);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return account;
        }

        public bool AccountDelete(Account account)
        {
            AccountRead(account);
            return SecuritySql.Instance.AccountDelete(account);
        }

        public GenericOutput<Account> AccountSearch(AccountPredicate accountPredicate)
        {
            return SecuritySql.Instance.AccountSearch(GenericInputCheck<Account, AccountPredicate>(accountPredicate));
        }

        #endregion Account

        #region Permission

        public Permission PermissionCreate(Permission permission)
        {
            EntityPropertiesCheck(
                permission,
                "Code",
                "Category");
            permission.Application = ApplicationCheck(permission.Application);
            if (permission.GetPermissionType() == PermissionType.Public)
            {
                ThrowException("Cannot create public permission.");
            }
            return SecuritySql.Instance.PermissionCreate(permission);
        }

        public Permission PermissionRead(Permission permission)
        {
            EntityInstanceCheck(permission);
            permission = SecuritySql.Instance.PermissionRead(permission);
            if (GenericEntity.HasValue(permission))
            {
                ApplicationCheck(permission.Application);
            }
            return permission;
        }

        public Permission PermissionUpdate(Permission permission)
        {
            EntityPropertiesCheck(
                permission,
                "Code",
                "Category");
            PermissionRead(permission);
            if (permission.GetPermissionType() == PermissionType.Public)
            {
                ThrowException("Cannot update public permission.");
            }
            return SecuritySql.Instance.PermissionUpdate(permission);
        }

        public bool PermissionDelete(Permission permission)
        {
            PermissionRead(permission);
            return SecuritySql.Instance.PermissionDelete(permission);
        }

        public GenericOutput<Permission> PermissionSearch(PermissionPredicate permissionPredicate)
        {
            return SecuritySql.Instance.PermissionSearch(GenericInputCheck<Permission, PermissionPredicate>(permissionPredicate));
        }

        #endregion Permission

        #region Role

        public Role RoleCreate(Role role)
        {
            EntityPropertiesCheck(
                role,
                "Code");
            role.Emplacement = EmplacementCheck(role.Emplacement);
            role.Application = ApplicationCheck(role.Application);
            return SecuritySql.Instance.RoleCreate(role);
        }

        public Role RoleRead(Role role)
        {
            EntityInstanceCheck(role);
            role = SecuritySql.Instance.RoleRead(role);
            if (GenericEntity.HasValue(role))
            {
                EmplacementCheck(role.Emplacement);
                ApplicationCheck(role.Application);
            }
            return role;
        }

        public Role RoleUpdate(Role role)
        {
            EntityPropertiesCheck(
                role,
                "Code");
            RoleRead(role);
            return SecuritySql.Instance.RoleUpdate(role);
        }

        public bool RoleDelete(Role role)
        {
            RoleRead(role);
            return SecuritySql.Instance.RoleDelete(role);
        }

        public GenericOutput<Role> RoleSearch(RolePredicate rolePredicate)
        {
            return SecuritySql.Instance.RoleSearch(GenericInputCheck<Role, RolePredicate>(rolePredicate));
        }

        #endregion Role

        #region Log

        public Log LogSave(Log log)
        {
            return SecuritySql.Instance.LogCreate(log);
        }

        public Log LogCreate(Log log)
        {
            EntityInstanceCheck(log);
            var session = Kernel.Instance.SessionManager.SessionRead();
            log.Application = session.Token.Application;
            log.Account = session.Token.Account;
            log.TokenId = session.Token.Id;
            log.CreatedOn = DateTimeOffset.Now;
            if (string.IsNullOrEmpty(log.Comment))
            {
                log.Comment = string.Empty;
                var fieldCategory = GenericTranslate(log.LogActionType);
                if (!string.IsNullOrEmpty(fieldCategory.Description))
                {
                    log.Comment = log.Parameters == null ? fieldCategory.Description : string.Format(fieldCategory.Description, Array.ConvertAll(log.Parameters, converter => (object) converter));
                }
                fieldCategory = GenericTranslate(LogActionType.Undefined);
                if (!string.IsNullOrEmpty(fieldCategory.Description))
                {
                    var dateTimeOffsetNow = DateTimeOffset.Now;
                    var parameters = new object[]
                    {
                        session.Token.Emplacement.Code,
                        session.Token.Application.Code,
                        CommonLogic.Instance.IpInfoRead(session.Token.ClientHost),
                        session.Token.Account == null ? string.Empty : session.Token.Account.User.Code,
                        CommonLogic.Instance.IpInfoRead(session.Token.RequestHost),
                        session.Token.RequestPort.ToString(CultureInfo.InvariantCulture),
                        session.Token.LastUsedOn.ToString(CultureInfo.InvariantCulture),
                        dateTimeOffsetNow.ToString(CultureInfo.InvariantCulture),
                        (dateTimeOffsetNow - session.Token.LastUsedOn).ToString()
                    };
                    log.Comment = string.Format(fieldCategory.Description, parameters) + log.Comment;
                    log.InsertParameters(parameters);
                }
            }
            EntityPropertiesCheck(
                log,
                "CreatedOn",
                "Application",
                "LogActionType");
            if (Kernel.Instance.ServerConfiguration.HangfireDisabled)
            {
                log = LogSave(log);
            }
            else
            {
                BackgroundJob.Enqueue(() => LogSave(log));
            }
            return log;
        }

        public Log LogRead(Log log)
        {
            EntityInstanceCheck(log);
            log = SecuritySql.Instance.LogRead(log);
            if (GenericEntity.HasValue(log))
            {
                EmplacementCheck(log.Account.User.Emplacement);
                ApplicationCheck(log.Application);
            }
            return log;
        }

        public GenericOutput<Log> LogSearch(LogPredicate logPredicate)
        {
            return SecuritySql.Instance.LogSearch(GenericInputCheck<Log, LogPredicate>(logPredicate));
        }

        #endregion Log

        #endregion Methods

        #endregion Public Members
    }
}