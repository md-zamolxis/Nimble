using System;
using System.Collections.Generic;
using System.Xml;
using System.Net;
using System.Text.RegularExpressions;
using System.Web;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Common;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Business.Library.Model.Framework.Owner;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Windows.Client;
using Nimble.Windows.Client.Common;

namespace Testing.Windows.Client
{
    [TestClass]
    public class UnitTest
    {
        [TestMethod]
        public void TestClient()
        {
            try
            {
                //ClientManager.Instance.Start(XmlReader.Create(AppDomain.CurrentDomain.SetupInformation.ConfigurationFile));
                //ClientManager.Instance.Start("http://80.245.81.59:50004/Nimble.Server.Iis/");
                ClientManager.Instance.Start();
                ClientManager.Instance.CustomMessageHeader.ClientGeospatial = new KeyValuePair<string, string>("ClientGeospatial", "47,26");
                ClientManager.Instance.Login("sa", "1");
                ClientManager.Instance.CustomMessageHeader.ClientGeospatial = new KeyValuePair<string, string>("ClientGeospatial", "48,25");
                var tokens = ClientManager.Instance.Common.TokenSearch(new TokenPredicate());
                ClientManager.Instance.CustomMessageHeader.ClientGeospatial = new KeyValuePair<string, string>("ClientGeospatial", "49,24");
                ClientManager.Instance.Security.LogCreate(new Log
                    {
                        LogActionType = LogActionType.Page,
                        Parameters = new[]
                            {
                                "Default.aspx"
                            }
                    });
                var genericOutput = ClientManager.Instance.CultureSearch(new CulturePredicate());
                var user = new User
                    {
                        Emplacement = ClientManager.Instance.Token.Emplacement,
                        Code = "Beermann",
                        Password = "Beermann"
                    };
                if (!GenericEntity.HasValue(ClientManager.Instance.Security.UserRead(user)))
                {
                    user = ClientManager.Instance.Security.UserCreate(user);
                }
            }
            catch (Exception exception)
            {
                var faultExceptionDetail = FaultExceptionDetail.Create(exception);
            }
        }

        [TestMethod]
        public void TestResetPasswordSend()
        {
            ClientManager.Instance.Start();
            var faultExceptionDetail = ClientManager.Instance.Common.ResetPasswordSend("dujacorneliu@hotmail.com");
        }

        [TestMethod]
        public void TestResetPasswordProceed()
        {
            ClientManager.Instance.Start();
            var faultExceptionDetail = ClientManager.Instance.Common.ResetPasswordProceed(HttpUtility.UrlDecode("YWZiMjEyZjQtN2U1Ny1lMzExLTg0YzUtMDAyMTg1NjZmOTU4"), HttpUtility.UrlDecode("202cb962ac59075b964b07152d234b70"), "123");
        }

