#region Using

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net.Mail;
using System.Web;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Common;
using Nimble.Business.Library.Model.Framework.Geolocation;
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
    public class CommonLogic : GenericLogic
    {
        #region Private Members

        #region Properties

        private static readonly CommonLogic instance = new CommonLogic();

        #endregion Properties

        #region Methods

        private static void TokenPresetSearch(Token token, Preset preset)
        {
            if (token != null &&
                token.Account != null &&
                preset != null &&
                token.Account.Equals(preset.Account))
            {
                token.Presets = CommonSql.Instance.PresetSearch(new GenericInput<Preset, PresetPredicate>
                {
                    Predicate = new PresetPredicate
                    {
                        AccountPredicate = new AccountPredicate
                        {
                            Accounts = new Criteria<List<Account>>(new List<Account> {token.Account})
                        }
                    }
                }).Entities;
            }
        }

        private static void TokenSearch(bool isFiltered, bool isExcluded, ICollection<Token> tokens, Token token)
        {
            if (isFiltered)
            {
                if (isExcluded)
                {
                    tokens.Remove(token);
                }
            }
            else
            {
                if (!isExcluded)
                {
                    tokens.Add(token);
                }
            }
        }

        private static List<Token> TokenSearch(GenericInput<Token, TokenPredicate> genericInput, List<Token> tokens)
        {
            var searchTokens = new List<Token>();
            var filterTokens = new List<Token>();
            var isFiltered = false;
            if (genericInput.Emplacement != null)
            {
                tokens.RemoveAll(item => !item.Emplacement.Equals(genericInput.Emplacement));
            }
            if (genericInput.Application != null)
            {
                tokens.RemoveAll(item => !item.Application.Equals(genericInput.Application));
            }
            if (genericInput.Organisations != null)
            {
                var removeTokens = new List<Token>();
                foreach (var token in tokens)
                {
                    if (genericInput.Person != null &&
                        genericInput.Person.Equals(token.Person)) continue;
                    if (token.EmployeeOrganisations != null)
                    {
                        var found = false;
                        foreach (var organisation in token.EmployeeOrganisations)
                        {
                            if (genericInput.Organisations.FirstOrDefault(item => item.Equals(organisation)) == null) continue;
                            found = true;
                            break;
                        }
                        if (found) continue;
                    }
                    removeTokens.Add(token);
                }
                foreach (var token in removeTokens)
                {
                    tokens.Remove(token);
                }
            }
            if (genericInput.Predicate.LastUsedOn != null &&
                genericInput.Predicate.LastUsedOn.Value != null)
            {
                foreach (var token in tokens)
                {
                    TokenSearch(isFiltered, (token.LastUsedOn >= (genericInput.Predicate.LastUsedOn.Value.DateFrom ?? token.LastUsedOn) && token.LastUsedOn <= (genericInput.Predicate.LastUsedOn.Value.DateTo ?? token.LastUsedOn)) != genericInput.Predicate.LastUsedOn.IsExcluded, filterTokens, token);
                }
                isFiltered = true;
            }
            if (genericInput.Predicate.PermissionTypes != null &&
                genericInput.Predicate.PermissionTypes.Value != null &&
                genericInput.Predicate.PermissionTypes.Value.Count > 0)
            {
                foreach (var token in tokens)
                {
                    TokenSearch(isFiltered, genericInput.Predicate.PermissionTypes.Value.Contains(token.PermissionType) != genericInput.Predicate.PermissionTypes.IsExcluded, filterTokens, token);
                }
                isFiltered = true;
            }
            if (genericInput.Predicate.Tokens != null &&
                genericInput.Predicate.Tokens.Value != null &&
                genericInput.Predicate.Tokens.Value.Count > 0)
            {
                foreach (var token in tokens)
                {
                    TokenSearch(isFiltered, genericInput.Predicate.Tokens.Value.Contains(token) != genericInput.Predicate.Tokens.IsExcluded, filterTokens, token);
                }
                isFiltered = true;
            }
            if (genericInput.Predicate.AccountPredicate != null)
            {
                var accounts = SecurityLogic.Instance.AccountSearch(genericInput.Predicate.AccountPredicate).Entities;
                foreach (var token in tokens)
                {
                    TokenSearch(isFiltered, accounts.Contains(token.Account), filterTokens, token);
                }
                isFiltered = true;
            }
            if (genericInput.Predicate.PersonPredicate != null)
            {
                var persons = OwnerLogic.Instance.PersonSearch(genericInput.Predicate.PersonPredicate).Entities;
                foreach (var token in tokens)
                {
                    TokenSearch(isFiltered, persons.Contains(token.Person), filterTokens, token);
                }
                isFiltered = true;
            }
            if (isFiltered)
            {
                if (genericInput.Predicate.IsExcluded)
                {
                    foreach (var token in tokens)
                    {
                        if (filterTokens.Contains(token)) continue;
                        searchTokens.Add(token);
                    }
                }
                else
                {
                    searchTokens = filterTokens;
                }
            }
            else
            {
                searchTokens = tokens;
            }
            return searchTokens;
        }

        private static void LoadEntities(List<Group> groups, BondPredicate bondPredicate)
        {
            var groupIds = new Dictionary<Guid?, Group>();
            foreach (var group in groups)
            {
                if (group == null ||
                    !group.Id.HasValue ||
                    groupIds.ContainsKey(group.Id)) continue;
                groupIds.Add(group.Id, group.Reduce<Group>());
            }
            if (bondPredicate == null)
            {
                bondPredicate = new BondPredicate();
            }
            if (bondPredicate.GroupPredicate == null)
            {
                bondPredicate.GroupPredicate = new GroupPredicate();
            }
            bondPredicate.GroupPredicate.Groups = new Criteria<List<Group>>(groupIds.Values.ToList());
            var bondSearch = CommonSql.Instance.BondSearch(new GenericInput<Bond, BondPredicate>
            {
                Predicate = bondPredicate
            });
            foreach (var group in groups)
            {
                group.Entities = bondSearch.Entities.Where(item => item.Group.Equals(group)).Select(item => item.Entity).ToList();
            }
        }

        private static Split SplitCheck(Split split)
        {
            if (!TokenIsMaster())
            {
                ThrowException("Only system administrators can manage splits and groups.");
            }
            return split;
        }

        private static Group GroupCheck(Group group)
        {
            if (group != null)
            {
                SplitCheck(group.Split);
            }
            return group;
        }

        private static void SignOrganisation(Employee employee)
        {
            employee.Organisation = OwnerSql.Instance.OrganisationCreate(employee.Organisation);
            employee = OwnerLogic.EmployeeSave(employee, true, false);
            var branch = OwnerSql.Instance.BranchCreate(new Branch
            {
                Organisation = employee.Organisation,
                Name = employee.Organisation.Code,
                BranchActionType = new Flags<BranchActionType>(BranchActionType.None)
            });
        }

        public static Employee EmployeeCheck(Organisation organisation)
        {
            organisation = OwnerSql.Instance.OrganisationRead(organisation);
            EntityInstanceCheck(organisation);
            var dateTimeOffsetNow = DateTimeOffset.Now;
            if (organisation.LockedOn.HasValue &&
                organisation.LockedOn.Value < dateTimeOffsetNow)
            {
                ThrowException("Organisation [{0}] has been locked on [{1}] by reason [{2}].", organisation.IDNO, organisation.LockedOn, organisation.LockedReason);
            }
            var employee = OwnerSql.Instance.EmployeeRead(new Employee
            {
                Organisation = organisation,
                IsDefault = true,
                State = Kernel.Instance.StateGenerate(dateTimeOffsetNow, true)
            });
            if (!GenericEntity.HasValue(employee))
            {
                ThrowException("No default employee for organisation [{0}] defined.", organisation.IDNO);
            }
            else if (employee.State.IsActive.HasValue &&
                     !employee.State.IsActive.Value)
            {
                ThrowException(
                    "Person [{0}] is not employeed of organisation [{1}] at [{2}].",
                    employee.Person.IDNP,
                    employee.Organisation.IDNO,
                    dateTimeOffsetNow);
            }
            else if (!GenericEntity.HasValue(employee.Person.User))
            {
                ThrowException("Default employee for organisation [{0}] has not credentials.", organisation.IDNO);
            }
            SecurityLogic.Instance.LogCreate(new Log
            {
                LogActionType = LogActionType.SignInOrganisation,
                Parameters = new[]
                {
                    organisation.Code
                }
            });
            return employee;
        }

        private static User UserCheck(Session session, string userCode, string userPassword, bool isAnonymous, Employee employee)
        {
            User user;
            if (employee == null ||
                employee.Person == null ||
                employee.Person.User == null)
            {
                user = SecuritySql.Instance.UserRead(new User
                {
                    Emplacement = session.Token.Emplacement,
                    Code = userCode,
                    FacebookId = userCode,
                    GmailId = userCode
                });
            }
            else
            {
                user = employee.Person.User;
            }
            if (!GenericEntity.HasValue(user) ||
                string.CompareOrdinal(user.Password, isAnonymous ? user.Password : EngineStatic.EncryptMd5(userPassword)) != 0)
            {
                SecurityLogic.Instance.LogCreate(new Log
                {
                    LogActionType = LogActionType.LoginFault,
                    Parameters = new[]
                    {
                        userCode,
                        userPassword
                    }
                });
                ThrowException(new FaultExceptionDetail(FaultExceptionDetailType.Invalid));
            }
            else if (user.LockedOn.HasValue &&
                     user.LockedOn.Value < session.Token.LastUsedOn)
            {
                SecurityLogic.Instance.LogCreate(new Log
                {
                    LogActionType = LogActionType.LoginLocked,
                    Parameters = new[]
                    {
                        userCode,
                        user.LockedOn.Value.ToString(CultureInfo.InvariantCulture)
                    }
                });
                ThrowException(new FaultExceptionDetail(FaultExceptionDetailType.Locked, HttpUtility.UrlEncode(GenericEntity.GuidToBase64(user.Id))));
            }
            return user;
        }

        private static void SessionAccountCheck(Session session, bool isAnonymous)
        {
            session.Token.Account = SecuritySql.Instance.AccountRead(session.Token.Account);
            if (!GenericEntity.HasValue(session.Token.Account))
            {
                ThrowException("User is not assigned to application [{0}].", session.Token.Application.Code);
            }
            else if (session.Token.Account.LockedOn.HasValue &&
                     session.Token.Account.LockedOn.Value < session.Token.LastUsedOn)
            {
                ThrowException("User has been locked for application [{0}] on [{1}].", session.Token.Application.Code, session.Token.Account.LockedOn.Value);
            }
            else if (!isAnonymous &&
                     (!session.Token.Account.LastUsedOn.HasValue ||
                      session.Token.Account.LastUsedOn.Value.Add(TimeSpan.Parse(Kernel.Instance.ServerConfiguration.AccountLastUsedLatency)) < session.Token.LastUsedOn))
            {
                var connectionStrings = new List<string> {Kernel.Instance.ServerConfiguration.GenericDatabase};
                if (Kernel.Instance.ServerConfiguration.StoreIpInfo)
                {
                    connectionStrings.Add(Kernel.Instance.ServerConfiguration.GeolocationDatabase);
                }
                try
                {
                    TransactionBegin(connectionStrings.ToArray(), new List<LockType>
                    {
                        LockType.Account
                    });
                    session.Token.Account = SecuritySql.Instance.AccountRead(session.Token.Account);
                    session.Token.Account.LastUsedOn = session.Token.LastUsedOn;
                    session.Token.Account = SecuritySql.Instance.AccountUpdate(session.Token.Account);
                    TransactionComplete();
                }
                catch (Exception exception)
                {
                    TransactionRollback(exception);
                }
            }
        }

        private static void SessionDataMap(Session session, Employee employee)
        {
            SetToken(session.Token, ClientStatic.GetEnumValues<CommonPropertyType>().ToArray(), true);
            if (employee == null)
            {
                PermissionsCheck(session.Token.Account, null, session.Token);
                session.Token.Presets = CommonSql.Instance.PresetSearch(new GenericInput<Preset, PresetPredicate>
                {
                    Predicate = new PresetPredicate
                    {
                        AccountPredicate = new AccountPredicate
                        {
                            Accounts = new Criteria<List<Account>>(new List<Account> {session.Token.Account})
                        }
                    }
                }).Entities;
                session.Token.Person = OwnerSql.Instance.PersonRead(new Person {User = session.Token.Account.User});
            }
            else
            {
                session.Token.Person = employee.Person;
            }
            if (GenericEntity.HasValue(session.Token.Person))
            {
                if (session.Token.Person.LockedOn.HasValue &&
                    session.Token.Person.LockedOn.Value < session.Token.LastUsedOn)
                {
                    ThrowException("Person has been locked on [{0}].", session.Token.Person.LockedOn.Value);
                }
                if (employee == null)
                {
                    session.Token.Employees = OwnerSql.Instance.EmployeeSearch(new GenericInput<Employee, EmployeePredicate>
                    {
                        Predicate = new EmployeePredicate
                        {
                            PersonPredicate = new PersonPredicate
                            {
                                Persons = new Criteria<List<Person>>(new List<Person> {session.Token.Person})
                            },
                            OrganisationPredicate = new OrganisationPredicate
                            {
                                LockedOn = new Criteria<DateInterval>(new DateInterval
                                {
                                    DateFrom = session.Token.LastUsedOn
                                })
                            },
                            State = new Criteria<State>(Kernel.Instance.StateGenerate(true))
                        }
                    }).Entities;
                    if (session.Token.Employees.Count > 0)
                    {
                        session.Token.EmployeeBranches = OwnerSql.Instance.BranchSearch(new GenericInput<Branch, BranchPredicate>
                        {
                            Predicate = new BranchPredicate
                            {
                                OrganisationPredicate = new OrganisationPredicate
                                {
                                    Organisations = new Criteria<List<Organisation>>(EmployeeOrganisations(session.Token))
                                },
                                EmployeePredicate = new EmployeePredicate
                                {
                                    Employees = new Criteria<List<Employee>>(new List<Employee>(session.Token.Employees))
                                }
                            }
                        }).Entities;
                    }
                }
                else
                {
                    session.Token.Employees = new List<Employee>
                    {
                        employee
                    };
                }
            }
        }

        #region Person

        private static Person SignCheckPerson(Person person)
        {
            var faultExceptionDetail = new FaultExceptionDetail();
            if (GenericEntity.HasValue(SecuritySql.Instance.UserRead(person.User)))
            {
                faultExceptionDetail.Items.Add(new FaultExceptionDetail("User already exists."));
            }
            if (GenericEntity.HasValue(OwnerSql.Instance.PersonRead(person)))
            {
                faultExceptionDetail.Items.Add(new FaultExceptionDetail("Person already exists."));
            }
            EntityValidate(faultExceptionDetail, Kernel.Instance.TypeDeclaratorManager.Get(ClientStatic.Person).GetDisplayName());
            return person;
        }

        private static Person SignPerson(Person person)
        {
            EntityPropertiesCheck(
                person,
                "User.Code",
                "FirstName",
                "LastName",
                "BornOn",
                "Email");
            var session = Kernel.Instance.SessionManager.SessionRead();
            person.User.Emplacement = person.Emplacement = session.Token.Emplacement;
            person.User.CreatedOn = session.Token.LastUsedOn;
            if (string.IsNullOrEmpty(person.FirstName))
            {
                person.FirstName = person.User.Code;
            }
            if (string.IsNullOrEmpty(person.Email))
            {
                person.Email = person.User.Code;
            }
            return person;
        }

        private static Person SignPerson(string userCode)
        {
            return SignPerson(
                new Person
                {
                    User = new User
                    {
                        Code = userCode,
                        FacebookId = userCode,
                        GmailId = userCode
                    }
                });
        }

        #endregion Person

        #region Employee

        private static Employee SignCheckEmployee(Employee employee)
        {
            var faultExceptionDetail = new FaultExceptionDetail();
            if (GenericEntity.HasValue(OwnerSql.Instance.OrganisationRead(employee.Organisation)))
            {
                faultExceptionDetail.Items.Add(new FaultExceptionDetail("Organisation already exists."));
            }
            if (GenericEntity.HasValue(OwnerSql.Instance.EmployeeRead(employee)))
            {
                faultExceptionDetail.Items.Add(new FaultExceptionDetail("Employee already exists."));
            }
            EntityValidate(faultExceptionDetail, Kernel.Instance.TypeDeclaratorManager.Get(ClientStatic.Employee).GetDisplayName());
            return employee;
        }

        private static Employee SignEmployee(Employee employee)
        {
            EntityPropertiesCheck(
                employee,
                "Organisation.Code");
            employee.Person = SignPerson(employee.Person);
            var session = Kernel.Instance.SessionManager.SessionRead();
            employee.Organisation.Emplacement = session.Token.Emplacement;
            employee.CreatedOn = employee.Organisation.CreatedOn = employee.Organisation.RegisteredOn = session.Token.LastUsedOn;
            if (string.IsNullOrEmpty(employee.Organisation.IDNO))
            {
                employee.Organisation.IDNO = employee.Organisation.Code;
            }
            if (string.IsNullOrEmpty(employee.Organisation.Name))
            {
                employee.Organisation.Name = employee.Organisation.Code;
            }
            employee.Organisation.OrganisationActionType = new Flags<OrganisationActionType>(OrganisationActionType.Private);
            employee.Function = EmployeeActorType.OperationalAdministrator.ToString();
            employee.EmployeeActorType = EmployeeActorType.OperationalAdministrator;
            employee.IsDefault = true;
            if (employee.State == null)
            {
                employee.State = new State
                {
                    IsActive = true
                };
            }
            if (!employee.State.AppliedOn.HasValue)
            {
                employee.State.AppliedOn = Kernel.Instance.ServerConfiguration.EmployeeAppliedOn ?? session.Token.LastUsedOn;
            }
            return employee;
        }

        private static Employee SignEmployee(string organisationCode, string userCode)
        {
            return SignEmployee(
                new Employee
                {
                    Organisation = new Organisation
                    {
                        Code = organisationCode
                    },
                    Person = new Person
                    {
                        User = new User
                        {
                            Code = userCode,
                            FacebookId = userCode,
                            GmailId = userCode
                        }
                    }
                });
        }

        #endregion Employee

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        internal static CommonLogic Instance
        {
            get { return instance; }
        }

        #endregion Properties

        #region Methods

        public static CommonLogic InstanceCheck(PermissionType permissionType)
        {
            GenericCheck(permissionType);
            return instance;
        }

        #region Common

        public bool HandleException(FaultExceptionDetail faultExceptionDetail)
        {
            return GenericTranslate(faultExceptionDetail);
        }

        public Tuple<List<Culture>, List<Resource>, List<Translation>, Token> Multilanguage(CulturePredicate culturePredicate, ResourcePredicate resourcePredicate, TranslationPredicate translationPredicate)
        {
            var cultureSearch = MultilanguageLogic.Instance.CultureSearch(culturePredicate);
            var resourceSearch = MultilanguageLogic.Instance.ResourceSearch(resourcePredicate);
            var translationSearch = MultilanguageLogic.Instance.TranslationSearch(translationPredicate);
            var token = TokenRead();
            return new Tuple<List<Culture>, List<Resource>, List<Translation>, Token>(cultureSearch.Entities, resourceSearch.Entities, translationSearch.Entities, token);
        }

        public Translation Translation(Resource resource)
        {
            return GenericTranslation(resource);
        }

        public string Translate(string code, string category, params object[] parameters)
        {
            return GenericTranslate(code, category, parameters).Item1;
        }

        public Token Login(string userCode, string userPassword, bool isAnonymous = false, Employee employee = null)
        {
            var session = SessionSave(true);
            var user = UserCheck(session, userCode, userPassword, isAnonymous, employee);
            session.Token.Account = new Account
            {
                Application = session.Token.Application,
                User = user
            };
            Kernel.Instance.GenericCache.Remove(session.Token.Account); // Used with same database for few developers with different WCF-services and same account.
            SessionAccountCheck(session, isAnonymous);
            Kernel.Instance.SessionManager.SessionClear(session);
            SessionDataMap(session, employee);
            SecurityLogic.Instance.LogCreate(new Log {LogActionType = LogActionType.LoginSuccess});
            return session.Token;
        }

        public bool Logout()
        {
            SecurityLogic.Instance.LogCreate(new Log {LogActionType = LogActionType.Logout});
            return Kernel.Instance.SessionManager.SessionDelete();
        }

        public string IpInfoRead(string ip)
        {
            return IpInfoRead(ip, Kernel.Instance.ServerConfiguration.StoreIpInfo);
        }

        public string IpInfoRead(string ipData, bool storeIpInfo)
        {
            var ipInfoRead = ipData;
            if (storeIpInfo &&
                GenericEntity.IpAddressIsValid(ipData, true))
            {
                var block = GeolocationSql.Instance.BlockRead(new Block {IpDataFrom = ipData});
                if (GenericEntity.HasValue(block) &&
                    block.Location != null)
                {
                    ipInfoRead = string.Format(
                        Constants.IP_INFO_FORMAT, ipData, block.IpDataFrom, block.IpDataTo,
                        block.Location.Code,
                        block.Location.Country,
                        block.Location.Region,
                        block.Location.City,
                        block.Location.PostalCode,
                        block.Location.Latitude,
                        block.Location.Longitude,
                        block.Location.MetroCode,
                        block.Location.AreaCode);
                }
            }
            return ipInfoRead;
        }

        public Token SignIn(string referenceId)
        {
            return Login(referenceId, null, true);
        }

        public FaultExceptionDetail ResetPasswordSend(string email)
        {
            var faultExceptionDetail = new FaultExceptionDetail();
            var session = Kernel.Instance.SessionManager.SessionRead();
            var emails = new Dictionary<string, User>();
            var user = new User
            {
                Emplacement = session.Token.Emplacement,
                Code = email
            };
            user = SecurityLogic.Instance.UserRead(user);
            if (GenericEntity.HasValue(user) &&
                GenericEntity.EmailIsValid(user.Code, true) &&
                !emails.ContainsKey(user.Code))
            {
                emails.Add(user.Code, user);
            }
            var person = new Person
            {
                Emplacement = session.Token.Emplacement,
                Email = email
            };
            person = OwnerLogic.Instance.PersonRead(person);
            if (GenericEntity.HasValue(person) &&
                GenericEntity.HasValue(person.User) &&
                GenericEntity.EmailIsValid(person.Email, true) &&
                !emails.ContainsKey(person.Email))
            {
                emails.Add(person.Email, person.User);
            }
            if (emails.Count == 0)
            {
                ThrowException("There are no users found for email {0}.", email);
            }
            foreach (var item in emails)
            {
                var url = string.Format(Kernel.Instance.ServerConfiguration.ResetPasswordUrl, HttpUtility.UrlEncode(GenericEntity.GuidToBase64(item.Value.Id)), HttpUtility.UrlEncode(item.Value.Password));
                var subject = GenericTranslate("Reset password URL {0}", ResourceCategoryType.BusinessLogic, url);
                var body = GenericTranslate("Hi, see below reset password URL {0}", ResourceCategoryType.BusinessLogic, url);
                var sendFaultExceptionDetail = Kernel.Instance.MailManager.Send(new MailMessage(Kernel.Instance.MailManager.MailContext.UserName, item.Key, subject, body));
                faultExceptionDetail.Items.AddRange(sendFaultExceptionDetail.Items);
            }
            if (faultExceptionDetail.Items.Count > 0)
            {
                faultExceptionDetail.Code = GenericTranslate("There were errors on sending emails - see details.", ResourceCategoryType.BusinessLogic);
            }
            return faultExceptionDetail;
        }

        public User ResetPasswordCheck(string key, string value)
        {
            var user = SecurityLogic.Instance.UserRead(new User
            {
                Id = GenericEntity.Base64ToGuid(key)
            });
            if (!GenericEntity.HasValue(user))
            {
                ThrowException("No user found.");
            }
            else if (string.CompareOrdinal(user.Password, value) != 0)
            {
                ThrowException("Reset password value is obsolete.");
            }
            return user;
        }

        public User ResetPasswordProceed(string key, string value, string password, bool isEncrypted = true)
        {
            if (!isEncrypted)
            {
                value = EngineStatic.EncryptMd5(value);
            }
            var user = ResetPasswordCheck(key, value);
            user.Password = password;
            user.LockedOn = null;
            return SecurityLogic.Instance.UserUpdate(user);
        }

        public Person SignCheckPerson(string userCode)
        {
            return SignCheckPerson(SignPerson(userCode));
        }

        public Person SignUpPerson(Person person)
        {
            person = SignPerson(person);
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Account,
                    LockType.Person,
                    LockType.Filestream
                });
                person = FilestreamSync(OwnerLogic.PersonSave(person, EmployeeActorType.OperationalAdministrator, true), person.Filestreams);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return person;
        }

        public Employee SignCheckOrganisation(string organisationCode, string userCode)
        {
            var employee = SignCheckEmployee(SignEmployee(organisationCode, userCode));
            SignCheckPerson(employee.Person);
            return employee;
        }

        public Employee SignUpOrganisation(Employee employee)
        {
            employee = SignEmployee(employee);
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Account,
                    LockType.Person,
                    LockType.Employee
                });
                SignOrganisation(employee);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return employee;
        }

        public Token SignInOrganisation(Organisation organisation)
        {
            var employee = EmployeeCheck(organisation);
            return Login(employee.Person.User.Code, null, true, employee);
        }

        #endregion Common

        #region Token

        public Token TokenRead()
        {
            return Kernel.Instance.SessionManager.SessionRead().Token;
        }

        public Token TokenUpdate(Token token)
        {
            EntityInstanceCheck(token);
            var session = Kernel.Instance.SessionManager.SessionRead();
            if (token.Account != null)
            {
                if ((token.Account.CultureId.HasValue &&
                     !token.Account.CultureId.Equals(session.Token.Account.CultureId)) ||
                    (session.Token.Account.CultureId.HasValue &&
                     !session.Token.Account.CultureId.Equals(token.Account.CultureId)))
                {
                    session.Token.Account = SecurityLogic.Instance.AccountUpdate(token.Account);
                    SetToken(session.Token, ClientStatic.GetEnumValues<CommonPropertyType>().ToArray(), true);
                }
            }
            if (session.Token.Employees != null &&
                session.Token.Employees.Exists(item => item.Equals(token.Employee)) &&
                (GenericEntity.HasValue(token.Employee) &&
                 !token.Employee.Equals(session.Token.Employee)) ||
                (GenericEntity.HasValue(session.Token.Employee) &&
                 !session.Token.Employee.Equals(token.Employee)))
            {
                session.Token.Employee = token.Employee;
            }
            return session.Token;
        }

        public void TokenUpdate(Person person)
        {
            var session = Kernel.Instance.SessionManager.SessionRead();
            if (session.Token.Person != null &&
                session.Token.Person.Equals(person))
            {
                session.Token.Person = person;
            }
        }

        public void TokenUpdate(Employee employee)
        {
            var session = Kernel.Instance.SessionManager.SessionRead();
            if (session.Token.Employees != null)
            {
                var index = session.Token.Employees.FindIndex(item => item.Equals(employee));
                if (index >= 0)
                {
                    session.Token.Employees[index] = employee;
                }
            }
            TokenUpdate(employee.Person);
        }

        public bool TokenDelete(TokenPredicate tokenPredicate)
        {
            EntityInstanceCheck(tokenPredicate);
            return Kernel.Instance.SessionManager.TokenDelete(TokenSearch(GenericInputCheck<Token, TokenPredicate>(tokenPredicate), Kernel.Instance.SessionManager.TokenSearch()));
        }

        public List<Token> TokenSearch(TokenPredicate tokenPredicate)
        {
            EntityInstanceCheck(tokenPredicate);
            return TokenSearch(GenericInputCheck<Token, TokenPredicate>(tokenPredicate), Kernel.Instance.SessionManager.TokenSearch());
        }

        public bool TokenHasPermissions(PermissionType[] permissionTypes)
        {
            var session = Kernel.Instance.SessionManager.SessionRead();
            return PermissionsCheck(session.Token.Account, permissionTypes, session.Token);
        }

        public bool AccountHasPermissions(Account account, PermissionType[] permissionTypes)
        {
            return PermissionsCheck(account, permissionTypes, null);
        }

        public static bool TokenIsExpired()
        {
            return Kernel.Instance.SessionManager.TokenIsExpired();
        }

        #endregion Token

        #region Lock

        public bool LockDelete(Token token)
        {
            EntityInstanceCheck(token);
            return Kernel.Instance.SessionManager.LockDelete(token);
        }

        public List<Token> LockSearch(TokenPredicate tokenPredicate)
        {
            EntityInstanceCheck(tokenPredicate);
            return TokenSearch(GenericInputCheck<Token, TokenPredicate>(tokenPredicate), Kernel.Instance.SessionManager.LockSearch());
        }

        #endregion Lock

        #region Preset

        public Preset PresetCreate(Preset preset)
        {
            EntityInstanceCheck(preset);
            var session = Kernel.Instance.SessionManager.SessionRead();
            if (!TokenIsMaster(session.Token))
            {
                preset.Account = session.Token.Account;
            }
            EntityPropertiesCheck(
                preset,
                "Account",
                "PresetEntityType",
                "Code",
                "Predicate");
            preset = CommonSql.Instance.PresetCreate(preset);
            TokenPresetSearch(session.Token, preset);
            return preset;
        }

        public Preset PresetRead(Preset preset)
        {
            EntityInstanceCheck(preset);
            return CommonSql.Instance.PresetRead(preset);
        }

        public Preset PresetUpdate(Preset preset)
        {
            EntityInstanceCheck(preset);
            var session = Kernel.Instance.SessionManager.SessionRead();
            var presetEntity = CommonSql.Instance.PresetRead(preset);
            if (!TokenIsMaster(session.Token))
            {
                if (presetEntity != null &&
                    !presetEntity.Account.Equals(session.Token.Account))
                {
                    ThrowException("User can update only owner presets.");
                }
                else
                {
                    preset.Account = session.Token.Account;
                }
            }
            EntityPropertiesCheck(
                preset,
                "Account",
                "PresetEntityType",
                "Code",
                "Predicate");
            preset = CommonSql.Instance.PresetUpdate(preset);
            TokenPresetSearch(session.Token, preset);
            return preset;
        }

        public bool PresetDelete(Preset preset)
        {
            EntityInstanceCheck(preset);
            var session = Kernel.Instance.SessionManager.SessionRead();
            var presetEntity = CommonSql.Instance.PresetRead(preset);
            if (!TokenIsMaster(session.Token) &&
                presetEntity != null &&
                !presetEntity.Account.Equals(session.Token.Account))
            {
                ThrowException("User can delete only owner presets.");
            }
            var removed = CommonSql.Instance.PresetDelete(preset);
            TokenPresetSearch(session.Token, presetEntity);
            return removed;
        }

        public GenericOutput<Preset> PresetSearch(PresetPredicate presetPredicate)
        {
            var session = Kernel.Instance.SessionManager.SessionRead();
            if (!TokenIsMaster(session.Token))
            {
                presetPredicate.AccountPredicate = new AccountPredicate
                {
                    Accounts = new Criteria<List<Account>>(new List<Account> {session.Token.Account})
                };
            }
            return CommonSql.Instance.PresetSearch(GenericInputCheck<Preset, PresetPredicate>(presetPredicate));
        }

        #endregion Preset

        #region Split

        public Split SplitCreate(Split split)
        {
            EntityPropertiesCheck(
                split,
                "SplitEntityType",
                "SplitEntityCode",
                "Name");
            split.Emplacement = EmplacementCheck(split.Emplacement);
            SplitCheck(split);
            return CommonSql.Instance.SplitCreate(split);
        }

        public Split SplitRead(Split split)
        {
            EntityInstanceCheck(split);
            split = CommonSql.Instance.SplitRead(split);
            if (GenericEntity.HasValue(split))
            {
                EmplacementCheck(split.Emplacement);
            }
            return split;
        }

        public Split SplitUpdate(Split split)
        {
            EntityPropertiesCheck(
                split,
                "Name");
            SplitCheck(SplitRead(split));
            return CommonSql.Instance.SplitUpdate(split);
        }

        public bool SplitDelete(Split split)
        {
            SplitCheck(SplitRead(split));
            return CommonSql.Instance.SplitDelete(split);
        }

        public GenericOutput<Split> SplitSearch(SplitPredicate splitPredicate)
        {
            return CommonSql.Instance.SplitSearch(GenericInputCheck<Split, SplitPredicate>(splitPredicate));
        }

        #endregion Split

        #region Group

        public Group GroupCreate(Group group)
        {
            EntityPropertiesCheck(
                group,
                "Split",
                "Name");
            group.Split = SplitCheck(SplitRead(group.Split));
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Group
                });
                group = CommonSql.Instance.GroupCreate(group);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return group;
        }

        public Group GroupRead(Group group)
        {
            EntityInstanceCheck(group);
            group = CommonSql.Instance.GroupRead(group);
            if (GenericEntity.HasValue(group))
            {
                EmplacementCheck(group.Split.Emplacement);
            }
            return group;
        }

        public Group GroupUpdate(Group group)
        {
            EntityPropertiesCheck(
                group,
                "Code",
                "Name");
            GroupCheck(GroupRead(group));
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Group
                });
                group = CommonSql.Instance.GroupUpdate(group);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return group;
        }

        public bool GroupDelete(Group group)
        {
            var deleted = false;
            GroupCheck(GroupRead(group));
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GenericDatabase}, new List<LockType>
                {
                    LockType.Group
                });
                deleted = CommonSql.Instance.GroupDelete(group);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return deleted;
        }

        public GenericOutput<Group> GroupSearch(GroupPredicate groupPredicate)
        {
            var genericOutput = CommonSql.Instance.GroupSearch(GenericInputCheck<Group, GroupPredicate>(groupPredicate));
            if (genericOutput.Entities.Count > 0 &&
                groupPredicate != null)
            {
                if (groupPredicate.LoadEntities)
                {
                    LoadEntities(genericOutput.Entities, new BondPredicate
                    {
                        Columns = groupPredicate.HandleColumns(),
                        GroupPredicate = groupPredicate
                    });
                }
            }
            return genericOutput;
        }

        #endregion Group

        #region Bond

        public Bond BondRead(Bond bond)
        {
            EntityInstanceCheck(bond);
            bond = CommonSql.Instance.BondRead(bond);
            if (GenericEntity.HasValue(bond))
            {
                EmplacementCheck(bond.Group.Split.Emplacement);
            }
            return bond;
        }

        public GenericOutput<Bond> BondSearch(BondPredicate bondPredicate)
        {
            return CommonSql.Instance.BondSearch(GenericInputCheck<Bond, BondPredicate>(bondPredicate));
        }

        #endregion Bond

        #region Filestream

        public Filestream FilestreamRead(Filestream filestream)
        {
            return CommonSql.Instance.FilestreamRead(filestream);
        }

        public GenericOutput<Filestream> FilestreamSearch(FilestreamPredicate filestreamPredicate)
        {
            var genericInput = GenericInputCheck<Filestream, FilestreamPredicate>(filestreamPredicate);
            if (filestreamPredicate.PersonPredicate == null &&
                filestreamPredicate.OrganisationPredicate == null &&
                filestreamPredicate.EmployeePredicate == null &&
                filestreamPredicate.BranchPredicate == null &&
                filestreamPredicate.BranchGroupPredicate == null &&
                filestreamPredicate.PostPredicate == null &&
                filestreamPredicate.PostGroupPredicate == null)
            {
                filestreamPredicate.PersonPredicate = new PersonPredicate();
                filestreamPredicate.OrganisationPredicate = new OrganisationPredicate();
                filestreamPredicate.EmployeePredicate = new EmployeePredicate();
                filestreamPredicate.BranchPredicate = new BranchPredicate();
                filestreamPredicate.BranchGroupPredicate = new BranchGroupPredicate();
                filestreamPredicate.PostPredicate = new PostPredicate();
                filestreamPredicate.PostGroupPredicate = new PostGroupPredicate();
            }
            return CommonSql.Instance.FilestreamSearch(genericInput);
        }

        public T FilestreamSync<T>(T entity, List<Filestream> filestreams) where T : GenericEntity
        {
            if (GenericEntity.HasValue(entity) &&
                filestreams != null)
            {
                var entityId = entity.GetId();
                foreach (var filestream in filestreams)
                {
                    filestream.EntityId = entityId;
                    filestream.ReferenceId = Guid.NewGuid();
                    filestream.SetDefaults();
                }
                try
                {
                    foreach (var filestream in filestreams)
                    {
                        if (filestream.Data == null ||
                            filestream.EntityActionType == EntityActionType.None) continue;
                        var filePath = FilePath(filestream.ReferenceId, filestream.Extension);
                        var thumbnailId = Guid.NewGuid();
                        var thumbnailPath = FilePath(thumbnailId, filestream.ThumbnailExtension);
                        if (filestream.EntityActionType == EntityActionType.Delete) continue;
                        var fileStream = FileSave(filePath, filestream.Data);
                        if (!filestream.ThumbnailWidth.HasValue ||
                            !filestream.ThumbnailHeight.HasValue) continue;
                        try
                        {
                            fileStream = File.OpenRead(filePath);
                            var bitmap = EngineStatic.ResizeImage(fileStream, filestream.ThumbnailWidth, filestream.ThumbnailHeight);
                            if (bitmap == null) continue;
                            bitmap.Save(thumbnailPath);
                            filestream.ThumbnailId = thumbnailId;
                            filestream.ThumbnailWidth = bitmap.Width;
                            filestream.ThumbnailHeight = bitmap.Height;
                        }
                        catch (Exception exception)
                        {
                            Kernel.Instance.Logging.Error(exception, false);
                        }
                        finally
                        {
                            fileStream.Close();
                        }
                    }
                }
                catch (Exception exception)
                {
                    Kernel.Instance.Logging.Error(exception, false);
                }
                var genericInput = new GenericInput<Filestream, FilestreamPredicate>
                {
                    Predicate = new FilestreamPredicate
                    {
                        Filestreams = new Criteria<List<Filestream>>(filestreams)
                    }
                };
                CommonSql.Instance.FilestreamSync(genericInput);
            }
            return entity;
        }

        public bool FilestreamRemove(FilestreamPredicate filestreamPredicate)
        {
            return CommonSql.Instance.FilestreamRemove(new GenericInput<Filestream, FilestreamPredicate>
            {
                Predicate = filestreamPredicate
            });
        }

        #endregion Filestream

        public static void Start()
        {
            #region Emplacement

            Emplacement emplacement = null;
            if (!string.IsNullOrEmpty(Kernel.Instance.ServerConfiguration.EmplacementCode))
            {
                emplacement = new Emplacement
                {
                    Code = Kernel.Instance.ServerConfiguration.EmplacementCode,
                    IsAdministrative = Kernel.Instance.ServerConfiguration.EmplacementIsAdministrative
                };
                var emplacementEntity = SecuritySql.Instance.EmplacementRead(emplacement);
                if (emplacementEntity == null)
                {
                    emplacement = SecuritySql.Instance.EmplacementCreate(emplacement);
                    Kernel.Instance.Logging.Information(Constants.ENTITY_ADDED, "Emplacement", emplacement.Code);
                }
                else
                {
                    if (emplacementEntity.IsAdministrative == emplacement.IsAdministrative)
                    {
                        emplacement = emplacementEntity;
                    }
                    else
                    {
                        emplacementEntity.IsAdministrative = emplacement.IsAdministrative;
                        emplacement = SecuritySql.Instance.EmplacementUpdate(emplacementEntity);
                        Kernel.Instance.Logging.Information(Constants.ENTITY_UPDATED, "Emplacement", emplacement.Code);
                    }
                }
            }

            #endregion Emplacement

            #region Application

            Application application = null;
            if (!string.IsNullOrEmpty(Kernel.Instance.ServerConfiguration.ApplicationCode))
            {
                application = new Application
                {
                    Code = Kernel.Instance.ServerConfiguration.ApplicationCode,
                    IsAdministrative = Kernel.Instance.ServerConfiguration.ApplicationIsAdministrative
                };
                var applicationEntity = SecuritySql.Instance.ApplicationRead(application);
                if (applicationEntity == null)
                {
                    application = SecuritySql.Instance.ApplicationCreate(application);
                    Kernel.Instance.Logging.Information(Constants.ENTITY_ADDED, "Application", application.Code);
                }
                else
                {
                    if (applicationEntity.IsAdministrative == application.IsAdministrative)
                    {
                        application = applicationEntity;
                    }
                    else
                    {
                        applicationEntity.IsAdministrative = application.IsAdministrative;
                        application = SecuritySql.Instance.ApplicationUpdate(applicationEntity);
                        Kernel.Instance.Logging.Information(Constants.ENTITY_UPDATED, "Application", application.Code);
                    }
                }
            }

            #endregion Application

            #region User

            User user = null;
            if (!string.IsNullOrEmpty(Kernel.Instance.ServerConfiguration.UserCode) &&
                !string.IsNullOrEmpty(Kernel.Instance.ServerConfiguration.UserPassword))
            {
                if (emplacement == null)
                {
                    Kernel.Instance.Logging.Information("Cannot add/update user - emplacement not defined.");
                }
                else
                {
                    user = new User
                    {
                        Emplacement = emplacement,
                        Code = Kernel.Instance.ServerConfiguration.UserCode,
                        Password = Kernel.Instance.ServerConfiguration.UserPassword,
                        CreatedOn = DateTimeOffset.Now
                    };
                    var userEntity = SecuritySql.Instance.UserRead(user);
                    if (userEntity == null)
                    {
                        user = SecuritySql.Instance.UserCreate(user);
                        Kernel.Instance.Logging.Information(Constants.ENTITY_ADDED, "User", user.Code + Constants.SLASH_DELIMITER + user.Password);
                    }
                    else
                    {
                        if (string.CompareOrdinal(userEntity.Password, EngineStatic.EncryptMd5(user.Password)) == 0)
                        {
                            user = userEntity;
                        }
                        else
                        {
                            userEntity.Password = user.Password;
                            user = SecuritySql.Instance.UserUpdate(userEntity);
                            Kernel.Instance.Logging.Information(Constants.ENTITY_ADDED, "User", user.Code + Constants.SLASH_DELIMITER + user.Password);
                        }
                    }
                }
            }

            #endregion User

            #region Account

            Account account = null;
            if (user == null)
            {
                Kernel.Instance.Logging.Information("Cannot add/update account - user not defined.");
            }
            else if (application == null)
            {
                Kernel.Instance.Logging.Information("Cannot add/update account - application not defined.");
            }
            else
            {
                account = new Account
                {
                    User = user,
                    Application = application
                };
                var accountEntity = SecuritySql.Instance.AccountRead(account);
                if (accountEntity == null)
                {
                    account = SecuritySql.Instance.AccountCreate(account);
                    Kernel.Instance.Logging.Information(Constants.ENTITY_ADDED, "Account", user.Code + Constants.SLASH_DELIMITER + application.Code);
                }
                else
                {
                    if (accountEntity.LockedOn.HasValue)
                    {
                        accountEntity.LockedOn = null;
                        account = SecuritySql.Instance.AccountUpdate(accountEntity);
                        Kernel.Instance.Logging.Information(Constants.ENTITY_UPDATED, "Account", user.Code + Constants.SLASH_DELIMITER + application.Code);
                    }
                    else
                    {
                        account = accountEntity;
                    }
                }
            }

            #endregion Account

            #region Role

            Role role = null;
            if (!string.IsNullOrEmpty(Kernel.Instance.ServerConfiguration.RoleCode))
            {
                if (emplacement == null)
                {
                    Kernel.Instance.Logging.Information("Cannot add/update role - emplacement not defined.");
                }
                else if (application == null)
                {
                    Kernel.Instance.Logging.Information("Cannot add/update role - application not defined.");
                }
                else
                {
                    role = new Role
                    {
                        Emplacement = emplacement,
                        Application = application,
                        Code = Kernel.Instance.ServerConfiguration.RoleCode
                    };
                    var roleEntity = SecuritySql.Instance.RoleRead(role);
                    if (roleEntity == null)
                    {
                        role = SecuritySql.Instance.RoleCreate(role);
                        Kernel.Instance.Logging.Information(Constants.ENTITY_ADDED, "Role", role.Code);
                    }
                    else
                    {
                        if (string.Compare(roleEntity.Description, role.Description, StringComparison.OrdinalIgnoreCase) == 0)
                        {
                            role = roleEntity;
                        }
                        else
                        {
                            roleEntity.Description = role.Description;
                            role = SecuritySql.Instance.RoleUpdate(roleEntity);
                            Kernel.Instance.Logging.Information(Constants.ENTITY_UPDATED, "Role", role.Code);
                        }
                    }
                    if (account == null)
                    {
                        Kernel.Instance.Logging.Information("Cannot assign role - account not defined.");
                    }
                    else
                    {
                        account.Roles = SecuritySql.Instance.RoleSearch(new GenericInput<Role, RolePredicate>
                        {
                            Predicate = new RolePredicate
                            {
                                AccountPredicate = new AccountPredicate
                                {
                                    Accounts = new Criteria<List<Account>>(new List<Account> {account})
                                }
                            }
                        }).Entities;
                        var roleId = role.Id;
                        if (account.Roles.Find(item => item.Id.Equals(roleId)) == null)
                        {
                            account.Roles.Add(role);
                            account = SecuritySql.Instance.AccountUpdate(account);
                            Kernel.Instance.Logging.Information("[{0}] role of application [{1}] assigned to [{2}] user.", role.Code, account.Application.Code, account.User.Code);
                        }
                    }
                }
            }

            #endregion Role

            #region Permissions

            if (Kernel.Instance.ServerConfiguration.UpdatePermissions.HasValue)
            {
                if (application == null)
                {
                    Kernel.Instance.Logging.Information("Cannot add/update permissions - application not defined.");
                }
                else
                {
                    var applicationPermissions = SecuritySql.Instance.PermissionSearch(new GenericInput<Permission, PermissionPredicate>
                    {
                        Predicate = new PermissionPredicate
                        {
                            ApplicationPredicate = new ApplicationPredicate
                            {
                                Applications = new Criteria<List<Application>>(new List<Application> {application})
                            }
                        }
                    });
                    List<Permission> permissions;
                    if (Kernel.Instance.ServerConfiguration.UpdatePermissions.Value)
                    {
                        permissions = new List<Permission>();
                        var customAttributes = ClientStatic.GetCustomAttributes<FieldCategory>(ClientStatic.PermissionType, null, false);
                        foreach (var customAttribute in customAttributes)
                        {
                            if (customAttribute.Value == null ||
                                customAttribute.Value.FieldCategoryType == FieldCategoryType.None) continue;
                            var category = customAttribute.Value.Name;
                            var description = customAttribute.Value.Description;
                            if (string.IsNullOrEmpty(category))
                            {
                                var fieldCategory = ClientStatic.GetCustomAttribute<FieldCategory>(ClientStatic.FieldCategoryType.GetField(customAttribute.Value.FieldCategoryType.ToString()), false);
                                if (fieldCategory == null) continue;
                                if (!string.IsNullOrEmpty(fieldCategory.Name))
                                {
                                    category = fieldCategory.Name;
                                }
                                if (string.IsNullOrEmpty(description))
                                {
                                    description = fieldCategory.Description;
                                }
                            }
                            var permission = new Permission
                            {
                                Application = application,
                                Code = customAttribute.Key.Name,
                                Category = category,
                                Description = description
                            };
                            var permissionEntity = SecuritySql.Instance.PermissionRead(permission);
                            if (permissionEntity == null)
                            {
                                permission = SecuritySql.Instance.PermissionCreate(permission);
                                Kernel.Instance.Logging.Information(Constants.ENTITY_ADDED, "Permission", permission.Code);
                            }
                            else
                            {
                                if (string.Compare(permissionEntity.Code, permission.Code, StringComparison.OrdinalIgnoreCase) == 0 &&
                                    string.Compare(permissionEntity.Category, permission.Category, StringComparison.OrdinalIgnoreCase) == 0 &&
                                    string.Compare(permissionEntity.Description, permission.Description, StringComparison.OrdinalIgnoreCase) == 0)
                                {
                                    permission = permissionEntity;
                                }
                                else
                                {
                                    permissionEntity.Code = permission.Code;
                                    permissionEntity.Category = permission.Category;
                                    permissionEntity.Description = permission.Description;
                                    permission = SecuritySql.Instance.PermissionUpdate(permissionEntity);
                                    Kernel.Instance.Logging.Information(Constants.ENTITY_UPDATED, "Permission", permission.Code);
                                }
                            }
                            permissionEntity = applicationPermissions.Entities.Find(item => item.Equals(permission));
                            if (permissionEntity != null)
                            {
                                applicationPermissions.Entities.Remove(permissionEntity);
                            }
                            permissions.Add(permission);
                        }
                        foreach (var permission in applicationPermissions.Entities)
                        {
                            SecuritySql.Instance.PermissionDelete(permission);
                            Kernel.Instance.Logging.Information(Constants.ENTITY_REMOVED, "Permission", permission.Code);
                        }
                    }
                    else
                    {
                        permissions = applicationPermissions.Entities;
                    }
                    if (role == null)
                    {
                        Kernel.Instance.Logging.Information("Cannot assign permissions - role not defined.");
                    }
                    else
                    {
                        role.Permissions = permissions;
                        role = SecuritySql.Instance.RoleUpdate(role);
                        Kernel.Instance.Logging.Information("{0} permissions assigned to [{1}] role.", permissions.Count, role.Code);
                    }
                }
            }

            #endregion Permissions

            #region Roles

            if (Kernel.Instance.ServerConfiguration.UpdateEmployeeActorTypeRoles)
            {
                if (emplacement == null)
                {
                    Kernel.Instance.Logging.Information("Cannot add/update employee actor type roles - emplacement not defined.");
                }
                else if (application == null)
                {
                    Kernel.Instance.Logging.Information("Cannot add/update employee actor type roles - application not defined.");
                }
                else
                {
                    var emplacements = SecuritySql.Instance.EmplacementSearch(new GenericInput<Emplacement, EmplacementPredicate>()).Entities;
                    var applications = SecuritySql.Instance.ApplicationSearch(new GenericInput<Application, ApplicationPredicate>()).Entities;
                    var serviceRoles = Kernel.Instance.ServerConfiguration.ServiceRoles();
                    foreach (var serviceRole in serviceRoles)
                    {
                        role = new Role
                        {
                            Emplacement = emplacement,
                            Application = application,
                            Code = serviceRole.Value.Role
                        };
                        if (!string.IsNullOrEmpty(serviceRole.Value.Emplacement))
                        {
                            role.Emplacement = emplacements.Find(item => item.Code.Equals(serviceRole.Value.Emplacement));
                            if (role.Emplacement == null) continue;
                        }
                        if (!string.IsNullOrEmpty(serviceRole.Value.Application))
                        {
                            role.Application = applications.Find(item => item.Code.Equals(serviceRole.Value.Application));
                            if (role.Application == null) continue;
                        }
                        var roleEntity = SecuritySql.Instance.RoleRead(role);
                        if (roleEntity == null)
                        {
                            role = SecuritySql.Instance.RoleCreate(role);
                            Kernel.Instance.Logging.Information("Role [{0}] created with emplacement [{1}] and application [{2}]", role.Code, role.Emplacement.Code, role.Application.Code);
                        }
                        else
                        {
                            role = roleEntity;
                        }
                        var rolePermissions = SecuritySql.Instance.PermissionSearch(new GenericInput<Permission, PermissionPredicate>
                        {
                            Predicate = new PermissionPredicate
                            {
                                RolePredicate = new RolePredicate
                                {
                                    Roles = new Criteria<List<Role>>(new List<Role> {role})
                                }
                            }
                        });
                        var assignedPermissions = new List<Permission>();
                        foreach (var permissionCode in serviceRole.Value.Permissions)
                        {
                            var permission = rolePermissions.Entities.Find(item => item.Code == permissionCode) ?? new Permission
                            {
                                Application = application,
                                Code = permissionCode
                            };
                            assignedPermissions.Add(permission);
                        }
                        var permissionsEquals = rolePermissions.Entities.Count == assignedPermissions.Count;
                        if (permissionsEquals)
                        {
                            foreach (var permission in assignedPermissions)
                            {
                                var permissionCode = permission.Code;
                                if (rolePermissions.Entities.Find(item => item.Code == permissionCode) != null) continue;
                                permissionsEquals = false;
                                break;
                            }
                        }
                        if (permissionsEquals) continue;
                        role.Permissions = assignedPermissions;
                        SecuritySql.Instance.RoleUpdate(role);
                        Kernel.Instance.Logging.Information("{0} permissions assigned to [{1}] employee actor type role.", assignedPermissions.Count, role.Code);
                    }
                }
            }

            #endregion Roles

            #region Translations

            if (!string.IsNullOrEmpty(Kernel.Instance.ServerConfiguration.CultureCode) &&
                !string.IsNullOrEmpty(Kernel.Instance.ServerConfiguration.CultureName))
            {
                if (emplacement == null)
                {
                    Kernel.Instance.Logging.Information("Cannot add culture - emplacement not defined.");
                }
                else
                {
                    var culture = new Culture
                    {
                        Emplacement = emplacement,
                        Code = Kernel.Instance.ServerConfiguration.CultureCode,
                        Name = Kernel.Instance.ServerConfiguration.CultureName
                    };
                    var languageEntity = MultilanguageSql.Instance.CultureRead(culture);
                    if (languageEntity == null)
                    {
                        culture = MultilanguageSql.Instance.CultureCreate(culture);
                        Kernel.Instance.Logging.Information(Constants.ENTITY_ADDED, "Culture", culture.Code);
                    }
                    else
                    {
                        culture = languageEntity;
                    }
                    if (Kernel.Instance.ServerConfiguration.DefineEmplacementCulture)
                    {
                        emplacement.CultureId = culture.Id;
                        emplacement = SecuritySql.Instance.EmplacementUpdate(emplacement);
                        Kernel.Instance.Logging.Information("Culture [{0}] assigned to emplacement [{1}]", culture.Name, emplacement.Code);
                    }
                    if (Kernel.Instance.ServerConfiguration.DefineAccountCulture &&
                        account != null)
                    {
                        account.CultureId = culture.Id;
                        account = SecuritySql.Instance.AccountUpdate(account);
                        Kernel.Instance.Logging.Information("Culture [{0}] assigned to user [{1}] of application [{2}]", culture.Name, account.User.Code, account.Application.Code);
                    }
                }
            }
            if (Kernel.Instance.ServerConfiguration.MultilanguageCopy)
            {
                if (emplacement == null)
                {
                    Kernel.Instance.Logging.Information("Cannot copy entities - emplacement not defined.");
                }
                else if (application == null)
                {
                    Kernel.Instance.Logging.Information("Cannot copy entities - application not defined.");
                }
                else
                {
                    MultilanguageSql.Instance.Copy(emplacement, application);
                    Kernel.Instance.Logging.Information("All translations entities copied for emplacement [{0}] and application [{1}].", emplacement.Code, application.Code);
                }
            }

            #endregion Translations

            #region Cache

            if (Kernel.Instance.ServerConfiguration.MultilanguageCacheOnLoad)
            {
                MultilanguageSql.Instance.TranslationSearch(new GenericInput<Translation, TranslationPredicate>
                {
                    Predicate = new TranslationPredicate
                    {
                        Translated = true
                    }
                });
            }

            #endregion Cache
        }

        public static void ApplicationStart(bool start)
        {
            Kernel.Instance.Start();
            Kernel.Instance.CheckConnections();
            HangfireContext.Start();
            if (start)
            {
                Start();
            }
        }

        public static void ApplicationEnd()
        {
            Kernel.Instance.End();
        }

        #endregion Methods

        #endregion Public Members
    }
}