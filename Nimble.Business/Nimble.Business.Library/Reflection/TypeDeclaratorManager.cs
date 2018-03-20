#region Using

using System;
using System.Collections.Generic;
using System.Reflection;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model;

#endregion Using

namespace Nimble.Business.Library.Reflection
{
    public class TypeDeclaratorManager
    {
        #region Private Members

        #region Properties

        private readonly object semaphore = new object();
        private readonly Dictionary<Type, TypeDeclarator> typeDeclarators = new Dictionary<Type, TypeDeclarator>();
        private readonly Dictionary<KeyValue, PropertyDeclarator> databaseColumns = new Dictionary<KeyValue, PropertyDeclarator>();

        #endregion Properties

        #endregion Private Members

        #region Public Members

        #region Methods

        public TypeDeclaratorManager()
        {
            var types = Assembly.GetExecutingAssembly().GetTypes();
            foreach (var type in types)
            {
                if (!type.IsClass ||
                    type.IsNotPublic ||
                    type.BaseType != ClientStatic.GenericEntity) continue;
                Get(type);
            }
            foreach (var typeDeclarator in typeDeclarators)
            {
                GetTreePropertyDeclarators(typeDeclarator.Key);
            }
        }

        public TypeDeclarator Get(Type type)
        {
            lock (semaphore)
            {
                TypeDeclarator typeDeclarator;
                if (typeDeclarators.ContainsKey(type))
                {
                    typeDeclarator = typeDeclarators[type];
                }
                else
                {
                    typeDeclarator = new TypeDeclarator(type);
                    typeDeclarators.Add(type, typeDeclarator);
                    if (typeDeclarator.DatabaseMapping != null &&
                        !typeDeclarator.DatabaseMapping.DisableIndexing)
                    {
                        foreach (var propertyDeclarator in typeDeclarator.PropertyDeclarators)
                        {
                            if (propertyDeclarator.DatabaseColumn == null ||
                                propertyDeclarator.DatabaseColumn.DisableIndexing ||
                                string.IsNullOrEmpty(propertyDeclarator.DatabaseColumn.Name)) continue;
                            databaseColumns.Add(new KeyValue(propertyDeclarator.DatabaseColumn.Name, typeDeclarator.DatabaseMapping.Table), propertyDeclarator);
                        }
                    }
                }
                return typeDeclarator;
            }
        }

        public void Clear()
        {
            lock (semaphore)
            {
                databaseColumns.Clear();
                typeDeclarators.Clear();
            }
        }

        public PropertyDeclarator FindByDatabaseColumn(string message)
        {
            PropertyDeclarator propertyDeclarator = null;
            if (!string.IsNullOrEmpty(message))
            {
                foreach (var databaseColumn in databaseColumns)
                {
                    if (message.IndexOf(databaseColumn.Key.Key + Constants.QUOTE, StringComparison.OrdinalIgnoreCase) < 0 ||
                        (!string.IsNullOrEmpty(databaseColumn.Key.Value) &&
                         message.IndexOf(databaseColumn.Key.Value + Constants.QUOTE, StringComparison.OrdinalIgnoreCase) < 0)) continue;
                    propertyDeclarator = databaseColumn.Value;
                    break;
                }
            }
            return propertyDeclarator;
        }

        public string InstanceCheck<T>(T entity) where T : class
        {
            string entityName = null;
            if (entity == null)
            {
                entityName = Get(typeof(T)).GetDisplayName();
            }
            return entityName;
        }

        public string InstanceCheck(Type type, object entity)
        {
            string entityName = null;
            if (entity == null)
            {
                entityName = Get(type).GetDisplayName();
            }
            return entityName;
        }

        public string InstancesCheck(params object[] entities)
        {
            string entityName = null;
            if (entities != null)
            {
                foreach (var entity in entities)
                {
                    entityName = InstanceCheck(entity);
                    if (!string.IsNullOrEmpty(entityName)) break;
                }
            }
            return entityName;
        }

