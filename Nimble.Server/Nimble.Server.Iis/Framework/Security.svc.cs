#region Using

using System.ServiceModel.Activation;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Logic.Framework;
using Nimble.Server.Iis.Framework.Interface;

#endregion Using

namespace Nimble.Server.Iis.Framework
{
    [AspNetCompatibilityRequirements(RequirementsMode = AspNetCompatibilityRequirementsMode.Allowed)]
    public class Security : ISecurity
    {
        #region Emplacement

        public Emplacement EmplacementCreate(Emplacement emplacement)
        {
            return SecurityLogic.InstanceCheck(PermissionType.EmplacementCreate).EmplacementCreate(emplacement);
        }

        public Emplacement EmplacementRead(Emplacement emplacement)
        {
            return SecurityLogic.InstanceCheck(PermissionType.EmplacementRead).EmplacementRead(emplacement);
        }

        public Emplacement EmplacementUpdate(Emplacement emplacement)
        {
            return SecurityLogic.InstanceCheck(PermissionType.EmplacementUpdate).EmplacementUpdate(emplacement);
        }

        public bool EmplacementDelete(Emplacement emplacement)
        {
            return SecurityLogic.InstanceCheck(PermissionType.EmplacementDelete).EmplacementDelete(emplacement);
        }

        public GenericOutput<Emplacement> EmplacementSearch(EmplacementPredicate emplacementPredicate)
        {
            return SecurityLogic.InstanceCheck(PermissionType.EmplacementSearch).EmplacementSearch(emplacementPredicate);
        }

        #endregion Emplacement

        #region Application

        public Application ApplicationCreate(Application application)
        {
            return SecurityLogic.InstanceCheck(PermissionType.ApplicationCreate).ApplicationCreate(application);
        }

        public Application ApplicationRead(Application application)
        {
            return SecurityLogic.InstanceCheck(PermissionType.ApplicationRead).ApplicationRead(application);
        }

        public Application ApplicationUpdate(Application application)
        {
            return SecurityLogic.InstanceCheck(PermissionType.ApplicationUpdate).ApplicationUpdate(application);
        }

        public bool ApplicationDelete(Application application)
        {
            return SecurityLogic.InstanceCheck(PermissionType.ApplicationDelete).ApplicationDelete(application);
        }

        public GenericOutput<Application> ApplicationSearch(ApplicationPredicate applicationPredicate)
        {
            return SecurityLogic.InstanceCheck(PermissionType.ApplicationSearch).ApplicationSearch(applicationPredicate);
        }

        #endregion Application

        #region User

        public User UserCreate(User user)
        {
            return SecurityLogic.InstanceCheck(PermissionType.UserCreate).UserCreate(user);
        }

        public User UserRead(User user)
        {
            return SecurityLogic.InstanceCheck(PermissionType.UserRead).UserRead(user);
        }

        public User UserUpdate(User user)
        {
            return SecurityLogic.InstanceCheck(PermissionType.UserUpdate).UserUpdate(user);
        }

        public bool UserDelete(User user)
        {
            return SecurityLogic.InstanceCheck(PermissionType.UserDelete).UserDelete(user);
        }

        public GenericOutput<User> UserSearch(UserPredicate userPredicate)
        {
            return SecurityLogic.InstanceCheck(PermissionType.UserSearch).UserSearch(userPredicate);
        }

        public User UserChange(User user, string oldPassword, string newPassword)
        {
            return SecurityLogic.InstanceCheck(PermissionType.UserChange).UserChange(user, oldPassword, newPassword);
        }

        #endregion User

        #region Account

        public Account AccountCreate(Account account)
        {
            return SecurityLogic.InstanceCheck(PermissionType.AccountCreate).AccountCreate(account);
        }

        public Account AccountRead(Account account)
        {
            return SecurityLogic.InstanceCheck(PermissionType.AccountRead).AccountRead(account);
        }

        public Account AccountUpdate(Account account)
        {
            return SecurityLogic.InstanceCheck(PermissionType.AccountUpdate).AccountUpdate(account);
        }

        public bool AccountDelete(Account account)
        {
            return SecurityLogic.InstanceCheck(PermissionType.AccountDelete).AccountDelete(account);
        }

        public GenericOutput<Account> AccountSearch(AccountPredicate accountPredicate)
        {
            return SecurityLogic.InstanceCheck(PermissionType.AccountSearch).AccountSearch(accountPredicate);
        }

        #endregion Account

        #region Permission

        public Permission PermissionCreate(Permission permission)
        {
            return SecurityLogic.InstanceCheck(PermissionType.PermissionCreate).PermissionCreate(permission);
        }

        public Permission PermissionRead(Permission permission)
        {
            return SecurityLogic.InstanceCheck(PermissionType.PermissionRead).PermissionRead(permission);
        }

        public Permission PermissionUpdate(Permission permission)
        {
            return SecurityLogic.InstanceCheck(PermissionType.PermissionUpdate).PermissionUpdate(permission);
        }

        public bool PermissionDelete(Permission permission)
        {
            return SecurityLogic.InstanceCheck(PermissionType.PermissionDelete).PermissionDelete(permission);
        }

        public GenericOutput<Permission> PermissionSearch(PermissionPredicate permissionPredicate)
        {
            return SecurityLogic.InstanceCheck(PermissionType.PermissionSearch).PermissionSearch(permissionPredicate);
        }

        #endregion Permission

        #region Role

        public Role RoleCreate(Role role)
        {
            return SecurityLogic.InstanceCheck(PermissionType.RoleCreate).RoleCreate(role);
        }

        public Role RoleRead(Role role)
        {
            return SecurityLogic.InstanceCheck(PermissionType.RoleRead).RoleRead(role);
        }

        public Role RoleUpdate(Role role)
        {
            return SecurityLogic.InstanceCheck(PermissionType.RoleUpdate).RoleUpdate(role);
        }

        public bool RoleDelete(Role role)
        {
            return SecurityLogic.InstanceCheck(PermissionType.RoleDelete).RoleDelete(role);
        }

        public GenericOutput<Role> RoleSearch(RolePredicate rolePredicate)
        {
            return SecurityLogic.InstanceCheck(PermissionType.RoleSearch).RoleSearch(rolePredicate);
        }

        #endregion Role

        #region Log

        public Log LogCreate(Log log)
        {
            return SecurityLogic.InstanceCheck(PermissionType.LogCreate).LogCreate(log);
        }

        public Log LogRead(Log log)
        {
            return SecurityLogic.InstanceCheck(PermissionType.LogRead).LogRead(log);
        }

        public GenericOutput<Log> LogSearch(LogPredicate logPredicate)
        {
            return SecurityLogic.InstanceCheck(PermissionType.LogSearch).LogSearch(logPredicate);
        }

        #endregion Log
    }
}