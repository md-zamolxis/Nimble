#region Using

using System;
using System.Reflection;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;

#endregion Using

namespace Nimble.Business.Library.Reflection
{
    [DataContract]
    [DisplayName("Property declarator")]
    public class PropertyDeclarator
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Entity type")]
        public Type EntityType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Property info")]
        public PropertyInfo PropertyInfo { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Database column")]
        public DatabaseColumn DatabaseColumn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Undefined values")]
        public UndefinedValues UndefinedValues { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Is generic entity")]
        public bool IsGenericEntity { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Is generic predicate")]
        public bool IsGenericPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Display name")]
        public DisplayName DisplayName { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Property types")]
        public PropertyTypes PropertyTypes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Connection string")]
        public ConnectionString ConnectionString { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Application setting")]
        public ApplicationSetting ApplicationSetting { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Profile property")]
        public ProfileProperty ProfileProperty { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Flags attribute")]
        public FlagsAttribute FlagsAttribute { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("External reference")]
        public ExternalReference ExternalReference { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Database mapping")]
        public DatabaseMapping DatabaseMapping { get; set; }

        #endregion Properties

        #region Methods

        public object GetValue(object component)
        {
            return PropertyInfo.GetValue(component, null);
        }

        public void SetValue(object component, object value)
        {
            PropertyInfo.SetValue(component, value, null);
        }

        public string GetDisplayName()
        {
            return (DisplayName == null) ? PropertyInfo.Name : DisplayName.Name;
        }

        #endregion Methods

        #endregion Public Members
    }
}