        [TestMethod]
        public void TestTokenSearch()
        {
            ClientManager.Instance.Start();
            ClientManager.Instance.Login("master", "G2dxYPyhXGE");
            var dateTimeOffsetNow = new DateTimeOffset(2014, 1, 1, 0, 0, 0, new TimeSpan(0));
            var emplacement = new Emplacement
                {
                    Code = "MoneyQuest.Central",
                    Description = "MoneyQuest.Central",
                    IsAdministrative = true
                };
            var organisation = new Organisation
                {
                    Emplacement = emplacement,
                    Code = "MoneyQuest",
                    IDNO = "MoneyQuest",
                    Name = "MoneyQuest",
                    RegisteredOn = dateTimeOffsetNow,
                    OrganisationActionType = new Flags<OrganisationActionType>(OrganisationActionType.Public)
                };
            var employee = new Employee
                {
                    Person = new Person
                        {
                            Emplacement = emplacement,
                            User = new User
                                {
                                    Emplacement = emplacement,
                                    Code = "master@mq.md",
                                    Password = "admin",
                                },
                            FirstName = "Admin",
                            LastName = "MoneyQuest",
                            Email = "master@mq.md"
                        },
                    Organisation = organisation,
                    EmployeeActorType = EmployeeActorType.OperationalAdministrator,
                    IsDefault = true,
                    State = new State
                        {
                            AppliedOn = dateTimeOffsetNow,
                            IsActive = true
                        }
                };
            if (!GenericEntity.HasValue(ClientManager.Instance.Owner.EmployeeRead(employee)))
            {
                employee = ClientManager.Instance.Owner.EmployeeCreate(employee);
            }
            organisation = new Organisation
                {
                    Emplacement = emplacement,
                    Code = "ProvectaPOS",
                    IDNO = "ProvectaPOS",
                    Name = "ProvectaPOS",
                    RegisteredOn = dateTimeOffsetNow,
                    OrganisationActionType = new Flags<OrganisationActionType>(OrganisationActionType.Public)
                };
            employee = new Employee
                {
                    Person = new Person
                        {
                            Emplacement = emplacement,
                            User = new User
                                {
                                    Emplacement = emplacement,
                                    Code = "master@provectapos.com",
                                    Password = "admin",
                                },
                            FirstName = "Admin",
                            LastName = "MoneyQuest",
                            Email = "master@provectapos.com"
                        },
                    Organisation = organisation,
                    EmployeeActorType = EmployeeActorType.OperationalAdministrator,
                    IsDefault = true,
                    State = new State
                        {
                            AppliedOn = dateTimeOffsetNow,
                            IsActive = true
                        }
                };
            if (!GenericEntity.HasValue(ClientManager.Instance.Owner.EmployeeRead(employee)))
            {
                employee = ClientManager.Instance.Owner.EmployeeCreate(employee);
            }
            var person = new Person
                {
                    Emplacement = emplacement,
                    User = new User
                        {
                            Emplacement = emplacement,
                            Code = "dujacorneliu@gmail.com",
                            Password = "1",
                        },
                    FirstName = "anonymous",
                    LastName = "anonymous",
                    Email = "dujacorneliu@gmail.com"
                };
            if (!GenericEntity.HasValue(ClientManager.Instance.Owner.PersonRead(person)))
            {
                person = ClientManager.Instance.Owner.PersonCreate(person);
            }
            ClientManager.Instance.Login("master@mq.md", "admin");
            ClientManager.Instance.Login("master@provectapos.com", "admin");
            ClientManager.Instance.Login("dujacorneliu@gmail.com", "1");
            var tokens = ClientManager.Instance.Common.TokenSearch(new TokenPredicate());
            ClientManager.Instance.Login("master@provectapos.com", "admin");
            tokens = ClientManager.Instance.Common.TokenSearch(new TokenPredicate());
            ClientManager.Instance.Login("master@mq.md", "admin");
            tokens = ClientManager.Instance.Common.TokenSearch(new TokenPredicate());
            ClientManager.Instance.Login("master", "G2dxYPyhXGE");
            tokens = ClientManager.Instance.Common.TokenSearch(new TokenPredicate());
        }

        [TestMethod]
        public void TestClients()
        {
            ClientManager.Instance.Start();
            ClientManager.Instance.Login("sa", "1");
            var clients = new List<CommonClient>();
            for (var index = 0; index < 100000; index++)
            {
                var client = ClientManager.Instance.Common;
                client.TokenRead();
                clients.Add(client);
            }
        }

        [TestMethod]
        public void TestGuidEncodeDecode()
        {
            var guid = Guid.NewGuid();
            var encoded = Convert.ToBase64String(guid.ToByteArray()).Replace("/", "_").Replace("+", "-").Substring(0, 22);
            var decode = new Guid(Convert.FromBase64String(encoded.Replace("_", "/").Replace("-", "+") + "=="));
        }

        [TestMethod]
        public void TestLogin()
        {
            //ClientManager.Instance.Start("https://provecta.md/Software/ProvectaPay/", BasicHttpBindingSecurityType.Certificate);
            ClientManager.Instance.Start();
            for (var index = 0; index < 10; index++)
            {
                ClientManager.Instance.Login("Becor.User", "1");
                ClientManager.Instance.Logout();
            }
        }

        [TestMethod]
        public void TestTranslate()
        {
            //ClientManager.Instance.Start("https://provecta.md/Software/ProvectaPay/", BasicHttpBindingSecurityType.Certificate);
            ClientManager.Instance.Start();
            var translated = ClientManager.Instance.Translate("aaa", "aaaaa");
            translated = ClientManager.Instance.Translate("bbb", "bbb");
        }
        
        [TestMethod]
        public void TestMultilanguage()
        {
            ClientManager.Instance.Start();
            var multilanguage = ClientManager.Instance.Common.Multilanguage(
                new CulturePredicate(),
                new ResourcePredicate(),
                new TranslationPredicate
                    {
                        Translated = true
                    });
        }

