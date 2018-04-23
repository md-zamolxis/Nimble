#region Using

using System;
using System.Collections.Generic;
using System.IO;
using System.ServiceModel;
using System.Xml.Schema;
using Nimble.Business.Engine.Common;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Geolocation;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Business.Library.Model.Framework.Owner;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Logic.Framework;
using Nimble.DataAccess.MsSql2008.Framework;
using Nimble.Business.Engine.Core;
using Nimble.Business.Service.Core;

#endregion Using

namespace Nimble.Business.Logic
{
    public abstract class GenericLogic
    {
        #region Protected Members

        #region Properties

        protected Logging Logging { get; set; }
        protected bool DisableLoggingError { get; set; }
        protected bool DisableLoggingInformation { get; set; }
        protected bool DisableLoggingWarning { get; set; }
        protected string XmlValidationMessage { get; set; }

        #endregion Properties

        #region Methods

        protected void XmlValidationEventHandler(object sender, ValidationEventArgs e)
        {
            XmlValidationMessage = e.Message;
        }

        protected static string FilePath(string filename, string extension)
        {
            var filePath = string.Empty;
            if (!string.IsNullOrEmpty(Kernel.Instance.ServerConfiguration.TemporaryDataFolder))
            {
                try
                {
                    filePath = string.Format(
                        Constants.TEMPORARY_DATA_FILE_PATH,
                        Kernel.Instance.ServerConfiguration.TemporaryDataFolder,
                        filename,
                        extension);
                    if (File.Exists(filePath))
                    {
                        File.Delete(filePath);
                    }
                }
                catch (Exception exception)
                {
                    Kernel.Instance.Logging.Error(exception, false);
                }
            }
            return filePath;
        }

        protected static string FilePath(Guid? reference, string extension)
        {
            return FilePath(reference.HasValue ? reference.ToString() : string.Empty, extension);
        }

        protected static FileStream FileSave(string filePath, byte[] data)
        {
            FileStream fileStream = null;
            try
            {
                fileStream = File.Create(filePath, data.Length);
                fileStream.Write(data, 0, data.Length);
                fileStream.Flush();
                fileStream.Close();
            }
            catch (Exception exception)
            {
                Kernel.Instance.Logging.Error(exception, false);
            }
            return fileStream;
        }

        protected static FileStream FileSave(string filePath, Stream stream)
        {
            FileStream fileStream = null;
            if (stream != null &&
                stream.Length > 0)
            {
                var data = new byte[stream.Length];
                stream.Read(data, 0, (int) stream.Length);
                fileStream = FileSave(filePath, data);
            }
            return fileStream;
        }

        protected static void TransactionBegin(string[] connectionStrings)
        {
            TransactionBegin(connectionStrings, null);
        }

        protected static void TransactionBegin(string[] connectionStrings, List<LockType> lockTypes)
        {
            var session = Kernel.Instance.SessionManager.SessionRead();
            if (!Kernel.Instance.SessionManager.LockCreate(session, connectionStrings, lockTypes))
            {
                ThrowException("Cannot perform this action, because is blocked by other session or the open transaction of the same session. Try again and if problem persists, contacts you system administrator.");
            }
        }

        protected static void TransactionRollback()
        {
            var session = Kernel.Instance.SessionManager.SessionRead();
            Kernel.Instance.SessionManager.LockDelete(session, false);
        }

        protected static void TransactionRollback(Exception exception, bool logFaultException = false)
        {
            TransactionRollback();
            if (exception is FaultException)
            {
                if (logFaultException)
                {
                    Kernel.Instance.Logging.Error(exception, false);
                }
                var faultExceptionDetail = FaultExceptionDetail.Create(exception);
                GenericTranslate(faultExceptionDetail);
                throw FaultExceptionDetail.Create(faultExceptionDetail);
            }
            Kernel.Instance.Logging.Error(exception, false);
            ThrowException(Constants.BUSINESS_RULE_UNHANDLED_ERROR);
        }

        protected static void TransactionComplete()
        {
            var session = Kernel.Instance.SessionManager.SessionRead();
            Kernel.Instance.SessionManager.LockDelete(session, true);
        }

        protected static T EntityInstanceCheck<T>(T entity) where T : class
        {
            var entityName = Kernel.Instance.TypeDeclaratorManager.InstanceCheck(entity);
            if (!string.IsNullOrEmpty(entityName))
            {
                ThrowException(Constants.OBJECT_NULL_INSTANCE, entityName);
            }
            return entity;
        }

