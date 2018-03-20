#region Using

using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Geolocation
{
    [DataContract]
    public enum SourceInputType
    {
        [EnumMember]
        [FieldCategory(Name = "undefined")]
        Undefined,
        [EnumMember]
        [FieldCategory(Name = "MaxMind locations")]
        MaxMindLocations,
        [EnumMember]
        [FieldCategory(Name = "MaxMind blocks")]
        MaxMindBlocks
    }

    [DataContract]
    public class SourcePredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<SourceInputType>> SourceInputTypes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Descriptions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> ApprovedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Source>> Sources { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Source")]
    [DatabaseMapping(StoredProcedure = "[Geolocation].[Source.Action]")]
    public class Source : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SourceId", IsIdentity = true)]
        [DisplayName("Source id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SourceCode")]
        [DisplayName("Source code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SourceInputType")]
        [DisplayName("Source input type")]
        [UndefinedValues(SourceInputType.Undefined)]
        public SourceInputType SourceInputType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SourceDescription")]
        [DisplayName("Source description")]
        public string Description { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SourceCreatedOn")]
        [DisplayName("Source created on")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SourceApprovedOn")]
        [DisplayName("Source approved on")]
        public DateTimeOffset? ApprovedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SourceInput")]
        [DisplayName("Source input")]
        [UndefinedValues(ConstantType.NullReference)]
        public byte[] Input { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SourceInputLength")]
        [DisplayName("Source input length")]
        public long? InputLength { get; set; }

        public Stream InputStream
        {
            get
            {
                Stream inputStream = null;
                if (Input != null && Input.Length > 0)
                {
                    inputStream = new MemoryStream(Input);
                    InputLength = Input.Length;
                }
                else
                {
                    Input = null;
                    InputLength = null;
                }
                return inputStream;
            }
            set
            {
                var inputStream = value;
                if (inputStream != null && inputStream.Length > 0)
                {
                    Input = new byte[inputStream.Length];
                    inputStream.Read(Input, 0, (int)inputStream.Length);
                    inputStream.Dispose();
                    InputLength = Input.Length;
                }
                else
                {
                    Input = null;
                    InputLength = null;
                }
            }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SourceEntriesLoaded")]
        [DisplayName("Source entries loaded")]
        public long? EntriesLoaded { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SourceErrors")]
        [DisplayName("Source errors")]
        public string Errors { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SourceErrorsLoaded")]
        [DisplayName("Source errors loaded")]
        public long? ErrorsLoaded { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SourceVersion")]
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
            if (!string.IsNullOrEmpty(Code))
            {
                keys.Add(Code.ToUpper());
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}