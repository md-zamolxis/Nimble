using System;
using System.Collections.Generic;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Geolocation;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Business.Library.Model.Framework.Owner;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Engine.Common;
using Nimble.DataAccess.MsSql2008.Framework;
using Nimble.Business.Engine.Core;
using Nimble.Business.Service.Core;

namespace Testing.DataAccess.MsSql2008
{
    [TestClass]
    public class UnitTest
    {
        [TestMethod]
        public void TestSerializeXml()
        {
            var emplacement = new Emplacement
                                  {
                                      Id = Guid.NewGuid(),
                                      Code = "<Central/>",
                                      Description = "Central",
                                      IsAdministrative = true,
                                      Version = new byte[] {0, 1, 2, 3, 4, 5, 6, 7},
                                      CultureId = Guid.NewGuid()
                                  };
            var serialized = EngineStatic.PortableXmlSerialize(emplacement);
            var genericOutput = new GenericOutput<Emplacement>
                                    {
                                        Entity = emplacement,
                                        Entities = new List<Emplacement>
                                                       {
                                                           emplacement
                                                       },
                                        Pager = new Pager
                                                    {
                                                        Index = 3,
                                                        Size = 55
                                                    }
                                    };
            serialized = EngineStatic.PortableXmlSerialize(genericOutput);
            var emplacementPredicate = new EmplacementPredicate
                                           {
                                               Sorts = new List<Sort>(),
                                               Emplacements = new Criteria<List<Emplacement>>(new List<Emplacement>())
                                           };
            emplacementPredicate.Sorts.Add(new Sort
                                               {
                                                   Index = 2,
                                                   Name = "EmplacementDescription",
                                                   SortType = SortType.Ascending
                                               });
            emplacementPredicate.Sorts.Add(new Sort
                                               {
                                                   Index = 0,
                                                   Name = "EmplacementCode",
                                                   SortType = SortType.Ascending
                                               });
            emplacementPredicate.Sorts.Add(new Sort
                                               {
                                                   Index = 1,
                                                   Name = "EmplacementId",
                                                   SortType = SortType.Ascending
                                               });
            emplacementPredicate.Emplacements.Value.Add(new Emplacement
                                                            {
                                                                Code = "Nimble"
                                                            });
            emplacementPredicate.Emplacements.Value.Add(new Emplacement
                                                            {
                                                                Id = Guid.NewGuid(),
                                                                Description = "Testing XML serialization"
                                                            });
            serialized = EngineStatic.PortableXmlSerialize(new GenericInput<Emplacement, EmplacementPredicate>
                                                       {
                                                           Entity = new Emplacement
                                                                        {
                                                                            Code = "Nimble.Framework",
                                                                            CultureId = Guid.NewGuid()
                                                                        },
                                                           Predicate = emplacementPredicate
                                                       });
            var organisationPredicate = new OrganisationPredicate
                                            {
                                                OrganisationActionType = new Criteria<Flags<OrganisationActionType>>(new Flags<OrganisationActionType>(OrganisationActionType.Public))
                                            };
            serialized = EngineStatic.PortableXmlSerialize(organisationPredicate);
        }

        [TestMethod]
        public void TestEmplacement()
        {
            Kernel.Instance.Start();
            Kernel.Instance.CheckConnections();
            var emplacement = new Emplacement
                                  {
                                      Code = "<Central/>",
                                      Description = "Central",
                                      IsAdministrative = true,
                                      Version = new byte[] {0, 1, 2, 3, 4, 5, 6, 7},
                                      CultureId = Guid.NewGuid()
                                  };
            var genericInput = new GenericInput<Emplacement, EmplacementPredicate>
                                   {
                                       PermissionType = PermissionType.EmplacementSearch,
                                       Predicate = new EmplacementPredicate
                                                       {
                                                           Codes = new Criteria<List<string>>(new List<string>{"Nimble%"}),
                                                           Emplacements = new Criteria<List<Emplacement>>(new List<Emplacement>{new Emplacement{Code = "Nimble.Central"}}),
                                                           Pager = new Pager
                                                                       {
                                                                           Index = 0,
                                                                           Size = 2
                                                                       }
                                                       }
                                   };
            var serialized = EngineStatic.PortableXmlSerialize(genericInput);
            var emplacementEntity = SecuritySql.Instance.EmplacementRead(emplacement);
            if (!GenericEntity.HasValue(emplacementEntity))
            {
                emplacementEntity = SecuritySql.Instance.EmplacementCreate(emplacement);
            }
            emplacementEntity.Description = "Testing Emplacement";
            emplacementEntity = SecuritySql.Instance.EmplacementUpdate(emplacementEntity);
            var genericOutput = SecuritySql.Instance.EmplacementSearch(genericInput);
            var deleted = SecuritySql.Instance.EmplacementDelete(emplacementEntity);
            emplacement.Code = null;
            try
            {
                emplacementEntity = SecuritySql.Instance.EmplacementCreate(emplacement);
            }
            catch (Exception exception)
            {
                Console.WriteLine(exception.Message);
            }
            Kernel.Instance.End();
        }

