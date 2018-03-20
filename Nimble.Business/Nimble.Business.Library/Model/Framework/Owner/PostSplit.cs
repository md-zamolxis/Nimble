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
    public enum SplitPostType
    {
        [EnumMember]
        [FieldCategory(Name = "none")]
        None,
        [EnumMember]
        [FieldCategory(Name = "menu")]
        Menu
    }

    [DataContract]
    public class PostSplitPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<SplitPostType>> SplitPostTypes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Names { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? IsSystem { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? IsExclusive { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<PostSplit>> PostSplits { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public OrganisationPredicate OrganisationPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Post split")]
    [DatabaseMapping(StoredProcedure = "[Owner.Post].[Split.Action]", Table = "Owner.Post.Split")]
    public class PostSplit : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitId", IsIdentity = true)]
        [DisplayName("Post split id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Post split organisation")]
        [UndefinedValues(ConstantType.NullReference)]
        public Organisation Organisation { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitCode")]
        [DisplayName("Post split code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitPostType")]
        [DisplayName("Post split type")]
        public SplitPostType? SplitPostType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitName")]
        [DisplayName("Post split name")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Name { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitNames")]
        [DisplayName("Post split names")]
        public KeyValue[] Names { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitIsSystem")]
        [DisplayName("Post split is system")]
        public bool IsSystem { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitIsExclusive")]
        [DisplayName("Post split is exclusive")]
        public bool IsExclusive { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitSettings")]
        [DisplayName("Post split settings")]
        public KeyValue[] Settings { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "SplitVersion")]
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
            if (HasValue(Organisation))
            {
                var organisationId = Organisation.GetIdCode();
                if (!string.IsNullOrEmpty(Code))
                {
                    keys.Add(organisationId + Code.ToUpper());
                }
                if (SplitPostType.HasValue)
                {
                    keys.Add(organisationId + SplitPostType.ToString().ToUpper());
                }
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}