        public string GetUndefinedProperty(Type type, object entity, string parent, string propertyName)
        {
            var undefinedPropertyName = InstanceCheck(type, entity);
            if (string.IsNullOrEmpty(undefinedPropertyName))
            {
                var typeDeclarator = Get(type);
                if (propertyName.IndexOf(parent, StringComparison.Ordinal) == 0)
                {
                    var name = propertyName.Substring(parent.Length);
                    var index = name.IndexOf(Constants.POINT);
                    if (index > 0)
                    {
                        name = name.Substring(0, index);
                    }
                    var propertyDeclarator = typeDeclarator.Find(name);
                    if (propertyDeclarator == null)
                    {
                        undefinedPropertyName = propertyName;
                    }
                    else
                    {
                        if (propertyDeclarator.IsGenericEntity)
                        {
                            undefinedPropertyName = GetUndefinedProperty(
                                propertyDeclarator.PropertyInfo.PropertyType,
                                propertyDeclarator.GetValue(entity),
                                parent + propertyDeclarator.PropertyInfo.PropertyType.Name + Constants.POINT,
                                propertyName);
                        }
                        else if (propertyDeclarator.UndefinedValues != null)
                        {
                            var propertyValue = propertyDeclarator.GetValue(entity);
                            foreach (var undefinedValue in propertyDeclarator.UndefinedValues.Values)
                            {
                                switch (undefinedValue.Key)
                                {
                                    case ConstantType.StringEmptyTrim:
                                    {
                                        propertyValue = propertyValue.ToString().Trim();
                                        break;
                                    }
                                    case ConstantType.StringEmptyTrimEnd:
                                    {
                                        propertyValue = propertyValue.ToString().TrimEnd();
                                        break;
                                    }
                                }
                                foreach (var value in undefinedValue.Value)
                                {
                                    if (!Equals(value, propertyValue)) continue;
                                    undefinedPropertyName = propertyName;
                                    break;
                                }
                                if (string.IsNullOrEmpty(undefinedPropertyName)) continue;
                                break;
                            }
                            if (!string.IsNullOrEmpty(undefinedPropertyName))
                            {
                                undefinedPropertyName = propertyDeclarator.GetDisplayName() ?? undefinedPropertyName;
                            }
                        }
                    }
                }
            }
            return undefinedPropertyName;
        }

        public List<string> GetUndefinedProperties<T>(T entity, params string[] propertyNames) where T : class
        {
            var undefinedProperties = new List<string>();
            if (propertyNames == null)
            {
                propertyNames = GetUndefinedPropertyNames(typeof(T), string.Empty).ToArray();
            }
            foreach (var propertyName in propertyNames)
            {
                var undefinedPropertyName = GetUndefinedProperty(typeof(T), entity, string.Empty, propertyName);
                if (string.IsNullOrEmpty(undefinedPropertyName)) continue;
                undefinedProperties.Add(undefinedPropertyName);
            }
            return undefinedProperties;
        }

        public void SetProperties<T>(T to, T from, params string[] propertyNames)
        {
            if (propertyNames == null) return;
            foreach (var propertyName in propertyNames)
            {
                SetProperty(to, from, propertyName);
            }
        }

        public void SetProperty<T>(T to, T from, string propertyName)
        {
            if (string.IsNullOrEmpty(propertyName)) return;
            var typeDeclarator = Get(typeof(T));
            var items = propertyName.Split(Constants.POINT);
            foreach (var item in items)
            {
                var propertyDeclarator = typeDeclarator.Find(item);
                if (propertyDeclarator == null) continue;
                var value = propertyDeclarator.GetValue(from);
                if (value == null) break;
                propertyDeclarator.SetValue(to, value);
            }
        }

        public List<string> GetUndefinedPropertyNames(Type type, string parent)
        {
            var propertyNames = new List<string>();
            var typeDeclarator = Get(type);
            foreach (var propertyDeclarator in typeDeclarator.PropertyDeclarators)
            {
                if (propertyDeclarator.IsGenericEntity)
                {
                    propertyNames.AddRange(GetUndefinedPropertyNames(propertyDeclarator.PropertyInfo.PropertyType, parent + propertyDeclarator.PropertyInfo.Name + Constants.POINT));
                }
                else
                {
                    if (propertyDeclarator.UndefinedValues == null) continue;
                    propertyNames.Add(parent + propertyDeclarator.PropertyInfo.Name);
                }
            }
            return propertyNames;
        }

        public Dictionary<string, Tuple<object, object>> GetUnequalProperties<T>(T left, T right, bool nullEmptyArray, params string[] propertyNames) where T : GenericEntity, new()
        {
            var unequalProperties = new Dictionary<string, Tuple<object, object>>();
            if (propertyNames != null)
            {
                if (left == null)
                {
                    left = new T();
                }
                if (right == null)
                {
                    right = new T();
                }
                var type = typeof(T);
                foreach (var propertyName in propertyNames)
                {
                    var valueLeft = GetPropertyValue(type, left, propertyName, nullEmptyArray);
                    var valueRight = GetPropertyValue(type, right, propertyName, nullEmptyArray);
                    if (valueLeft != null &&
                        valueRight != null &&
                        Equals(valueLeft, valueRight)) continue;
                    if (valueLeft == null)
                    {
                        valueLeft = string.Empty;
                    }
                    if (valueRight == null)
                    {
                        valueRight = string.Empty;
                    }
                    if (ClientStatic.XmlSerialize(valueLeft).Equals(ClientStatic.XmlSerialize(valueRight))) continue;
                    unequalProperties.Add(propertyName, new Tuple<object, object>(valueLeft, valueRight));
                }
            }
            return unequalProperties;
        }

