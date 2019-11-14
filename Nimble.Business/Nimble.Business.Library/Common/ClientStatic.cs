#region Usings

using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Runtime.Serialization;
using System.Text;
using System.Xml;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.DataTransport;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Common;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Business.Library.Model.Framework.Notification;
using Nimble.Business.Library.Model.Framework.Owner;
using Nimble.Business.Library.Model.Framework.Security;

#endregion Usings

namespace Nimble.Business.Library.Common
{
    public class ClientStatic
    {
        #region Public

        #region Fields

        public static readonly Type ValueString = typeof(string);
        public static readonly Type ValueInt = typeof(int);
        public static readonly Type ValueDecimal = typeof(decimal);
        public static readonly Type ValueByte = typeof(byte);

        public static readonly Type StructureDateTimeOffset = typeof(DateTimeOffset);
        public static readonly Type StructureGuid = typeof(Guid);

        public static readonly Type Nullable = typeof(Nullable<>);
        public static readonly Type NullableInt = typeof(int?);
        public static readonly Type NullableDecimal = typeof(decimal?);
        public static readonly Type NullableDateTimeOffset = typeof(DateTimeOffset?);
        public static readonly Type NullableGuid = typeof(Guid?);

        public static readonly Type FaultExceptionDetailType = typeof(FaultExceptionDetailType);
        public static readonly Type PermissionType = typeof(PermissionType);
        public static readonly Type GenericEntity = typeof(GenericEntity);
        public static readonly Type GenericPredicate = typeof(GenericPredicate);
        public static readonly Type Culture = typeof(Culture);
        public static readonly Type Resource = typeof(Resource);
        public static readonly Type Translation = typeof(Translation);
        public static readonly Type Flags = typeof(Flags<>);
        public static readonly Type Profile = typeof(Profile);
        public static readonly Type Property = typeof(Property);
        public static readonly Type Person = typeof(Person);
        public static readonly Type Mark = typeof(Mark);
        public static readonly Type Employee = typeof(Employee);
        public static readonly Type FieldCategoryType = typeof(FieldCategoryType);
        public static readonly Type MarkResume = typeof(MarkResume);
        public static readonly Type Log = typeof(Log);
        public static readonly Type LogActionType = typeof(LogActionType);
        public static readonly Type NotificationType = typeof(NotificationType);

        #endregion Fields

        #region Methods

        #region Common

        public static int Compare(object item1, object item2)
        {
            var compare = 0;
            if (!Equals(item1, null) &&
                !Equals(item2, null) &&
                item1.GetType() == item2.GetType())
            {
                var type = item1.GetType();
                if (type == ValueString)
                {
                    compare = string.Compare((string) item1, (string) item2, StringComparison.OrdinalIgnoreCase);
                }
                if (type == StructureDateTimeOffset ||
                    type == NullableDateTimeOffset)
                {
                    compare = DateTimeOffset.Compare((DateTimeOffset) item1, (DateTimeOffset) item2);
                }
                if (type == ValueInt ||
                    type == NullableInt)
                {
                    compare = decimal.Compare((int) item1, (int) item2);
                }
                if (type == ValueDecimal ||
                    type == NullableDecimal)
                {
                    compare = decimal.Compare((decimal) item1, (decimal) item2);
                }
            }
            else if (Equals(item1, null) &&
                     Equals(item2, null))
            {
                compare = 0;
            }
            else if (!Equals(item1, null) &&
                     Equals(item2, null))
            {
                compare = 1;
            }
            else
            {
                compare = -1;
            }
            return compare;
        }

        public static void ApplyLikeOperator(List<string> items)
        {
            if (items == null) return;
            for (var index = 0; index < items.Count; index++)
            {
                if (items[index] == null) continue;
                items[index] = items[index].Trim();
                if (string.IsNullOrEmpty(items[index])) continue;
                items[index] = Constants.PERCENT + items[index] + Constants.PERCENT;
            }
        }

        public static string Transpose(string text, string search, string replace)
        {
            var transposed = text;
            if (!string.IsNullOrEmpty(text) &&
                !string.IsNullOrEmpty(search))
            {
                for (var index = 0; index < search.Length; index++)
                {
                    var searched = search[index].ToString();
                    var replaced = string.Empty;
                    if (!string.IsNullOrEmpty(replace) &&
                        replace.Length > index)
                    {
                        replaced = replace[index].ToString();
                    }
                    transposed = transposed.Replace(searched, replaced);
                }
            }
            return transposed;
        }

