using System;
using System.Collections.Generic;
using System.Xml;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Multicurrency;
using Nimble.Business.Library.Model.Framework.Owner;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Logic.Framework;
using Nimble.Business.Engine.Core;
using Nimble.Business.Service.Core;

namespace Testing.Business.Logic
{
    [TestClass]
    public class UnitTest
    {
        [TestMethod]
        public void TestCommonStart()
        {
            Kernel.Instance.Start();
            Kernel.Instance.CheckConnections();
            CommonLogic.Start();
            Kernel.Instance.End();
        }

        [TestMethod]
        public void TestEmployee()
        {
            Kernel.Instance.Start();
            Kernel.Instance.CheckConnections();
            //CommonLogic.Start();
            var token = CommonLogic.InstanceCheck(PermissionType.Public).Login("sa", "1");
            var dateTimeOffsetNow = DateTimeOffset.Now;
            var emplacement = new Emplacement
            {
                Code = "Nimble.Central"
            };
            var organisation = new Organisation
            {
                Emplacement = emplacement,
                Code = "Piv&Mit",
                IDNO = "Piv&Mit",
                Name = "Piv&Mit",
                RegisteredOn = dateTimeOffsetNow,
                OrganisationActionType = new Flags<OrganisationActionType>(OrganisationActionType.Public)
            };
            var organisationEntity = OwnerLogic.InstanceCheck(PermissionType.OrganisationRead).OrganisationRead(organisation);
            organisation = GenericEntity.HasValue(organisationEntity) ? organisationEntity : OwnerLogic.InstanceCheck(PermissionType.OrganisationCreate).OrganisationCreate(organisation);
            var employee = new Employee
            {
                Person = new Person
                {
                    Emplacement = emplacement,
                    User = new User
                    {
                        Emplacement = emplacement,
                        Code = "Piv&Mit.User",
                        Password = "1"
                    },
                    Code = "Piv&Mit.Person",
                    IDNP = "Piv&Mit.Person",
                    FirstName = "Piv&Mit.Person",
                    LastName = "Piv&Mit.Person",
                    Patronymic = "Piv&Mit.Person",
                    BornOn = dateTimeOffsetNow.AddYears(-20),
                    PersonSexType = PersonSexType.Male
                },
                Organisation = organisation,
                Function = "Piv&Mit.Employee",
                EmployeeActorType = EmployeeActorType.OperationalViewer,
                IsDefault = true,
                State = Kernel.Instance.StateGenerate(dateTimeOffsetNow.AddYears(-1), true)
            };
            var applications = SecurityLogic.InstanceCheck(PermissionType.ApplicationSearch).ApplicationSearch(new ApplicationPredicate()).Entities;
            foreach (var application in applications)
            {
                var account = SecurityLogic.InstanceCheck(PermissionType.AccountRead).AccountRead(new Account
                {
                    User = employee.Person.User,
                    Application = application
                });
            }
            var employeeEntity = OwnerLogic.InstanceCheck(PermissionType.EmployeeRead).EmployeeRead(employee);
            if (GenericEntity.HasValue(employeeEntity))
            {
                if (GenericEntity.HasValue(employeeEntity.Person.User))
                {
                    GenericEntity.SetGenericEntity(employee.Person.User, employeeEntity.Person.User);
                }
                GenericEntity.SetGenericEntity(employee.Person, employeeEntity.Person);
                GenericEntity.SetGenericEntity(employee, employeeEntity);
                employee = OwnerLogic.InstanceCheck(PermissionType.EmployeeUpdate).EmployeeUpdate(employee);
            }
            else
            {
                employee = OwnerLogic.InstanceCheck(PermissionType.EmployeeCreate).EmployeeCreate(employee);
            }
            Kernel.Instance.End();
        }

        [TestMethod]
        public void TestTokenSearch()
        {
            Kernel.Instance.Start();
            Kernel.Instance.CheckConnections();
            var token1 = CommonLogic.InstanceCheck(PermissionType.Public).Login("sa", "1");
            var token2 = CommonLogic.InstanceCheck(PermissionType.Public).Login("Becor.User", "1");
            var tokenPredicate = new TokenPredicate
            {
                LastUsedOn = new Criteria<DateInterval>(new DateInterval
                {
                    IncludeTime = true,
                    DateTo = DateTimeOffset.Now
                }),
                AccountPredicate = new AccountPredicate
                {
                    UserPredicate = new UserPredicate
                    {
                        Codes = new Criteria<List<string>>(new List<string>
                        {
                            "Becor%"
                        })
                    }
                }
            };
            var tokenSearch = CommonLogic.InstanceCheck(PermissionType.TokenSearch).TokenSearch(tokenPredicate);
            Kernel.Instance.End();
        }