        protected static void EntityInstancesCheck(params object[] entities)
        {
            var entityName = Kernel.Instance.TypeDeclaratorManager.InstancesCheck(entities);
            if (!string.IsNullOrEmpty(entityName))
            {
                ThrowException(Constants.OBJECT_NULL_INSTANCE, entityName);
            }
        }

        protected static T EntityPropertiesCheck<T>(T entity, params string[] propertyNames) where T : class
        {
            var undefinedProperties = Kernel.Instance.TypeDeclaratorManager.GetUndefinedProperties(entity, propertyNames);
            if (undefinedProperties.Count > 0)
            {
                var faultExceptionDetail = new FaultExceptionDetail("{0} cannot pass validation rules.", Kernel.Instance.TypeDeclaratorManager.Get(typeof(T)).GetDisplayName());
                foreach (var undefinedProperty in undefinedProperties)
                {
                    var item = new FaultExceptionDetail("[{0}] property not defined.", undefinedProperty);
                    GenericTranslate(item, ResourceCategoryType.BusinessLogic);
                    item.PropertyName = undefinedProperty;
                    faultExceptionDetail.Items.Add(item);
                }
                ThrowException(faultExceptionDetail);
            }
            return entity;
        }

        protected static string EntityPropertiesDifference<T>(T left, T right, params string[] propertyNames) where T : GenericEntity, new()
        {
            var difference = string.Empty;
            var unequalProperties = Kernel.Instance.TypeDeclaratorManager.GetUnequalProperties(left, right, true, propertyNames);
            foreach (var unequalProperty in unequalProperties)
            {
                var leftValue = string.Empty;
                if (unequalProperty.Value.Item1 != null)
                {
                    leftValue = EngineStatic.JsonSerialize(unequalProperty.Value.Item1);
                }
                var rightValue = string.Empty;
                if (unequalProperty.Value.Item2 != null)
                {
                    rightValue = EngineStatic.JsonSerialize(unequalProperty.Value.Item2);
                }
                difference += string.Format("{0}: {1} <> {2}\n", unequalProperty.Key, leftValue, rightValue);
            }
            return difference;
        }

        protected static void EntityValidate(FaultExceptionDetail faultExceptionDetail, string name)
        {
            if (faultExceptionDetail == null) return;
            faultExceptionDetail.Items.RemoveAll(item => string.IsNullOrEmpty(item.Code));
            if (faultExceptionDetail.Items.Count == 0) return;
            foreach (var item in faultExceptionDetail.Items)
            {
                GenericTranslate(item, ResourceCategoryType.BusinessLogic);
            }
            faultExceptionDetail.Code = "{0} cannot pass validation rules.";
            faultExceptionDetail.Parameters = new object[]
            {
                name
            };
            ThrowException(faultExceptionDetail);
        }

        protected static void EntityValidate<T>(T entity) where T : GenericEntity
        {
            EntityInstanceCheck(entity);
            EntityValidate(entity.Validate(), Kernel.Instance.TypeDeclaratorManager.Get(entity.GetType()).GetDisplayName());
        }

        protected static object GetCommonPropertyValue(CommonPropertyType commonPropertyType, params object[] entities)
        {
            object propertyValue = null;
            foreach (var entity in entities)
            {
                if (entity == null) continue;
                var typeDeclarator = Kernel.Instance.TypeDeclaratorManager.Get(entity.GetType());
                foreach (var propertyDeclarator in typeDeclarator.PropertyDeclarators)
                {
                    if (propertyDeclarator.ProfileProperty == null ||
                        propertyDeclarator.ProfileProperty.CommonPropertyType != commonPropertyType) continue;
                    propertyValue = propertyDeclarator.GetValue(entity);
                    break;
                }
                if (propertyValue != null) break;
            }
            return propertyValue;
        }

        protected static Token SetToken(Token token, CommonPropertyType[] commonPropertyTypes, bool reload)
        {
            foreach (var commonPropertyType in commonPropertyTypes)
            {
                switch (commonPropertyType)
                {
                    case CommonPropertyType.Culture:
                    {
                        if (reload ||
                            token.Culture == null)
                        {
                            var cultureId = GetCommonPropertyValue(CommonPropertyType.Culture, token.Account, token.Emplacement);
                            if (cultureId != null)
                            {
                                token.Culture = MultilanguageSql.Instance.CultureRead(new Culture {Id = (Guid) cultureId});
                            }
                        }
                        break;
                    }
                }
            }
            return token;
        }