        public Dictionary<string, PropertyDeclarator> GetTreePropertyDeclarators(Type type)
        {
            var typeDeclarator = Get(type);
            if (typeDeclarator.TreePropertyDeclarators == null)
            {
                typeDeclarator.TreePropertyDeclarators = new Dictionary<string, PropertyDeclarator>();
                GetTreePropertyDeclarators(typeDeclarator.TreePropertyDeclarators, type, string.Empty);
            }
            return typeDeclarator.TreePropertyDeclarators;
        }

        public void GetTreePropertyDeclarators(Dictionary<string, PropertyDeclarator> treePropertyDeclarators, Type type, string parentName)
        {
            var typeDeclarator = Get(type);
            foreach (var propertyDeclarator in typeDeclarator.PropertyDeclarators)
            {
                treePropertyDeclarators.Add(parentName + propertyDeclarator.PropertyInfo.Name, propertyDeclarator);
                if (!propertyDeclarator.IsGenericEntity) continue;
                GetTreePropertyDeclarators(treePropertyDeclarators, propertyDeclarator.PropertyInfo.PropertyType, parentName + propertyDeclarator.PropertyInfo.Name + Constants.POINT);
            }
        }

        public string GetDatabaseColumnName(Type type, string propertyName)
        {
            return GetDatabaseColumnName(type, string.Empty, propertyName);
        }

        public string GetDatabaseColumnName(Type type, string parent, string propertyName)
        {
            var databaseColumnName = parent;
            var typeDeclarator = Get(type);
            var index = propertyName.IndexOf(Constants.POINT);
            var name = index > 0 ? propertyName.Substring(0, index) : propertyName;
            var propertyDeclarator = typeDeclarator.Find(name);
            if (propertyDeclarator != null)
            {
                if (propertyDeclarator.DatabaseColumn != null)
                {
                    databaseColumnName += propertyDeclarator.DatabaseColumn.Prefix + propertyDeclarator.DatabaseColumn.Name;
                }
                if (propertyDeclarator.IsGenericEntity)
                {
                    databaseColumnName = GetDatabaseColumnName(propertyDeclarator.PropertyInfo.PropertyType, databaseColumnName, propertyName.Substring(index + 1));
                }
            }
            return databaseColumnName;
        }

        public object GetPropertyValue(Type type, object entity, string propertyName, bool nullEmptyArray = false)
        {
            object value = null;
            var typeDeclarator = Get(type);
            var index = propertyName.IndexOf(Constants.POINT);
            var name = index > 0 ? propertyName.Substring(0, index) : propertyName;
            var propertyDeclarator = typeDeclarator.Find(name);
            if (propertyDeclarator != null)
            {
                value = propertyDeclarator.GetValue(entity);
                if (index >= 0 &&
                    propertyName.IndexOf(Constants.POINT, index) >= 0)
                {
                    value = GetPropertyValue(propertyDeclarator.PropertyInfo.PropertyType, value, propertyName.Substring(index + 1));
                }
                if (nullEmptyArray &&
                    propertyDeclarator.PropertyInfo.PropertyType.IsArray &&
                    value != null &&
                    ((Array)value).Length == 0)
                {
                    value = null;
                }
            }
            return value;
        }

        public void ProfilePropertyMap<T>(T entityTo, T entityFrom, bool excludeUndefined) where T : GenericEntity
        {
            var type = entityTo.GetType();
            var typeDeclarator = Get(type);
            foreach (var propertyDeclarator in typeDeclarator.PropertyDeclarators)
            {
                if (propertyDeclarator.ProfileProperty == null) continue;
                var value = propertyDeclarator.PropertyInfo.GetValue(entityFrom, null);
                if (value == null && excludeUndefined) continue;
                propertyDeclarator.PropertyInfo.SetValue(entityTo, value, null);
            }
        }

        public Dictionary<E, T> GetEnumEntityPairs<E, T>(List<T> entities)
        {
            var enumEntityPairs = new Dictionary<E, T>();
            var enumType = typeof(E);
            var typeDeclarator = Get(typeof(T));
            var propertyDeclarator = typeDeclarator.Find(enumType);
            if (propertyDeclarator != null)
            {
                foreach (var entity in entities)
                {
                    var enumString = propertyDeclarator.GetValue(entity).ToString();
                    if (!Enum.IsDefined(enumType, enumString)) continue;
                    var enumValue = (E) Enum.Parse(enumType, enumString, true);
                    if (enumEntityPairs.ContainsKey(enumValue)) continue;
                    enumEntityPairs.Add(enumValue, entity);
                }
            }
            return enumEntityPairs;
        }

        #endregion Methods

        #endregion Public Members
    }
}