        public static T XmlClone<T>(T entity)
        {
            return (T) XmlDeserialize(XmlSerialize(entity), typeof(T));
        }

        #endregion Common

        #region Serialization

        public static string XmlSerialize(object value)
        {
            var stringBuilder = new StringBuilder();
            var xmlWriterSettings = new XmlWriterSettings
            {
                OmitXmlDeclaration = true,
                Indent = true
            };
            using (var xmlWriter = XmlWriter.Create(stringBuilder, xmlWriterSettings))
            {
                var dataContractSerializer = new DataContractSerializer(value.GetType());
                dataContractSerializer.WriteObject(xmlWriter, value);
            }
            return stringBuilder.ToString();
        }

        public static object XmlDeserialize(string value, Type type)
        {
            var stringReader = new StringReader(value);
            using (var xmlReader = XmlReader.Create(stringReader))
            {
                var dataContractSerializer = new DataContractSerializer(type);
                return dataContractSerializer.ReadObject(xmlReader);
            }
        }

        public static T XmlDeserialize<T>(string value)
        {
            return (T) XmlDeserialize(value, typeof(T));
        }

        #endregion Serialization

        #region Reflection

        public static T GetCustomAttribute<T>(object[] attributes)
        {
            var customAttribute = default(T);
            if (attributes != null)
            {
                foreach (var attribute in attributes)
                {
                    if (!(attribute is T)) continue;
                    customAttribute = (T) attribute;
                    break;
                }
            }
            return customAttribute;
        }

        public static T GetCustomAttribute<T>(PropertyInfo propertyInfo, bool inherit)
        {
            return propertyInfo == null ? default(T) : GetCustomAttribute<T>(propertyInfo.GetCustomAttributes(typeof(T), inherit));
        }

        public static T GetCustomAttribute<T>(Type type, bool inherit)
        {
            return type == null ? default(T) : GetCustomAttribute<T>(type.GetCustomAttributes(typeof(T), inherit));
        }

        public static T GetCustomAttribute<T>(FieldInfo fieldInfo, bool inherit)
        {
            return fieldInfo == null ? default(T) : GetCustomAttribute<T>(fieldInfo.GetCustomAttributes(typeof(T), inherit));
        }

        public static Dictionary<FieldInfo, T> GetCustomAttributes<T>(Type type, BindingFlags? bindingFlags, bool inherit)
        {
            var customAttributes = new Dictionary<FieldInfo, T>();
            var fieldInfos = bindingFlags == null ? type.GetFields() : type.GetFields(bindingFlags.Value);
            foreach (var fieldInfo in fieldInfos)
            {
                var customAttribute = GetCustomAttribute<T>(fieldInfo, inherit);
                customAttributes.Add(fieldInfo, customAttribute);
            }
            return customAttributes;
        }

        public static object CreateInstance(Type type)
        {
            object value = null;
            var constructorInfos = type.GetConstructors();
            foreach (var constructorInfo in constructorInfos)
            {
                if (constructorInfo.GetParameters().Length != 0) continue;
                value = Activator.CreateInstance(type);
                break;
            }
            return value;
        }

        public static List<E> GetEnumValues<E>()
        {
            List<E> enumValues = null;
            var type = typeof(E);
            if (type.IsEnum)
            {
                enumValues = new List<E>();
                var fields = type.GetFields(BindingFlags.Public | BindingFlags.Static);
                foreach (var field in fields)
                {
                    enumValues.Add((E) Enum.Parse(type, field.Name, false));
                }
            }
            return enumValues;
        }

        public static Dictionary<E, T> GetEnumAttributePairs<E, T>(List<E> enums)
        {
            Dictionary<E, T> enumAttributePairs = null;
            var type = typeof(E);
            if (type.IsEnum)
            {
                enumAttributePairs = new Dictionary<E, T>();
                foreach (var enumValue in enums)
                {
                    if (enumAttributePairs.ContainsKey(enumValue)) continue;
                    var customAttribute = GetCustomAttribute<T>(type.GetField(enumValue.ToString()), true);
                    if (customAttribute == null) continue;
                    enumAttributePairs.Add(enumValue, customAttribute);
                }
            }
            return enumAttributePairs;
        }

        public static Dictionary<E, T> GetEnumAttributePairs<E, T>()
        {
            return GetEnumAttributePairs<E, T>(GetEnumValues<E>());
        }

        public static string HexHashCode(string value)
        {
            return string.Format("{0:X}", value.GetHashCode());
        }

        #endregion Reflection

        #endregion Methods

        #endregion Public
    }
}