        protected static Session SessionSave(bool isAuthorized)
        {
            var emplacement = SecuritySql.Instance.EmplacementRead(new Emplacement {Code = Kernel.Instance.SessionManager.EmplacementCode()});
            if (emplacement == null)
            {
                throw FaultExceptionDetail.Create(new FaultExceptionDetail(Constants.SECURITY_VIOLATION_ENTITY_INVALID, "emplacement"));
            }
            var application = SecuritySql.Instance.ApplicationRead(new Application {Code = Kernel.Instance.SessionManager.ApplicationCode()});
            if (application == null)
            {
                throw FaultExceptionDetail.Create(new FaultExceptionDetail(Constants.SECURITY_VIOLATION_ENTITY_INVALID, "application"));
            }
            var session = Kernel.Instance.SessionManager.SessionRead();
            if (session == null ||
                string.IsNullOrEmpty(session.Token.Code) ||
                isAuthorized)
            {
                session = Kernel.Instance.SessionManager.SessionCreate(isAuthorized);
                session = Kernel.Instance.SessionManager.SessionUpdate(session);
                SetToken(session.Token, ClientStatic.GetEnumValues<CommonPropertyType>().ToArray(), false);
            }
            session.Token.Emplacement = emplacement;
            session.Token.Application = application;
            var cultureCode = Kernel.Instance.SessionManager.KeyValue(Kernel.Instance.SessionManager.CustomMessageHeader.CultureCode);
            if (!string.IsNullOrEmpty(cultureCode))
            {
                session.Token.Culture = MultilanguageSql.Instance.CultureRead(new Culture
                {
                    Emplacement = emplacement,
                    Code = cultureCode
                });
            }
            return session;
        }

        protected static bool PermissionsCheck(Account account, PermissionType[] permissionTypes, Token token)
        {
            var hasPermissions = true;
            EntityInstanceCheck(account);
            Dictionary<string, Permission> permissions;
            if (token != null &&
                token.Permissions != null)
            {
                permissions = token.Permissions;
            }
            else
            {
                var enumEntityPairs = Kernel.Instance.TypeDeclaratorManager.GetEnumEntityPairs<PermissionType, Permission>(SecuritySql.Instance.PermissionSearch(new GenericInput<Permission, PermissionPredicate>
                {
                    Predicate = new PermissionPredicate
                    {
                        AccountPredicate = new AccountPredicate
                        {
                            Accounts = new Criteria<List<Account>>(new List<Account>
                            {
                                account
                            })
                        }
                    }
                }).Entities);
                permissions = new Dictionary<string, Permission>();
                foreach (var enumEntityPair in enumEntityPairs)
                {
                    permissions.Add(enumEntityPair.Key.ToString(), enumEntityPair.Value);
                }
                if (token != null)
                {
                    token.Permissions = permissions;
                }
            }
            if (permissionTypes != null)
            {
                foreach (var permissionType in permissionTypes)
                {
                    if (permissions.ContainsKey(permissionType.ToString())) continue;
                    hasPermissions = false;
                    break;
                }
            }
            return hasPermissions;
        }

        protected static void GenericCheck(PermissionType permissionType)
        {
            var session = SessionSave(false);
            if (session == null)
            {
                ThrowException(Constants.SECURITY_VIOLATION_ENTITY_INVALID, "session");
            }
            else
            {
                if (session.Token.Account != null)
                {
                    if (!session.Token.Account.User.Emplacement.Equals(session.Token.Emplacement))
                    {
                        ThrowException(Constants.SECURITY_VIOLATION_ENTITY_DIFFERENT, "Token", "emplacements");
                    }
                    if (!session.Token.Account.Application.Equals(session.Token.Application))
                    {
                        ThrowException(Constants.SECURITY_VIOLATION_ENTITY_DIFFERENT, "Token", "applications");
                    }
                }
                session.Token.PermissionType = permissionType;
                session.Token.PermissionDescription = GenericTranslate(permissionType).Description;
                if (permissionType == PermissionType.Public) return;
                if (session.Token.Account == null)
                {
                    ThrowException(new FaultExceptionDetail(FaultExceptionDetailType.Unauthorised));
                }
                else if (!PermissionsCheck(session.Token.Account, new[] {permissionType}, session.Token))
                {
                    ThrowException("User [{0}] do not has permission [{1}] on application [{2}].", session.Token.Account.User.Code, permissionType, session.Token.Account.Application.Code);
                }
            }
        }