        [TestMethod]
        public void TestCulture()
        {
            Kernel.Instance.Start();
            Kernel.Instance.CheckConnections();
            var emplacement = new Emplacement
                                  {
                                      Code = "<Central/>",
                                      Description = "Central",
                                      IsAdministrative = true,
                                      Version = new byte[] {0, 1, 2, 3, 4, 5, 6, 7},
                                      CultureId = Guid.NewGuid()
                                  };
            var genericInput = new GenericInput<Culture, CulturePredicate>
                                   {
                                       PermissionType = PermissionType.CultureSearch,
                                       Predicate = new CulturePredicate
                                                       {
                                                           EmplacementPredicate = new EmplacementPredicate
                                                                                      {
                                                                                          Codes = new Criteria<List<string>>(new List<string>{"<Central/>"}),
                                                                                          Pager = new Pager
                                                                                                      {
                                                                                                          Index = 1,
                                                                                                          Size = 2
                                                                                                      }
                                                                                      },
                                                           Pager = new Pager
                                                                       {
                                                                           Index = 0,
                                                                           Size = 2
                                                                       }
                                                       }
                                   };
            var emplacementEntity = SecuritySql.Instance.EmplacementRead(emplacement);
            if (!GenericEntity.HasValue(emplacementEntity))
            {
                emplacementEntity = SecuritySql.Instance.EmplacementCreate(emplacement);
            }
            var culture = new Culture
                              {
                                  Emplacement = emplacement,
                                  Code = "en",
                                  Name = "English"
                              };
            var cultureEntity = MultilanguageSql.Instance.CultureRead(culture);
            if (!GenericEntity.HasValue(cultureEntity))
            {
                cultureEntity = MultilanguageSql.Instance.CultureCreate(culture);
            }
            cultureEntity.Name = "English (UK)";
            cultureEntity = MultilanguageSql.Instance.CultureUpdate(cultureEntity);
            try
            {
                SecuritySql.Instance.EmplacementDelete(emplacementEntity);
            }
            catch (Exception exception)
            {
                Console.WriteLine(exception.Message);
            }
            var genericOutput = MultilanguageSql.Instance.CultureSearch(genericInput);
            var deleted = MultilanguageSql.Instance.CultureDelete(cultureEntity);
            deleted = SecuritySql.Instance.EmplacementDelete(emplacementEntity);
            Kernel.Instance.End();
        }

