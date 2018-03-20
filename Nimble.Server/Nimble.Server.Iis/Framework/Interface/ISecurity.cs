#region Using

using System.ServiceModel;
using System.ServiceModel.Web;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model.Framework.Security;

#endregion Using

namespace Nimble.Server.Iis.Framework.Interface
{
    [ServiceContract]
    public interface ISecurity
    {
        #region Emplacement

        [OperationContract]
        Emplacement EmplacementCreate(Emplacement emplacement);

        [OperationContract]
        Emplacement EmplacementRead(Emplacement emplacement);

        [OperationContract]
        Emplacement EmplacementUpdate(Emplacement emplacement);

        [OperationContract]
        bool EmplacementDelete(Emplacement emplacement);

        [OperationContract]
        GenericOutput<Emplacement> EmplacementSearch(EmplacementPredicate emplacementPredicate);

        #endregion Emplacement

        #region Application

        [OperationContract]
        Application ApplicationCreate(Application application);

        [OperationContract]
        Application ApplicationRead(Application application);

        [OperationContract]
        Application ApplicationUpdate(Application application);

        [OperationContract]
        bool ApplicationDelete(Application application);

        [OperationContract]
        GenericOutput<Application> ApplicationSearch(ApplicationPredicate applicationPredicate);

        #endregion Application

        #region User

        [OperationContract]
        [WebInvoke(Method = "POST", BodyStyle = WebMessageBodyStyle.WrappedRequest, ResponseFormat = WebMessageFormat.Json, RequestFormat = WebMessageFormat.Json)]
        User UserCreate(User user);

        [OperationContract]
        [WebInvoke(Method = "POST", BodyStyle = WebMessageBodyStyle.WrappedRequest, ResponseFormat = WebMessageFormat.Json, RequestFormat = WebMessageFormat.Json)]
        User UserRead(User user);

        [OperationContract]
        [WebInvoke(Method = "POST", BodyStyle = WebMessageBodyStyle.WrappedRequest, ResponseFormat = WebMessageFormat.Json, RequestFormat = WebMessageFormat.Json)]
        User UserUpdate(User user);

        [OperationContract]
        [WebInvoke(Method = "POST", BodyStyle = WebMessageBodyStyle.WrappedRequest, ResponseFormat = WebMessageFormat.Json, RequestFormat = WebMessageFormat.Json)]
        bool UserDelete(User user);

        [OperationContract]
        [WebInvoke(Method = "POST", BodyStyle = WebMessageBodyStyle.WrappedRequest, ResponseFormat = WebMessageFormat.Json, RequestFormat = WebMessageFormat.Json)]
        GenericOutput<User> UserSearch(UserPredicate userPredicate);

        [OperationContract]
        [WebInvoke(Method = "POST", BodyStyle = WebMessageBodyStyle.WrappedRequest, ResponseFormat = WebMessageFormat.Json, RequestFormat = WebMessageFormat.Json)]
        User UserChange(User user, string oldPassword, string newPassword);

        #endregion User

        #region Account

        [OperationContract]
        Account AccountCreate(Account account);

        [OperationContract]
        Account AccountRead(Account account);

        [OperationContract]
        Account AccountUpdate(Account account);

        [OperationContract]
        bool AccountDelete(Account account);

        [OperationContract]
        GenericOutput<Account> AccountSearch(AccountPredicate accountPredicate);

        #endregion Account

        #region Role

        #region Permission

        [OperationContract]
        Permission PermissionCreate(Permission permission);

        [OperationContract]
        Permission PermissionRead(Permission permission);

        [OperationContract]
        Permission PermissionUpdate(Permission permission);

        [OperationContract]
        bool PermissionDelete(Permission permission);

        [OperationContract]
        GenericOutput<Permission> PermissionSearch(PermissionPredicate permissionPredicate);

        #endregion Permission

        [OperationContract]
        Role RoleCreate(Role role);

        [OperationContract]
        Role RoleRead(Role role);

        [OperationContract]
        Role RoleUpdate(Role role);

        [OperationContract]
        bool RoleDelete(Role role);

        [OperationContract]
        GenericOutput<Role> RoleSearch(RolePredicate rolePredicate);

        #endregion Role

        #region Log

        [OperationContract]
        Log LogCreate(Log log);

        [OperationContract]
        Log LogRead(Log log);

        [OperationContract]
        GenericOutput<Log> LogSearch(LogPredicate logPredicate);

        #endregion Log
    }
}