        protected static void GenericCheck(string emplacementCode, string applicationCode, PermissionType permissionType, string userCode, string userPassword)
        {
            Kernel.Instance.SessionManager.SessionContextSet(emplacementCode, applicationCode);
            if (permissionType != PermissionType.Public)
            {
                CommonLogic.InstanceCheck(PermissionType.Public).Login(userCode, userPassword);
            }
            GenericCheck(permissionType);
        }

        protected static GenericInput<T, P> GenericInputCheck<T, P>(P predicate) where T : GenericEntity where P : GenericPredicate
        {
            EntityInstanceCheck(predicate);
            var session = Kernel.Instance.SessionManager.SessionRead();
            var genericInput = new GenericInput<T, P>
            {
                Predicate = predicate
            };
            if (!session.Token.Emplacement.IsAdministrative)
            {
                genericInput.Emplacement = session.Token.Emplacement.Clone<Emplacement>();
            }
            if (!session.Token.Application.IsAdministrative)
            {
                genericInput.Application = session.Token.Application.Clone<Application>();
            }
            if (session.Token.Person != null)
            {
                genericInput.Person = session.Token.Person.Clone<Person>();
            }
            if (!TokenIsMaster(session.Token))
            {
                genericInput.Organisations = new List<Organisation>();
                foreach (var organisation in EmployeeOrganisations(session.Token))
                {
                    genericInput.Organisations.Add(organisation.Clone<Organisation>());
                }
                if (session.Token.EmployeeBranches != null &&
                    session.Token.EmployeeBranches.Count > 0)
                {
                    genericInput.Branches = new List<Branch>();
                    foreach (var branch in session.Token.EmployeeBranches)
                    {
                        genericInput.Branches.Add(branch.Clone<Branch>());
                    }
                }
            }
            return genericInput;
        }

        protected static Emplacement EmplacementCheck(Emplacement emplacement, bool checkInstance = true, bool denyAccess = true, bool nullInstance = false)
        {
            if (!GenericEntity.HasValue(emplacement))
            {
                emplacement = SecuritySql.Instance.EmplacementRead(emplacement);
            }
            if (checkInstance)
            {
                EntityInstanceCheck(emplacement);
            }
            var session = Kernel.Instance.SessionManager.SessionRead();
            if (!TokenIsMaster(session.Token) &&
                !session.Token.Emplacement.IsAdministrative &&
                !session.Token.Emplacement.Equals(emplacement))
            {
                if (denyAccess)
                {
                    ThrowException(Constants.ENTITY_ACCESS_DENIED, "emplacement", session.Token.Emplacement.Code);
                }
                if (nullInstance)
                {
                    emplacement = null;
                }
            }
            return emplacement;
        }

        protected static Application ApplicationCheck(Application application, bool checkInstance = true, bool denyAccess = true, bool nullInstance = false)
        {
            if (!GenericEntity.HasValue(application))
            {
                application = SecuritySql.Instance.ApplicationRead(application);
            }
            if (checkInstance)
            {
                EntityInstanceCheck(application);
            }
            var session = Kernel.Instance.SessionManager.SessionRead();
            if (!TokenIsMaster(session.Token) &&
                !session.Token.Application.IsAdministrative &&
                !session.Token.Application.Equals(application))
            {
                if (denyAccess)
                {
                    ThrowException(Constants.ENTITY_ACCESS_DENIED, "application", session.Token.Application.Code);
                }
                if (nullInstance)
                {
                    application = null;
                }
            }
            return application;
        }

        protected static void CultureCheck(Culture culture, Emplacement emplacement)
        {
            if (!GenericEntity.HasValue(culture) ||
                !GenericEntity.HasValue(culture.Emplacement))
            {
                culture = MultilanguageSql.Instance.CultureRead(culture);
            }
            if (!GenericEntity.HasValue(emplacement))
            {
                emplacement = SecuritySql.Instance.EmplacementRead(emplacement);
            }
            if (GenericEntity.HasValue(culture) &&
                GenericEntity.HasValue(culture.Emplacement) &&
                !culture.Emplacement.Equals(emplacement))
            {
                ThrowException(Constants.SECURITY_VIOLATION_ENTITY_DIFFERENT, "Culture", "emplacements");
            }
        }

        protected static bool TokenIsMaster(Token token)
        {
            return token.IsMaster();
        }

