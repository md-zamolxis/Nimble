#region Using

using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Engine.Common;
using Nimble.Business.Engine.Core;
using Nimble.Business.Service.Core;

#endregion Using

namespace Nimble.DataAccess.MsSql2008.Framework
{
    public class SecuritySql : GenericSql
    {
        #region Private Members

        #region Properties

        private static readonly SecuritySql instance = new SecuritySql(Kernel.Instance.ServerConfiguration.GenericDatabase);

        #endregion Properties

        #region Methods

        private SecuritySql(string connectionString) : base(connectionString) { }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        public static SecuritySql Instance
        {
            get { return instance; }
        }

        #endregion Properties

        #region Methods

        public SecuritySql() { }

        #region Emplacement

        public Emplacement EmplacementCreate(Emplacement emplacement)
        {
            return ProfileSave(EntityAction(PermissionType.EmplacementCreate, emplacement).Entity, emplacement);
        }

        public Emplacement EmplacementRead(Emplacement emplacement)
        {
            var emplacementEntity = Kernel.Instance.GenericCache.GetEntity(emplacement);
            if (emplacementEntity == null)
            {
                emplacementEntity = EntityAction(PermissionType.EmplacementRead, emplacement).Entity;
                ProfileRemove(emplacementEntity);
            }
            ProfileGet(emplacementEntity);
            return emplacementEntity;
        }

        public Emplacement EmplacementUpdate(Emplacement emplacement)
        {
            return ProfileSave(EntityAction(PermissionType.EmplacementUpdate, emplacement).Entity, emplacement);
        }

        public bool EmplacementDelete(Emplacement emplacement)
        {
            var deleted = EntityDelete(PermissionType.EmplacementDelete, emplacement);
            if (deleted)
            {
                ProfileDelete(emplacement);
            }
            return deleted;
        }

        public GenericOutput<Emplacement> EmplacementSearch(GenericInput<Emplacement, EmplacementPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.EmplacementSearch;
            return EntityAction(genericInput);
        }

        #endregion Emplacement

        #region Application

        public Application ApplicationCreate(Application application)
        {
            return EntityAction(PermissionType.ApplicationCreate, application).Entity;
        }

        public Application ApplicationRead(Application application)
        {
            return Kernel.Instance.GenericCache.GetEntity(application) ?? EntityAction(PermissionType.ApplicationRead, application).Entity;
        }

        public Application ApplicationUpdate(Application application)
        {
            return EntityAction(PermissionType.ApplicationUpdate, application).Entity;
        }

        public bool ApplicationDelete(Application application)
        {
            return EntityDelete(PermissionType.ApplicationDelete, application);
        }

        public GenericOutput<Application> ApplicationSearch(GenericInput<Application, ApplicationPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.ApplicationSearch;
            return EntityAction(genericInput);
        }

        #endregion Application

        #region User

        public User UserCreate(User user)
        {
            user.Password = EngineStatic.EncryptMd5(user.Password);
            return EntityAction(PermissionType.UserCreate, user).Entity;
        }

        public User UserRead(User user)
        {
            return Kernel.Instance.GenericCache.GetEntity(user) ?? EntityAction(PermissionType.UserRead, user).Entity;
        }

        public User UserUpdate(User user)
        {
            user.Password = EngineStatic.EncryptMd5(user.Password);
            return EntityAction(PermissionType.UserUpdate, user).Entity;
        }

        public bool UserDelete(User user)
        {
            return EntityDelete(PermissionType.UserDelete, user);
        }

        public GenericOutput<User> UserSearch(GenericInput<User, UserPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.UserSearch;
            return EntityAction(genericInput);
        }

        #endregion User

        #region Account

        public Account AccountCreate(Account account)
        {
            return ProfileSave(EntityAction(PermissionType.AccountCreate, account).Entity, account);
        }

        public Account AccountRead(Account account)
        {
            var accountEntity = Kernel.Instance.GenericCache.GetEntity(account);
            if (accountEntity == null)
            {
                accountEntity = EntityAction(PermissionType.AccountRead, account).Entity;
                ProfileRemove(accountEntity);
            }
            ProfileGet(accountEntity);
            return accountEntity;
        }

        public Account AccountUpdate(Account account)
        {
            return ProfileSave(EntityAction(PermissionType.AccountUpdate, account).Entity, account);
        }

        public bool AccountDelete(Account account)
        {
            var deleted = EntityDelete(PermissionType.AccountDelete, account);
            if (deleted)
            {
                ProfileDelete(account);
            }
            return deleted;
        }

        public GenericOutput<Account> AccountSearch(GenericInput<Account, AccountPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.AccountSearch;
            return EntityAction(genericInput);
        }

        #endregion Account

        #region Permission

        public Permission PermissionCreate(Permission permission)
        {
            return EntityAction(PermissionType.PermissionCreate, permission).Entity;
        }

        public Permission PermissionRead(Permission permission)
        {
            return Kernel.Instance.GenericCache.GetEntity(permission) ?? EntityAction(PermissionType.PermissionRead, permission).Entity;
        }

        public Permission PermissionUpdate(Permission permission)
        {
            return EntityAction(PermissionType.PermissionUpdate, permission).Entity;
        }

        public bool PermissionDelete(Permission permission)
        {
            return EntityDelete(PermissionType.PermissionDelete, permission);
        }

        public GenericOutput<Permission> PermissionSearch(GenericInput<Permission, PermissionPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.PermissionSearch;
            return EntityAction(genericInput);
        }

        #endregion Permission

        #region Role

        public Role RoleCreate(Role role)
        {
            return EntityAction(PermissionType.RoleCreate, role).Entity;
        }

        public Role RoleRead(Role role)
        {
            return Kernel.Instance.GenericCache.GetEntity(role) ?? EntityAction(PermissionType.RoleRead, role).Entity;
        }

        public Role RoleUpdate(Role role)
        {
            return EntityAction(PermissionType.RoleUpdate, role).Entity;
        }

        public bool RoleDelete(Role role)
        {
            return EntityDelete(PermissionType.RoleDelete, role);
        }

        public GenericOutput<Role> RoleSearch(GenericInput<Role, RolePredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.RoleSearch;
            return EntityAction(genericInput);
        }

        #endregion Role

        #region Log

        public Log LogCreate(Log log)
        {
            return EntityAction(PermissionType.LogCreate, log).Entity;
        }

        public Log LogRead(Log log)
        {
            return EntityAction(PermissionType.LogRead, log).Entity;
        }

        public GenericOutput<Log> LogSearch(GenericInput<Log, LogPredicate> genericInput)
        {
            genericInput.PermissionType = PermissionType.LogSearch;
            return EntityAction(genericInput);
        }

        #endregion Log

        #endregion Methods

        #endregion Public Members
    }
}
