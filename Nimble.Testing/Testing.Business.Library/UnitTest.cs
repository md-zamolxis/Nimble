using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using System.Xml;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Configuration;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Business.Library.Model.Framework.Owner;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Library.Reflection;

namespace Testing.Business.Library
{
    [TestClass]
    public class UnitTest
    {
        [TestMethod]
        public void TestListSort()
        {
            var emplacementPredicate = new EmplacementPredicate
            {
                Sorts = new List<Sort>()
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
            Console.Out.WriteLine(emplacementPredicate.Order);
        }

        [TestMethod]
        public void TestEmailValidation()
        {
            Console.Out.WriteLine(GenericEntity.EmailIsValid("   ", true));
            Console.Out.WriteLine(GenericEntity.EmailIsValid("   ", false));
        }

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
            var serialized = ClientStatic.XmlSerialize(genericOutput);
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
            serialized = ClientStatic.XmlSerialize(new GenericInput<Emplacement, EmplacementPredicate>
            {
                Entity = new Emplacement
                {
                    Code = "Nimble.Framework",
                    CultureId = Guid.NewGuid()
                },
                Predicate = emplacementPredicate
            });
        }

        [TestMethod]
        public void TestSerializeDeserializeXml()
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
            var serialized = ClientStatic.XmlSerialize(emplacement);
            Console.Out.WriteLine(serialized);
            emplacement = ClientStatic.XmlDeserialize<Emplacement>(serialized);
            Console.Out.WriteLine(emplacement.Code);
        }

        [TestMethod]
        public void TestGenericTypesManager()
        {
            var typeDeclaratorManager = new TypeDeclaratorManager();
            var typeDeclarator = typeDeclaratorManager.Get(ClientStatic.Employee);
        }

        [TestMethod]
        public void TestGenericConfiguration()
        {
            var clientConfiguration = new ClientConfiguration(XmlReader.Create(AppDomain.CurrentDomain.SetupInformation.ConfigurationFile));
        }

        [TestMethod]
        public void TestRegex()
        {
            //IDNP
            Console.WriteLine(Regex.Match("0123456789012", @"^\d{13}$", RegexOptions.IgnoreCase).Success);
        }

        [TestMethod]
        public void TestDecimalNullable()
        {
            decimal? sum = null;
            decimal value = 13.8M;
            sum += value;
            Console.WriteLine(sum);
        }

        [TestMethod]
        public void TestEnumGetValues()
        {
            var iisStateTypes = ClientStatic.GetEnumValues<IisStateType>();
        }