        protected static bool TokenIsMaster()
        {
            return TokenIsMaster(Kernel.Instance.SessionManager.SessionRead().Token);
        }

        protected static List<Organisation> EmployeeOrganisations(Token token)
        {
            if (token.EmployeeOrganisations == null)
            {
                token.EmployeeOrganisations = new List<Organisation>();
                if (token.Employees != null)
                {
                    foreach (var employee in token.Employees)
                    {
                        var organisation = employee.Organisation;
                        if (token.EmployeeOrganisations.Exists(item => item.Equals(organisation))) continue;
                        token.EmployeeOrganisations.Add(organisation);
                    }
                }
            }
            return token.EmployeeOrganisations;
        }

        protected static Person PersonCheck(Person person, bool checkInstance = true, bool checkNull = true, bool checkEmplacement = true, bool denyAccess = true, bool nullInstance = false)
        {
            if (!GenericEntity.HasValue(person))
            {
                person = OwnerSql.Instance.PersonRead(person);
            }
            if (checkInstance)
            {
                EntityInstanceCheck(person);
            }
            var session = Kernel.Instance.SessionManager.SessionRead();
            if (!TokenIsMaster(session.Token))
            {
                if (GenericEntity.HasValue(person) ||
                    checkNull)
                {
                    if (session.Token.Person.Equals(person))
                    {
                        if (checkEmplacement)
                        {
                            EmplacementCheck(person.Emplacement);
                        }
                    }
                    else
                    {
                        if (denyAccess)
                        {
                            ThrowException(Constants.ENTITY_ACCESS_DENIED, "person", session.Token.Person.ToString());
                        }
                        if (nullInstance)
                        {
                            person = null;
                        }
                    }
                }
            }
            return person;
        }

        protected static Person PersonCheck(Person person, Organisation organisation)
        {
            person = PersonCheck(person, false, false, false, false, true);
            if (!GenericEntity.HasValue(person))
            {
                OrganisationCheck(organisation);
            }
            return person;
        }

        protected static Organisation OrganisationCheck(Organisation organisation, List<EmployeeActorType> employeeActorTypes, bool checkInstance = true, bool checkEmplacement = true, bool denyAccess = true, bool nullInstance = false)
        {
            if (!GenericEntity.HasValue(organisation))
            {
                organisation = OwnerSql.Instance.OrganisationRead(organisation);
            }
            if (checkInstance)
            {
                EntityInstanceCheck(organisation);
            }
            var session = Kernel.Instance.SessionManager.SessionRead();
            var tokenOrganisations = EmployeeOrganisations(session.Token);
            if (!TokenIsMaster(session.Token))
            {
                var exists = false;
                if (employeeActorTypes == null ||
                    employeeActorTypes.Count == 0)
                {
                    exists = tokenOrganisations.Exists(item => item.Equals(organisation));
                }
                else if (session.Token.Employees != null)
                {
                    foreach (var employee in session.Token.Employees)
                    {
                        var employeeActorType = employee.EmployeeActorType;
                        if (!organisation.Equals(employee.Organisation) ||
                            !employeeActorTypes.Exists(item => item.Equals(employeeActorType))) continue;
                        exists = true;
                        break;
                    }
                }
                if (exists)
                {
                    if (organisation.LockedOn.HasValue &&
                        organisation.LockedOn.Value < session.Token.LastUsedOn)
                    {
                        ThrowException("Organisation [{0}] has been locked on [{1}] by reason [{2}].", organisation.IDNO, organisation.LockedOn, organisation.LockedReason);
                    }
                    if (checkEmplacement)
                    {
                        EmplacementCheck(organisation.Emplacement);
                    }
                }
                else
                {
                    if (denyAccess)
                    {
                        ThrowException("Person [{0}] is not employed at organisation [{1}] or have no rights to perform this operation.", session.Token.Person.ToString(), organisation.Name);
                    }
                    if (nullInstance)
                    {
                        organisation = null;
                    }
                }
            }
            return organisation;
        }

