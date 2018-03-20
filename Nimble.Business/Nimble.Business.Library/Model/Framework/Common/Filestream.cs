#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model.Framework.Owner;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Common
{
    [DataContract]
    public class FilestreamPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Guid?>> EntityIds { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Guid?>> ReferenceIds { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Names { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Descriptions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Extensions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? IsDefault { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Urls { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Guid?>> ThumbnailIds { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<AmountInterval> ThumbnailWidth { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<AmountInterval> ThumbnailHeight { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> ThumbnailExtensions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> ThumbnailUrls { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Filestream>> Filestreams { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public PersonPredicate PersonPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public OrganisationPredicate OrganisationPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public EmployeePredicate EmployeePredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public BranchPredicate BranchPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public BranchGroupPredicate BranchGroupPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public PostPredicate PostPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public PostGroupPredicate PostGroupPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool LoadData { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Filestream")]
    [DatabaseMapping(StoredProcedure = "[Common].[Filestream.Action]")]
    public class Filestream : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "FilestreamId", IsIdentity = true)]
        [DisplayName("Filestream id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "FilestreamEntityId")]
        [DisplayName("Filestream entity id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? EntityId { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "FilestreamCode")]
        [DisplayName("Filestream code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "FilestreamReferenceId")]
        [DisplayName("Filestream reference id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? ReferenceId { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "FilestreamCreatedOn")]
        [DisplayName("Filestream created on")]
        public DateTimeOffset? CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "FilestreamName")]
        [DisplayName("Filestream name")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Name { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "FilestreamDescription")]
        [DisplayName("Filestream description")]
        public string Description { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "FilestreamExtension")]
        [DisplayName("Filestream extension")]
        public string Extension { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "FilestreamData")]
        [DisplayName("Filestream data")]
        [UndefinedValues(ConstantType.NullReference)]
        public byte[] Data { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "FilestreamIsDefault")]
        [DisplayName("Filestream is default")]
        public bool IsDefault { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "FilestreamUrl")]
        [DisplayName("Filestream url")]
        public string Url { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "FilestreamThumbnailId")]
        [DisplayName("Filestream thumbnail id")]
        public Guid? ThumbnailId { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "FilestreamThumbnailWidth")]
        [DisplayName("Filestream thumbnail width")]
        public int? ThumbnailWidth { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "FilestreamThumbnailHeight")]
        [DisplayName("Filestream thumbnail height")]
        public int? ThumbnailHeight { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "FilestreamThumbnailExtension")]
        [DisplayName("Filestream thumbnail extension")]
        public string ThumbnailExtension { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "FilestreamThumbnailUrl")]
        [DisplayName("Filestream thumbnail url")]
        public string ThumbnailUrl { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Filestream entity action type")]
        public EntityActionType EntityActionType
        {
            get { return entityActionType; }
            set { entityActionType = value; }
        }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (EntityId.HasValue)
            {
                var entityId = EntityId.Value.ToString();
                if (!string.IsNullOrEmpty(Code))
                {
                    keys.Add(entityId + Code.ToUpper());
                }
                if (IsDefault)
                {
                    keys.Add(entityId);
                }
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