        [TestMethod]
        public void TestResourceValidate()
        {
            var resource = new Resource
            {
                Code = @"
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent dapibus malesuada ultrices. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Mauris at sodales leo. Nam lobortis nisl eget diam aliquam egestas. Donec quis nibh tellus, et tincidunt felis. Sed vitae tellus urna, ultrices scelerisque mauris. Proin a malesuada justo. Duis consectetur nulla vitae augue sollicitudin laoreet. Duis ut orci a mauris auctor scelerisque quis a nisl. Quisque fringilla sodales lacus, ac interdum lectus faucibus vitae. Nunc id sem mattis sapien scelerisque pellentesque quis nec lacus.

Ut quis ligula magna, eget posuere sem. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Curabitur a neque ac ligula sodales ullamcorper a et diam. Quisque hendrerit facilisis pharetra. Phasellus tempor scelerisque porttitor. Suspendisse potenti. Morbi nibh mauris, venenatis ut sagittis nec, semper sit amet purus. Aliquam erat volutpat. Nunc nisl sem, rhoncus sed tristique sit amet, volutpat vel neque.

Vestibulum quam mi, sollicitudin sit amet tempus sed, suscipit at erat. In sodales, enim vel tempus vehicula, magna tortor tristique nisl, ac lobortis lacus tellus ut arcu. Suspendisse vel purus ac turpis cursus consequat. Cras velit tortor, dictum non aliquam at, malesuada ac orci. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec ante massa, faucibus quis vestibulum in, aliquam eget urna. In enim mauris, imperdiet quis ultrices et, euismod vel eros. Ut eu nisl eu metus venenatis adipiscing. Vivamus et elementum leo. Sed eu diam nibh, nec scelerisque ante. Fusce lobortis eros a nisi scelerisque pharetra. Nam pretium placerat turpis, a commodo tellus bibendum vitae. Phasellus imperdiet, tellus ac porta auctor, quam purus pulvinar augue, sed imperdiet ligula velit id turpis.

Curabitur dapibus, odio eu condimentum euismod, ante ligula accumsan justo, et pretium turpis metus vitae metus. Vestibulum ligula ante, imperdiet id rutrum at, hendrerit non metus. Sed viverra lacinia nisl, at rutrum nunc facilisis nec. Nam ut consectetur sapien. Phasellus eleifend vulputate semper. Donec ante augue, sagittis et dictum eu, rutrum nec sapien. Quisque nisi justo, blandit eget congue a, venenatis sed arcu. Sed vestibulum fermentum venenatis. Nam nec justo ligula. Donec elementum diam non nulla accumsan sed ultricies urna suscipit.

Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Maecenas sed massa at tellus mattis feugiat. Proin lacus orci, pretium in varius nec, pulvinar vel mauris. Mauris dapibus massa vel dolor eleifend aliquet. Ut pulvinar est a lorem condimentum sollicitudin. Vestibulum blandit velit in magna posuere ultrices. Nunc bibendum blandit leo eu aliquet. Pellentesque id fermentum libero.
                                   "
            };
            var faultExceptionDetail = resource.Validate();
        }

        [TestMethod]
        public void TestFaultExceptionDetail()
        {
            var faultExceptionDetailFrom = new FaultExceptionDetail("User [{0}] do not has permission [{1}] on application [{2}].", "sa", PermissionType.EmplacementSearch, "Provecta.Servce.Iis");
            var faultException = FaultExceptionDetail.Create(faultExceptionDetailFrom);
            var faultExceptionDetailTo = FaultExceptionDetail.Create(faultException);
        }

        [TestMethod]
        public void TestParse()
        {
            decimal value;
            var parse = decimal.TryParse(null, out value);
            parse = decimal.TryParse(string.Empty, out value);
            parse = decimal.TryParse("     ", out value);
        }

        [TestMethod]
        public void TestKeyValue()
        {
            var keyValues = KeyValue.Create(new List<string>
            {
                "a",
                "b",
                "a",
                "A",
                "B"
            });
            var keyValue = KeyValue.Find(ref keyValues, "a");
            keyValue = KeyValue.Find(ref keyValues, "C");
        }

        [TestMethod]
        public void TestDateInterval()
        {
            var type = typeof(DateIntervalType);
            foreach (var dateIntervalType in Enum.GetValues(type))
            {
                var dateInterval = new DateInterval((DateIntervalType) Enum.Parse(type, dateIntervalType.ToString()));
            }
        }

        [TestMethod]
        public void TestPager()
        {
            var pager = new Pager
            {
                Index = 0,
                Size = 10,
                StartLag = 0,
                Count = 10,
                Number = 14
            };
            var pages = pager.Pages;
        }

        [TestMethod]
        public void TestGetCoordinates()
        {
            var coordinates = GenericEntity.GetCoordinates("1010.105405,10405.4545");
        }

        [TestMethod]
        public void TestFlags()
        {
            var flags = new Flags<OrganisationActionType>(OrganisationActionType.Public | OrganisationActionType.Framework);
            var number = flags.Number;
            var line = flags.Line;
            flags = new Flags<OrganisationActionType>("101");
            flags = new Flags<OrganisationActionType>("0101");
            flags = new Flags<OrganisationActionType>("123");
            var value = Convert.ToInt32(null);
        }
    }
}