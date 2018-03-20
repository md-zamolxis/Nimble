#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Owner
{
    [DataContract]
    public enum LayoutEntityType
    {
        [EnumMember]
        [FieldCategory(Name = "undefined")]
        Undefined,
        [EnumMember]
        [FieldCategory(Name = "discount")]
        Discount,
        [EnumMember]
        [FieldCategory(Name = "price")]
        Price,
        [EnumMember]
        [FieldCategory(Name = "receipt")]
        Receipt
    }

    [DataContract]
    public class LayoutPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<LayoutEntityType>> LayoutEntityTypes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Names { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Descriptions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Layout>> Layouts { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public OrganisationPredicate OrganisationPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Layout")]
    [DatabaseMapping(StoredProcedure = "[Owner].[Layout.Action]")]
    public class Layout: GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LayoutId", IsIdentity = true)]
        [DisplayName("Layout id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Layout organisation")]
        [UndefinedValues(ConstantType.NullReference)]
        public Organisation Organisation { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LayoutEntityType")]
        [DisplayName("Layout entity type")]
        [UndefinedValues(LayoutEntityType.Undefined)]
        public LayoutEntityType LayoutEntityType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LayoutCode")]
        [DisplayName("Layout code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LayoutName")]
        [DisplayName("Layout name")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Name { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LayoutDescription")]
        [DisplayName("Layout description")]
        public string Description { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LayoutSettings")]
        [DisplayName("Layout settings")]
        public KeyValue[] Settings { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LayoutVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(Organisation) &&
                LayoutEntityType != LayoutEntityType.Undefined &&
                !string.IsNullOrEmpty(Code))
            {
                keys.Add(Organisation.GetIdCode() + LayoutEntityType.ToString().ToUpper() + Code.ToUpper());
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}