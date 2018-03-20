#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.DataAccess;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Owner
{
    [DataContract]
    public class MarkOutput
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public GenericOutput<Mark> GenericOutput { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public List<Branch> Branches { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public List<Post> Posts { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    public enum MarkEntityType
    {
        [EnumMember]
        [FieldCategory(Name = "undefined")]
        Undefined,
        [EnumMember]
        [FieldCategory(Name = "branch")]
        Branch = 1,
        [EnumMember]
        [FieldCategory(Name = "post")]
        Post = 2
    }

    [DataContract]
    public enum MarkActionType
    {
        [EnumMember]
        [FieldCategory(Name = "undefined")]
        Undefined,
        [EnumMember]
        [FieldCategory(Name = "like")]
        Like,
        [EnumMember]
        [FieldCategory(Name = "dislike")]
        Dislike
    }

    [DataContract]
    public class MarkPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<MarkEntityType>> MarkEntityTypes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Guid?>> EntityIds { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> UpdatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<MarkActionType>> MarkActionTypes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Comments { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public PersonPredicate PersonPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool LoadBranches { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool LoadPosts { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Mark")]
    [DatabaseMapping(StoredProcedure = "[Owner].[Mark.Action]")]
    public class Mark : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MarkId", IsIdentity = true)]
        [DisplayName("Mark id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Mark person")]
        [UndefinedValues(ConstantType.NullReference)]
        public Person Person { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MarkEntityType")]
        [DisplayName("Mark entity type")]
        [UndefinedValues(MarkEntityType.Undefined)]
        public MarkEntityType MarkEntityType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MarkEntityId")]
        [DisplayName("Mark entity id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? EntityId { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MarkCreatedOn")]
        [DisplayName("Mark created on")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MarkUpdatedOn")]
        [DisplayName("Mark updated on")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? UpdatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MarkActionType")]
        [DisplayName("Mark action type")]
        [UndefinedValues(MarkActionType.Undefined)]
        public MarkActionType MarkActionType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MarkComment")]
        [DisplayName("Mark comment")]
        public string Comment { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MarkSettings")]
        [DisplayName("Mark settings")]
        public KeyValue[] Settings { get; set; }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(Person) &&
                MarkEntityType != MarkEntityType.Undefined &&
                EntityId.HasValue)
            {
                keys.Add(Person.GetIdCode() + MarkEntityType.ToString().ToUpper() + EntityId.Value);
            }
            return keys;
        }

        public override void SetDefaults()
        {
            CreatedOn = DateTimeOffset.Now;
        }

        #endregion Methods

        #endregion Public Members
    }
}