        [TestMethod]
        public void TestRole()
        {
            Kernel.Instance.Start();
            Kernel.Instance.CheckConnections();
            var emplacement = new Emplacement
                                  {
                                      Code = "Nimble.Global"
                                  };
            var application = new Application
                                  {
                                      Code = "Nimble.Server.Iis"
                                  };
            var permission1 = new Permission
                                 {
                                     Application = application,
                                     Code = "Permission1",
                                     Category = "Service"
                                 };
            var permissionEntity = SecuritySql.Instance.PermissionRead(permission1);
            permission1 = GenericEntity.HasValue(permissionEntity) ? permissionEntity : SecuritySql.Instance.PermissionCreate(permission1);
            var permission2 = new Permission
                                  {
                                      Application = application,
                                      Code = "Permission2",
                                      Category = "Service"
                                  };
            permissionEntity = SecuritySql.Instance.PermissionRead(permission2);
            permission2 = GenericEntity.HasValue(permissionEntity) ? permissionEntity : SecuritySql.Instance.PermissionCreate(permission2);
            var permission3 = new Permission
                                  {
                                      Application = application,
                                      Code = "Permission3",
                                      Category = "Service"
                                  };
            permissionEntity = SecuritySql.Instance.PermissionRead(permission3);
            permission3 = GenericEntity.HasValue(permissionEntity) ? permissionEntity : SecuritySql.Instance.PermissionCreate(permission3);
            var role1 = new Role
                           {
                               Emplacement = emplacement,
                               Application = application,
                               Code = "Role1",
                               Permissions = new List<Permission>()
                           };
            var roleEntity = SecuritySql.Instance.RoleRead(role1);
            if (GenericEntity.HasValue(roleEntity))
            {
                roleEntity.Description = "Testing Role";
                role1 = SecuritySql.Instance.RoleUpdate(roleEntity);
                var permissionPredicate = new PermissionPredicate
                                              {
                                                  RolePredicate = new RolePredicate
                                                                      {
                                                                          Roles = new Criteria<List<Role>>(new List<Role>{role1})
                                                                      }
                                              };
                role1.Permissions = SecuritySql.Instance.PermissionSearch(new GenericInput<Permission, PermissionPredicate>
                                                                              {
                                                                                  Predicate = permissionPredicate
                                                                              }).Entities;
                //var index = role1.Permissions.FindIndex(item => item.Code.Equals("Permission1"));
                //role1.Permissions.RemoveAt(index);
                //role1.Permissions.Add(permission3);
                role1.Permissions.Clear();
                role1 = SecuritySql.Instance.RoleUpdate(role1);
                role1.Permissions = SecuritySql.Instance.PermissionSearch(new GenericInput<Permission, PermissionPredicate>
                                                                              {
                                                                                  Predicate = permissionPredicate
                                                                              }).Entities;
            }
            else
            {
                role1.Permissions = new List<Permission>
                                        {
                                            permission1,
                                            permission2
                                        };
                role1 = SecuritySql.Instance.RoleCreate(role1);
            }

            var emplacementPredicate = new EmplacementPredicate
                                           {
                                               Codes = new Criteria<List<string>>(new List<string>{"Nimble%"})
                                           };
            var applicationPredicate = new ApplicationPredicate
                                           {
                                               Codes = new Criteria<List<string>>(new List<string>{"Nimble%"})
                                           };
            var deleted = SecuritySql.Instance.RoleDelete(role1);
            Kernel.Instance.End();
        }

        [TestMethod]
        public void TestSource()
        {
            Kernel.Instance.Start();
            Kernel.Instance.CheckConnections();
            var sourcePredicate = new SourcePredicate
                                      {
                                          Pager = new Pager
                                                      {
                                                          Index = 2,
                                                          Size = 3
                                                      },
                                          Codes = new Criteria<List<string>>
                                                      {
                                                          Value = new List<string>
                                                                      {
                                                                          "%Blocks%"
                                                                      }
                                                      }
                                      };
            var genericOutput = GeolocationSql.Instance.SourceSearch(new GenericInput<Source, SourcePredicate>
                                                                         {
                                                                             Predicate = sourcePredicate
                                                                         });
            Kernel.Instance.End();
        }

        [TestMethod]
        public void TestBlock()
        {
            Kernel.Instance.Start();
            Kernel.Instance.CheckConnections();
            var blockPredicate = new BlockPredicate
                                     {
                                         Pager = new Pager
                                                     {
                                                         Index = 20,
                                                         Size = 10
                                                     },
                                         LocationPredicate = new LocationPredicate
                                                                 {
                                                                     Countries = new Criteria<List<string>>
                                                                                     {
                                                                                         Value = new List<string>
                                                                                                     {
                                                                                                         "MD"
                                                                                                     }
                                                                                     }
                                                                 }
                                     };
            var genericOutput = GeolocationSql.Instance.BlockSearch(new GenericInput<Block, BlockPredicate>
                                                                        {
                                                                            Predicate = blockPredicate
                                                                        });
            var block = GeolocationSql.Instance.BlockRead(new Block
                                                              {
                                                                  IpDataFrom = "80.245.81.59"
                                                              });
            Kernel.Instance.End();
        }

        [TestMethod]
        public void TestDatabaseSize()
        {
            Kernel.Instance.Start();
            Kernel.Instance.CheckConnections();
            var size = MaintenanceSql.Instance.DatabaseSize();
            Kernel.Instance.End();
        }

        [TestMethod]
        public void TestEncryptMd5()
        {
            var encrypted = EngineStatic.EncryptMd5(null);
        }
    }
}
