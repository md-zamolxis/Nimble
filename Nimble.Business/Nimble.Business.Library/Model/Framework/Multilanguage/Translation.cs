#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Multilanguage
{
    [DataContract]
    public class TranslationPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Senses { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Translation>> Translations { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public ResourcePredicate ResourcePredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public CulturePredicate CulturePredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? Translated { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Translation")]
    [DatabaseMapping(StoredProcedure = "[Multilanguage].[Translation.Action]")]
    public class Translation : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "TranslationId", IsIdentity = true, ForceValue = true)]
        [DisplayName("Translation id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Translation resource")]
        [UndefinedValues(ConstantType.NullReference)]
        public Resource Resource { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Translation culture")]
        [UndefinedValues(ConstantType.NullReference)]
        public Culture Culture { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "TranslationSense")]
        [DisplayName("Translation sense")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmpty)]
        public string Sense { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "TranslationVersion")]
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
            if (HasValue(Resource) &&
                HasValue(Culture))
            {
                keys.Add(Resource.GetIdCode() + Culture.GetIdCode());
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}