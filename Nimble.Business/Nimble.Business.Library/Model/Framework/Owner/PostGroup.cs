#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model.Framework.Common;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Owner
{
    [DataContract]
    public class PostGroupPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Names { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Descriptions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? IsDefault { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> UpdatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> DeletedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<PostGroup>> PostGroups { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public PostSplitPredicate PostSplitPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public PostPredicate PostPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool PostSplitIntersect { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool LoadPosts { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool LoadFilestreams { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Post group")]
    [DatabaseMapping(StoredProcedure = "[Owner.Post].[Group.Action]", Table = "Owner.Post.Group")]
    public class PostGroup : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupId", IsIdentity = true)]
        [DisplayName("Post group id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Post group split")]
        [UndefinedValues(ConstantType.NullReference)]
        public PostSplit PostSplit { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupCode")]
        [DisplayName("Post group code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupName")]
        [DisplayName("Post group name")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Name { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupNames")]
        [DisplayName("Post group names")]
        public KeyValue[] Names { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupDescription")]
        [DisplayName("Post group description")]
        public string Description { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupDescriptions")]
        [DisplayName("Post group descriptions")]
        public KeyValue[] Descriptions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupIsDefault")]
        [DisplayName("Post group is default")]
        public bool IsDefault { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupCreatedOn")]
        [DisplayName("Post group created on")]
        public DateTimeOffset? CreatedOn
        {
            get { return createdOn; }
            set { createdOn = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupUpdatedOn")]
        [DisplayName("Post group updated on")]
        public DateTimeOffset? UpdatedOn
        {
            get { return updatedOn; }
            set { updatedOn = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupDeletedOn")]
        [DisplayName("Post group deleted on")]
        public DateTimeOffset? DeletedOn
        {
            get { return deletedOn; }
            set { deletedOn = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupSettings")]
        [DisplayName("Post group settings")]
        public KeyValue[] Settings { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Post group posts")]
        public List<Post> Posts { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Post group filestream")]
        public Filestream Filestream { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Post group filestreams")]
        public List<Filestream> Filestreams { get; set; }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(PostSplit))
            {
                var postSplitId = PostSplit.GetIdCode();
                if (!string.IsNullOrEmpty(Code))
                {
                    keys.Add(postSplitId + Code.ToUpper());
                }
                if (IsDefault)
                {
                    keys.Add(postSplitId);
                }
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}