        [TestMethod]
        public void TestTokenCulture()
        {
            ClientManager.Instance.Start();
            ClientManager.Instance.Login("sa", "1");
            var genericOutput = ClientManager.Instance.Multilanguage.CultureSearch(new CulturePredicate());
            foreach (var culture in genericOutput.Entities)
            {
                if (!culture.Equals(ClientManager.Instance.Token.Culture) &&
                    GenericEntity.HasValue(ClientManager.Instance.Token.Culture) &&
                    culture.Emplacement.Equals(ClientManager.Instance.Token.Culture.Emplacement))
                {
                    var token = ClientManager.Instance.Update(culture);
                    break;
                }
            }
        }

        [TestMethod]
        public void TestLogSearch()
        {
            ClientManager.Instance.Start();
            ClientManager.Instance.Login("sa", "1");
            var genericOutput = ClientManager.Instance.Security.LogSearch(new LogPredicate());
        }

        [TestMethod]
        public void TestGetIp()
        {
            var value = new WebClient().DownloadString("http://checkip.dyndns.org");
            var regex = new Regex(@"Current IP Address:\s(\d+.\d+.\d+.\d+)");
            var match = regex.Match(value);
            if (match.Success)
            {
                var ip = match.Groups[1].Value;
            }
        }

        [TestMethod]
        public void TestManageEmployee()
        {
            //ClientManager.Instance.Start("http://80.245.81.59:50004/ProvectaPOS.Server.Iis/");
            ClientManager.Instance.Start();
            //ClientManager.Instance.Start("http://provectapos.com:8011/");
            ClientManager.Instance.Login("master", "G2dxYPyhXGE");
            var dateTimeOffsetNow = new DateTimeOffset(2014, 1, 1, 0, 0, 0, new TimeSpan(0));
            var emplacement = new Emplacement
            {
                Code = "MoneyQuest.Central",
                Description = "MoneyQuest.Central",
                IsAdministrative = true
            };
            if (!GenericEntity.HasValue(ClientManager.Instance.Security.EmplacementRead(emplacement)))
            {
                emplacement = ClientManager.Instance.Security.EmplacementCreate(emplacement);
            }
            var organisation = new Organisation
            {
                Emplacement = emplacement,
                Code = "MoneyQuest",
                IDNO = "MoneyQuest",
                Name = "MoneyQuest",
                RegisteredOn = dateTimeOffsetNow,
                OrganisationActionType = new Flags<OrganisationActionType>(OrganisationActionType.Public)
            };
            var organisationEntity = ClientManager.Instance.Owner.OrganisationRead(organisation);
            if (GenericEntity.HasValue(organisationEntity))
            {
                GenericEntity.SetGenericEntity(organisation, organisationEntity);
                organisation = ClientManager.Instance.Owner.OrganisationUpdate(organisation);
            }
            else
            {
                organisation = ClientManager.Instance.Owner.OrganisationCreate(organisation);
            }
            var employee = new Employee
                {
                    Person = new Person
                        {
                            Emplacement = emplacement,
                            User = new User
                                {
                                    Emplacement = emplacement,
                                    Code = "master@mq.md",
                                    Password = "quest",
                                },
                            FirstName = "Admin",
                            LastName = "MoneyQuest",
                            Email = "master@mq.md"
                        },
                    Organisation = organisation,
                    EmployeeActorType = EmployeeActorType.OperationalAdministrator,
                    IsDefault = true,
                    State = new State
                        {
                            AppliedOn = dateTimeOffsetNow,
                            IsActive = true
                        }
                };
            if (!GenericEntity.HasValue(ClientManager.Instance.Owner.EmployeeRead(employee)))
            {
                employee = ClientManager.Instance.Owner.EmployeeCreate(employee);
            }
            ClientManager.Instance.Logout();
            ClientManager.Instance.Login("master@mq.md", "quest");
            var employeeSearch = ClientManager.Instance.Owner.EmployeeSearch(new EmployeePredicate());
        }

        [TestMethod]
        public void TestTokenIsExpired()
        {
            ClientManager.Instance.Start();
            var tokenIsExpired = ClientManager.Instance.Common.TokenIsExpired();
            ClientManager.Instance.Login("sa", "1");
            tokenIsExpired = ClientManager.Instance.Common.TokenIsExpired();
        }

        [TestMethod]
        public void TestGuid()
        {
            var oldGuid = Guid.NewGuid();
            var value = GenericEntity.GuidToBase64(oldGuid);
            var newGuid = GenericEntity.Base64ToGuid(value);
            value = GenericEntity.StringToBase64(" Mama mia! ");
            value = GenericEntity.Base64ToString("  " + value + "  ");
            newGuid = GenericEntity.Base64ToGuid("NmY3Y2M0YzItMTliNS1lNDExLTgwZDEtMDAxNTVkNDk3ZDI2");
        }
    }
}