        protected static Branch BranchCheck(Branch branch, bool checkInstance = true, bool checkNull = true, bool checkOrganisation = true, bool denyAccess = true, bool nullInstance = false)
        {
            if (!GenericEntity.HasValue(branch))
            {
                branch = OwnerSql.Instance.BranchRead(branch);
            }
            if (checkInstance)
            {
                EntityInstanceCheck(branch);
            }
            var session = Kernel.Instance.SessionManager.SessionRead();
            if (!TokenIsMaster(session.Token))
            {
                if (GenericEntity.HasValue(branch) ||
                    checkNull)
                {
                    var exists = true;
                    if (session.Token.EmployeeBranches != null &&
                        session.Token.EmployeeBranches.Count > 0)
                    {
                        exists = session.Token.EmployeeBranches.Exists(item => item.Equals(branch));
                    }
                    if (exists)
                    {
                        if (checkOrganisation)
                        {
                            OrganisationCheck(branch.Organisation);
                        }
                    }
                    else
                    {
                        if (denyAccess)
                        {
                            ThrowException("Person {0} is not attached as employee to branch {1}.", session.Token.Person.ToString(), branch.Name);
                        }
                        if (nullInstance)
                        {
                            branch = null;
                        }
                    }
                }
            }
            return branch;
        }

        protected static Organisation OrganisationCheck(Organisation organisation)
        {
            return OrganisationCheck(organisation, null);
        }

        protected static Employee EmployeeCheck(Token token)
        {
            var employee = token.Employee;
            if (!TokenIsMaster(token))
            {
                if (token.Employees == null ||
                    token.Employees.Count == 0)
                {
                    ThrowException("No employees available.");
                }
                else if (token.Employees.Count == 1)
                {
                    employee = token.Employees[0];
                }
                else if (employee == null)
                {
                    ThrowException("No current employee selected.");
                }
            }
            return employee;
        }

        protected static Employee EmployeeCheck()
        {
            return EmployeeCheck(Kernel.Instance.SessionManager.SessionRead().Token);
        }

        protected static Translation GenericTranslation(Resource resource)
        {
            var session = Kernel.Instance.SessionManager.SessionRead();
            resource.Emplacement = session.Token.Emplacement;
            resource.Application = session.Token.Application;
            resource.Category = resource.Category ?? string.Empty;
            return GenericTranslation(session.Token.Culture, resource);
        }

        protected static Translation GenericTranslation(Culture culture, Resource resource)
        {
            Translation translation = null;
            if (resource != null &&
                Kernel.Instance.ServerConfiguration.UseTranslationModule)
            {
                resource = MultilanguageSql.Instance.ResourceRead(resource);
                if (culture != null)
                {
                    translation = new Translation
                    {
                        Culture = culture,
                        Resource = resource
                    };
                    var translationEntity = Kernel.Instance.ServerConfiguration.MultilanguageCacheOnLoad ? Kernel.Instance.GenericCache.GetEntity(translation) : MultilanguageSql.Instance.TranslationRead(translation);
                    if (GenericEntity.HasValue(translationEntity))
                    {
                        translation = translationEntity;
                    }
                }
            }
            return translation;
        }

        protected static Tuple<string, bool> GenericTranslate(string code, string category, params object[] parameters)
        {
            var value = code;
            var state = false;
            var translation = GenericTranslation(new Resource
            {
                Code = value,
                Category = category
            });
            if (translation != null)
            {
                value = GenericEntity.HasValue(translation) ? translation.Sense : value;
                state = GenericEntity.HasValue(translation.Resource);
            }
            if (parameters != null &&
                parameters.Length > 0)
            {
                value = string.Format(value, parameters);
            }
            return new Tuple<string, bool>(value, state);
        }

        protected static string GenericTranslate(string code, params object[] parameters)
        {
            return GenericTranslate(code, string.Empty, parameters).Item1;
        }

        protected static string GenericTranslate(string code, ResourceCategoryType resourceCategoryType, params object[] parameters)
        {
            return GenericTranslate(code, resourceCategoryType.ToString(), parameters).Item1;
        }

        protected static FieldCategory GenericTranslate<E>(E enumItem)
        {
            var name = enumItem.ToString();
            var description = string.Empty;
            var type = typeof(E);
            if (type.IsEnum)
            {
                var customAttribute = ClientStatic.GetCustomAttribute<FieldCategory>(type.GetField(name), true);
                if (customAttribute != null)
                {
                    name = customAttribute.Name;
                    description = customAttribute.Description;
                    if (!string.IsNullOrEmpty(customAttribute.Name) &&
                        customAttribute.Name.Length <= Constants.STRING_CODE_MAX_LENGTH)
                    {
                        name = GenericTranslate(customAttribute.Name, ResourceCategoryType.Enumerators);
                    }
                    if (!string.IsNullOrEmpty(customAttribute.Description) &&
                        customAttribute.Description.Length <= Constants.STRING_CODE_MAX_LENGTH)
                    {
                        description = GenericTranslate(customAttribute.Description, ResourceCategoryType.Enumerators);
                    }
                }
            }
            return new FieldCategory
            {
                Name = name,
                Description = description
            };
        }

