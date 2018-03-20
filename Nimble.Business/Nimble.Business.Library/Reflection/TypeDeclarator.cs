#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Library.Reflection
{
    [DataContract]
    [DisplayName("Type declarator")]
    public class TypeDeclarator
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Entity type")]
        public Type EntityType { get; private set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Property declarators")]
        public List<PropertyDeclarator> PropertyDeclarators { get; private set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Property declarator identity")]
        public PropertyDeclarator Identity { get; private set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Display name")]
        public DisplayName DisplayName { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Database mapping")]
        public DatabaseMapping DatabaseMapping { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("External mapping")]
        public ExternalMapping ExternalMapping { get; set; }

        [DisplayName("Name property declarators")]
        public Dictionary<string, PropertyDeclarator> TreePropertyDeclarators { get; set; }

        #endregion Properties

        #region Methods

        public TypeDeclarator(Type type)
        {
            EntityType = type;
            DisplayName = ClientStatic.GetCustomAttribute<DisplayName>(type, false);
            DatabaseMapping = ClientStatic.GetCustomAttribute<DatabaseMapping>(type, false);
            ExternalMapping = ClientStatic.GetCustomAttribute<ExternalMapping>(type, false);
            PropertyDeclarators = new List<PropertyDeclarator>();
            var propertyInfos = type.GetProperties();
            foreach (var propertyInfo in propertyInfos)
            {
                var propertyDeclarator = new PropertyDeclarator
                {
                    EntityType = type,
                    PropertyInfo = propertyInfo,
                    DatabaseColumn = ClientStatic.GetCustomAttribute<DatabaseColumn>(propertyInfo, false),
                    UndefinedValues = ClientStatic.GetCustomAttribute<UndefinedValues>(propertyInfo, false),
                    IsGenericEntity = (propertyInfo.PropertyType.BaseType == ClientStatic.GenericEntity),
                    IsGenericPredicate = (propertyInfo.PropertyType.BaseType == ClientStatic.GenericPredicate),
                    DisplayName = ClientStatic.GetCustomAttribute<DisplayName>(propertyInfo, false),
                    PropertyTypes = ClientStatic.GetCustomAttribute<PropertyTypes>(propertyInfo, false),
                    ConnectionString = ClientStatic.GetCustomAttribute<ConnectionString>(propertyInfo, false),
                    ApplicationSetting = ClientStatic.GetCustomAttribute<ApplicationSetting>(propertyInfo, false),
                    ProfileProperty = ClientStatic.GetCustomAttribute<ProfileProperty>(propertyInfo, false),
                    FlagsAttribute = ClientStatic.GetCustomAttribute<FlagsAttribute>(propertyInfo, false),
                    ExternalReference = ClientStatic.GetCustomAttribute<ExternalReference>(propertyInfo, false),
                    DatabaseMapping = DatabaseMapping
                };
                PropertyDeclarators.Add(propertyDeclarator);
                if (propertyDeclarator.DatabaseColumn == null ||
                    !propertyDeclarator.DatabaseColumn.IsIdentity) continue;
                Identity = propertyDeclarator;
            }
        }

        public PropertyDeclarator Find(string propertyName)
        {
            PropertyDeclarator propertyDeclarator = null;
            foreach (var property in PropertyDeclarators)
            {
                if (!property.PropertyInfo.Name.Equals(propertyName)) continue;
                propertyDeclarator = property;
                break;
            }
            return propertyDeclarator;
        }

        public PropertyDeclarator Find(Type propertyType)
        {
            PropertyDeclarator propertyDeclarator = null;
            foreach (var item in PropertyDeclarators)
            {
                if (item.PropertyTypes == null ||
                    !item.PropertyTypes.Types.Contains(propertyType)) continue;
                propertyDeclarator = item;
                break;
            }
            return propertyDeclarator;
        }

        public string GetDisplayName()
        {
            return (DisplayName == null) ? EntityType.Name : DisplayName.Name;
        }

        public object GetValue(string propertyName, object component)
        {
            var propertyDeclarator = Find(propertyName);
            return propertyDeclarator == null ? null : propertyDeclarator.GetValue(component);
        }

        #endregion Methods

        #endregion Public Members
    }
}