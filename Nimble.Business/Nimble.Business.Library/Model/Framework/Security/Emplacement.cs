#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Security
{
    [DataContract]
    public class EmplacementPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Descriptions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? IsAdministrative { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Emplacement>> Emplacements { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Emplacement")]
    [DatabaseMapping(StoredProcedure = "[Security].[Emplacement.Action]")]
    public class Emplacement : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "EmplacementId", IsIdentity = true)]
        [DisplayName("Emplacement id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "EmplacementCode")]
        [DisplayName("Emplacement code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrim)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "EmplacementDescription")]
        [DisplayName("Emplacement description")]
        public string Description { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "EmplacementIsAdministrative")]
        [DisplayName("Emplacement is administrative")]
        public bool IsAdministrative { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "EmplacementVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        #region Profile

        [DataMember(EmitDefaultValue = false)]
        [ProfileProperty(ProfileCode = "CultureId", CommonPropertyType = CommonPropertyType.Culture)]
        [DisplayName("Culture id")]
        public Guid? CultureId { get; set; }

        #endregion Profile

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (!string.IsNullOrEmpty(Code))
            {
                keys.Add(Code.ToUpper());
            }
            return keys;
        }

        public override GenericEntity Clone()
        {
            return new Emplacement
                {
                    Id = Id,
                    Code = Code
                };
        }

        #endregion Methods

        #endregion Public Members
    }
}