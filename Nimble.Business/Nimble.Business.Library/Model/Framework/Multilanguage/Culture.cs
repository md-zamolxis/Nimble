#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Model.Framework.Security;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Multilanguage
{
    [DataContract]
    public class CulturePredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Names { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Culture>> Cultures { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public EmplacementPredicate EmplacementPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Culture")]
    [DatabaseMapping(StoredProcedure = "[Multilanguage].[Culture.Action]")]
    public class Culture : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "CultureId", IsIdentity = true)]
        [DisplayName("Culture id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Culture emplacement")]
        [UndefinedValues(ConstantType.NullReference)]
        public Emplacement Emplacement { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "CultureCode")]
        [DisplayName("Culture code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmpty)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "CultureName")]
        [DisplayName("Culture name")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmpty)]
        public string Name { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "CultureVersion")]
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
            if (HasValue(Emplacement))
            {
                var emplacementId = Emplacement.GetIdCode();
                if (!string.IsNullOrEmpty(Code))
                {
                    keys.Add(emplacementId + Code.ToUpper());
                }
                if (!string.IsNullOrEmpty(Name))
                {
                    keys.Add(emplacementId + Name.ToUpper());
                }
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}