        protected static void GenericTranslate(FaultExceptionDetail faultExceptionDetail, ResourceCategoryType resourceCategoryType)
        {
            var translate = GenericTranslate(faultExceptionDetail.Code, resourceCategoryType.ToString(), faultExceptionDetail.Parameters);
            faultExceptionDetail.Message = translate.Item1;
            faultExceptionDetail.Translated = translate.Item2;
        }

        protected static bool GenericTranslate(FaultExceptionDetail faultExceptionDetail)
        {
            var isHandled = false;
            if (faultExceptionDetail != null &&
                !string.IsNullOrEmpty(faultExceptionDetail.Code) &&
                !faultExceptionDetail.Translated)
            {
                isHandled = true;
                if (faultExceptionDetail.Untranslatable)
                {
                    faultExceptionDetail.Message = faultExceptionDetail.Code;
                }
                else
                {
                    GenericTranslate(faultExceptionDetail, ResourceCategoryType.BusinessLogic);
                }
            }
            return isHandled;
        }

        protected static void ThrowException(FaultExceptionDetail faultExceptionDetail)
        {
            GenericTranslate(faultExceptionDetail);
            throw FaultExceptionDetail.Create(faultExceptionDetail);
        }

        protected static void ThrowException(string code, params object[] parameters)
        {
            ThrowException(new FaultExceptionDetail(code, parameters));
        }

        protected static Tuple<FaultExceptionDetail, Branch> BranchCheck(Branch branch, DateTimeOffset dateTimeOffset, BranchActionType? branchActionType)
        {
            var faultExceptionDetail = new FaultExceptionDetail();
            branch = OwnerSql.Instance.BranchRead(branch);
            if (!GenericEntity.HasValue(branch))
            {
                faultExceptionDetail.Code = "Branch not found.";
            }
            else
            {
                branch = BranchCheck(branch);
                if (branch.LockedOn.HasValue &&
                    branch.LockedOn < dateTimeOffset)
                {
                    faultExceptionDetail.Code = "Branch [{0}] has been locked on [{1}].";
                    faultExceptionDetail.Parameters = new object[]
                    {
                        branch.Code,
                        branch.LockedOn
                    };
                }
                else if (branchActionType.HasValue &&
                         !branch.BranchActionType.HasValue(branchActionType.Value))
                {
                    faultExceptionDetail.Code = "Branch [{0}] has no [{1}] function.";
                    faultExceptionDetail.Parameters = new object[]
                    {
                        branch.Code,
                        branchActionType.ToString()
                    };
                }
            }
            GenericTranslate(faultExceptionDetail);
            return new Tuple<FaultExceptionDetail, Branch>(faultExceptionDetail, branch);
        }

        protected static FaultExceptionDetail RangeCheck(Branch branch, DateTimeOffset dateTimeOffset)
        {
            var faultExceptionDetail = new FaultExceptionDetail();
            var ranges = OwnerSql.Instance.RangeSearch(new GenericInput<Range, RangePredicate>
            {
                Predicate = new RangePredicate
                {
                    BranchPredicate = new BranchPredicate
                    {
                        Branches = new Criteria<List<Branch>>(new List<Branch> {branch})
                    }
                }
            }).Entities;
            var session = Kernel.Instance.SessionManager.SessionRead();
            var ipNumber = Block.GetIpNumber(session.Token.RequestHost);
            if (ranges.Count > 0 &&
                ipNumber.HasValue &&
                ipNumber.Value > 0)
            {
                var range = ranges.Find(item => ipNumber >= item.IpNumberFrom && ipNumber <= item.IpNumberTo);
                if (!GenericEntity.HasValue(range))
                {
                    faultExceptionDetail.Code = "Branch [{0}] has no assigned range of IP address, valid for request from [{1}].";
                    faultExceptionDetail.Parameters = new object[]
                    {
                        branch.Code,
                        session.Token.RequestHost
                    };
                }
                else if (range.LockedOn.HasValue &&
                         range.LockedOn < dateTimeOffset)
                {
                    faultExceptionDetail.Code = "Range [{0}] has been locked on [{1}].";
                    faultExceptionDetail.Parameters = new object[]
                    {
                        range.Code,
                        range.LockedOn
                    };
                }
            }
            GenericTranslate(faultExceptionDetail);
            return faultExceptionDetail;
        }

