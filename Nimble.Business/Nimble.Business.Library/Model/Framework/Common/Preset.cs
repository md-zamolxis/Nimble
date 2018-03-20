#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model.Framework.Security;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Common
{
    [DataContract]
    public enum PresetEntityType
    {
        [EnumMember]
        [FieldCategory(Name = "undefined")]
        Undefined,
        [EnumMember]
        [FieldCategory(Name = "emplacement")]
        Emplacement,
        [EnumMember]
        [FieldCategory(Name = "user")]
        User,
        [EnumMember]
        [FieldCategory(Name = "application")]
        Application,
        [EnumMember]
        [FieldCategory(Name = "permission")]
        Permission,
        [EnumMember]
        [FieldCategory(Name = "role")]
        Role,
        [EnumMember]
        [FieldCategory(Name = "log")]
        Log,
        [EnumMember]
        [FieldCategory(Name = "token")]
        Token,
        [EnumMember]
        [FieldCategory(Name = "lock")]
        Lock,
        [EnumMember]
        [FieldCategory(Name = "culture")]
        Culture,
        [EnumMember]
        [FieldCategory(Name = "resource")]
        Resource,
        [EnumMember]
        [FieldCategory(Name = "translation")]
        Translation,
        [EnumMember]
        [FieldCategory(Name = "backup")]
        Backup,
        [EnumMember]
        [FieldCategory(Name = "batch")]
        Batch,
        [EnumMember]
        [FieldCategory(Name = "source")]
        Source,
        [EnumMember]
        [FieldCategory(Name = "location")]
        Location,
        [EnumMember]
        [FieldCategory(Name = "person")]
        Person
    }

    [DataContract]
    public class PresetPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<PresetEntityType>> PresetEntityTypes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<AmountInterval> Category { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Descriptions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? IsDefault { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? IsInstantly { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Preset>> Presets { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public AccountPredicate AccountPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Preset")]
    [DatabaseMapping(StoredProcedure = "[Common].[Preset.Action]")]
    public class Preset : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PresetId", IsIdentity = true)]
        [DisplayName("Preset id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(DisableCaching = true)]
        [DisplayName("Preset account")]
        [UndefinedValues(ConstantType.NullReference)]
        public Account Account { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PresetEntityType")]
        [DisplayName("Preset entity type")]
        [UndefinedValues(PresetEntityType.Undefined)]
        public PresetEntityType PresetEntityType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PresetCode")]
        [DisplayName("Preset code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PresetCategory")]
        [DisplayName("Preset category")]
        public int? Category { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PresetDescription")]
        [DisplayName("Preset description")]
        public string Description { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PresetPredicate")]
        [DisplayName("Preset predicate")]
        [UndefinedValues(ConstantType.NullReference)]
        public string Predicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PresetIsDefault")]
        [DisplayName("Preset is default")]
        public bool IsDefault { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PresetIsInstantly")]
        [DisplayName("Preset is instantly")]
        public bool IsInstantly { get; set; }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(Account) &&
                PresetEntityType != PresetEntityType.Undefined &&
                !string.IsNullOrEmpty(Code))
            {
                var accountIdPresetEntityType = Account.GetIdCode() + PresetEntityType.ToString().ToUpper();
                if (!string.IsNullOrEmpty(Code))
                {
                    keys.Add(accountIdPresetEntityType + Code.ToUpper() + (Category == null ? string.Empty : Category.ToString()));
                }
                if (IsDefault)
                {
                    keys.Add(accountIdPresetEntityType);
                }
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}