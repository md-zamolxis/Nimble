#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Geolocation
{
    [DataContract]
    [DisplayName("Portion")]
    [DatabaseMapping(StoredProcedure = "[Geolocation].[Portion.Action]")]
    public class Portion : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PortionId", IsIdentity = true)]
        [DisplayName("Portion id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Portion source")]
        [UndefinedValues(ConstantType.NullReference)]
        public Source Source { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PortionCode")]
        [DisplayName("Portion code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PortionEntries")]
        [DisplayName("Portion entries")]
        public string Entries { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PortionEntriesLoaded")]
        [DisplayName("Portion entries loaded")]
        public long? EntriesLoaded { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PortionEntriesImported")]
        [DisplayName("Portion entries imported")]
        public long? EntriesImported { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PortionVersion")]
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
            if (HasValue(Source) &&
                !string.IsNullOrEmpty(Code))
            {
                keys.Add(Source.GetIdCode() + Code.ToUpper());
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}