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
    [Flags]
    [DataContract]
    public enum PostActionType
    {
        [EnumMember]
        [FieldCategory(Name = "none")]
        None = 0,
        [EnumMember]
        [FieldCategory(Name = "public")]
        Public = 1,
        [EnumMember]
        [FieldCategory(Name = "slider")]
        Slider = 2
    }

    [DataContract]
    public class PostPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> Date { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Titles { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Subjects { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Bodies { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> UpdatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> DeletedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<Flags<PostActionType>> PostActionType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Post>> Posts { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public OrganisationPredicate OrganisationPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public PostGroupPredicate PostGroupPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool PostGroupExclude { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool LoadPostGroups { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool LoadFilestreams { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Post")]
    [DatabaseMapping(StoredProcedure = "[Owner].[Post.Action]")]
    public class Post : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PostId", IsIdentity = true)]
        [DisplayName("Post id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Post organisation")]
        [UndefinedValues(ConstantType.NullReference)]
        public Organisation Organisation { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PostCode")]
        [DisplayName("Post code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PostDate")]
        [DisplayName("Post date")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? Date { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PostTitle")]
        [DisplayName("Post title")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmpty)]
        public string Title { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PostTitles")]
        [DisplayName("Post titles")]
        public KeyValue[] Titles { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PostSubject")]
        [DisplayName("Post subject")]
        public string Subject { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PostSubjects")]
        [DisplayName("Post subjects")]
        public KeyValue[] Subjects { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PostBody")]
        [DisplayName("Post body")]
        public string Body { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PostBodies")]
        [DisplayName("Post bodies")]
        public KeyValue[] Bodies { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PostUrls")]
        [DisplayName("Post urls")]
        public KeyValue[] Urls { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PostCreatedOn")]
        [DisplayName("Post created on")]
        public DateTimeOffset? CreatedOn
        {
            get { return createdOn; }
            set { createdOn = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PostUpdatedOn")]
        [DisplayName("Post updated on")]
        public DateTimeOffset? UpdatedOn
        {
            get { return updatedOn; }
            set { updatedOn = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PostDeletedOn")]
        [DisplayName("Post deleted on")]
        public DateTimeOffset? DeletedOn
        {
            get { return deletedOn; }
            set { deletedOn = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PostActionType")]
        [DisplayName("Post action type")]
        [UndefinedValues(ConstantType.NullReference)]
        public Flags<PostActionType> PostActionType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PostSettings")]
        [DisplayName("Post settings")]
        public KeyValue[] Settings { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "PostVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Post groups")]
        public List<PostGroup> PostGroups { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Post filestream")]
        public Filestream Filestream { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Post filestreams")]
        public List<Filestream> Filestreams { get; set; }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(Organisation) &&
                !string.IsNullOrEmpty(Code))
            {
                keys.Add(Organisation.GetIdCode() + Code.ToUpper());
            }
            return keys;
        }

        public override void SetDefaults()
        {
            CreatedOn = DateTimeOffset.Now;
        }

        public override GenericEntity Clone()
        {
            return new Post
                {
                    Id = Id,
                    Organisation = (Organisation == null ? Organisation : Organisation.Clone<Organisation>()),
                    Code = Code
                };
        }

        #endregion Methods

        #endregion Public Members
    }
}