        [TestMethod]
        public void TestMulticurrency()
        {
            Kernel.Instance.Start();
            Kernel.Instance.CheckConnections();
            //CommonLogic.Start();
            CommonLogic.InstanceCheck(PermissionType.Public).Login("sa", "1");
            var emplacement = new Emplacement
            {
                Code = "Nimble.Central",
                IsAdministrative = true
            };
            var emplacementEntity = SecurityLogic.InstanceCheck(PermissionType.EmplacementRead).EmplacementRead(emplacement);
            if (!GenericEntity.HasValue(emplacementEntity))
            {
                emplacementEntity = SecurityLogic.InstanceCheck(PermissionType.EmplacementCreate).EmplacementCreate(emplacement);
            }
            var organisation = new Organisation
            {
                Emplacement = emplacementEntity,
                Code = "Nimble",
                IDNO = "Nimble",
                Name = "Nimble",
                OrganisationActionType = new Flags<OrganisationActionType>(OrganisationActionType.Public),
                RegisteredOn = DateTimeOffset.Now
            };
            var organisationEntity = OwnerLogic.InstanceCheck(PermissionType.OrganisationRead).OrganisationRead(organisation);
            if (!GenericEntity.HasValue(organisationEntity))
            {
                organisationEntity = OwnerLogic.InstanceCheck(PermissionType.OrganisationCreate).OrganisationCreate(organisation);
            }
            var currencyOutput = MulticurrencyLogic.InstanceCheck(PermissionType.CurrencySearch).CurrencySearch(new CurrencyPredicate
            {
                OrganisationPredicate = new OrganisationPredicate
                {
                    Organisations = new Criteria<List<Organisation>>(new List<Organisation>
                    {
                        organisationEntity
                    })
                }
            });
            var currency = new Currency
            {
                Organisation = organisationEntity,
                Code = "UAH",
                IsDefault = true,
                Rates = new List<Rate>
                {
                    new Rate
                    {
                        CurrencyFrom = new Currency {Code = "EUR"},
                        CurrencyTo = new Currency {Code = "GBP"},
                        Value = 0.79M
                    },
                    new Rate
                    {
                        CurrencyFrom = new Currency {Code = "EUR"},
                        CurrencyTo = new Currency {Code = "MDL"},
                        Value = 15.63M
                    },
                    new Rate
                    {
                        CurrencyFrom = new Currency {Code = "GBP"},
                        CurrencyTo = new Currency {Code = "EUR"},
                        Value = 1.27M
                    },
                    new Rate
                    {
                        CurrencyFrom = new Currency {Code = "MDL"},
                        CurrencyTo = new Currency {Code = "UAH"},
                        Value = 1.58M
                    }
                }
            };
            foreach (var rate in currency.Rates)
            {
                rate.CurrencyFrom.Organisation = rate.CurrencyTo.Organisation = organisationEntity;
            }
            var currencyEntity = MulticurrencyLogic.InstanceCheck(PermissionType.CurrencyRead).CurrencyRead(currency);
            if (GenericEntity.HasValue(currencyEntity))
            {
                var deleted = MulticurrencyLogic.InstanceCheck(PermissionType.CurrencyDelete).CurrencyDelete(currencyEntity);
            }
            else
            {
                currencyEntity = MulticurrencyLogic.InstanceCheck(PermissionType.CurrencyCreate).CurrencyCreate(currency);
            }
            var trade = new Trade
            {
                Organisation = organisationEntity,
                Rates = new List<Rate>
                {
                    new Rate
                    {
                        CurrencyFrom = new Currency {Code = "EUR"},
                        CurrencyTo = new Currency {Code = "GBP"},
                        Value = 0.79M
                    },
                    new Rate
                    {
                        CurrencyFrom = new Currency {Code = "EUR"},
                        CurrencyTo = new Currency {Code = "MDL"},
                        Value = 15.63M
                    },
                    new Rate
                    {
                        CurrencyFrom = new Currency {Code = "GBP"},
                        CurrencyTo = new Currency {Code = "EUR"},
                        Value = 1.27M
                    },
                },
                AppliedOn = DateTimeOffset.Now
            };
            foreach (var rate in trade.Rates)
            {
                rate.CurrencyFrom.Organisation = rate.CurrencyTo.Organisation = organisationEntity;
            }
            trade = MulticurrencyLogic.InstanceCheck(PermissionType.TradeCreate).TradeCreate(trade);
            Kernel.Instance.End();
        }

        [TestMethod]
        public void TestGenericConfiguration()
        {
            var clientConfiguration = new ServerConfiguration(XmlReader.Create(AppDomain.CurrentDomain.SetupInformation.ConfigurationFile));
        }

        [TestMethod]
        public void TestOrganisationSearch()
        {
            Kernel.Instance.Start();
            Kernel.Instance.CheckConnections();
            CommonLogic.InstanceCheck(PermissionType.Public).Login("sa", "1");
            var organisations = OwnerLogic.InstanceCheck(PermissionType.Public).OrganisationSearch(new OrganisationPredicate());
        }
    }
}