        protected static Tuple<FaultExceptionDetail, Employee> EmployeeCheck(Organisation organisation, Employee employee, DateTimeOffset dateTimeOffset)
        {
            var faultExceptionDetail = new FaultExceptionDetail();
            var state = Kernel.Instance.StateGenerate(dateTimeOffset, true);
            var employeeDefined = true;
            if (employee == null)
            {
                employeeDefined = false;
            }
            else
            {
                employee.State = state;
            }
            employee = OwnerSql.Instance.EmployeeRead(employee);
            if (!GenericEntity.HasValue(employee))
            {
                if (employeeDefined)
                {
                    faultExceptionDetail.Code = "Employee is not hired at organisation [{0}] at [{1}].";
                    faultExceptionDetail.Parameters = new object[]
                    {
                        organisation.IDNO,
                        dateTimeOffset
                    };
                }
                employee = OwnerSql.Instance.EmployeeRead(new Employee
                {
                    Organisation = organisation,
                    IsDefault = true,
                    State = state
                });
                if (!GenericEntity.HasValue(employee))
                {
                    faultExceptionDetail.Code = "Employee not found and no default employee for organisation [{0}] defined.";
                    faultExceptionDetail.Parameters = new object[]
                    {
                        organisation.IDNO
                    };
                }
            }
            if (GenericEntity.HasValue(employee) &&
                employee.State.IsActive.HasValue &&
                !employee.State.IsActive.Value)
            {
                faultExceptionDetail.Code = "Person [{0}] is not employeed of organisation [{1}] at [{2}].";
                faultExceptionDetail.Parameters = new object[]
                {
                    employee.Person.IDNP,
                    employee.Organisation.IDNO,
                    dateTimeOffset
                };
            }
            GenericTranslate(faultExceptionDetail);
            return new Tuple<FaultExceptionDetail, Employee>(faultExceptionDetail, employee);
        }

        protected static Tuple<FaultExceptionDetail, Employee> EmployeeCheck(Branch branch, Employee employee, DateTimeOffset dateTimeOffset)
        {
            return EmployeeCheck(branch.Organisation, employee, dateTimeOffset);
        }

        protected static void Distance(IEnumerable<GenericEntity> entities, Session session = null)
        {
            if (entities == null) return;
            if (session == null)
            {
                session = Kernel.Instance.SessionManager.SessionRead();
            }
            var coordinates = GenericEntity.GetCoordinates(session.Token.ClientGeospatial);
            if (coordinates == null) return;
            foreach (var entity in entities)
            {
                if (entity == null) continue;
                entity.SetCoordinates(session.Token);
            }
        }

        protected static void Distance(GenericEntity entity, Session session = null)
        {
            Distance(new List<GenericEntity> {entity}, session);
        }

        protected void LoggingError(string message, bool rethrow)
        {
            if (DisableLoggingError) return;
            if (Logging == null)
            {
                Kernel.Instance.Logging.Error(message, rethrow);
            }
            else
            {
                Logging.Error(message, rethrow);
            }
        }

        protected void LoggingError(Exception exception, bool rethrow)
        {
            if (DisableLoggingError) return;
            if (Logging == null)
            {
                Kernel.Instance.Logging.Error(exception, rethrow);
            }
            else
            {
                Logging.Error(exception, rethrow);
            }
        }

        protected void LoggingError(Exception exception, string message)
        {
            if (DisableLoggingError) return;
            if (Logging == null)
            {
                Kernel.Instance.Logging.Error(exception, message);
            }
            else
            {
                Logging.Error(exception, message);
            }
        }

        protected void LoggingInformation(string message, params object[] parameters)
        {
            if (DisableLoggingInformation) return;
            if (Logging == null)
            {
                Kernel.Instance.Logging.Information(message, parameters);
            }
            else
            {
                Logging.Information(message, parameters);
            }
        }

        protected void LoggingWarning(string message, params object[] parameters)
        {
            if (DisableLoggingWarning) return;
            if (Logging == null)
            {
                Kernel.Instance.Logging.Warning(message, parameters);
            }
            else
            {
                Logging.Warning(message, parameters);
            }
        }

        #endregion Methods

        #endregion Protected Members
    }
}