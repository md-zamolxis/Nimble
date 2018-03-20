#region Using

using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model.Framework.Security;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Multilanguage
{
    [DataContract]
    public enum ResourceCategoryType
    {
        [EnumMember]
        BusinessLogic,
        [EnumMember]
        Enumerators,
        [EnumMember]
        AdministrationWebSite,
        [EnumMember]
        AdministrationMasterPage,
        [EnumMember]
        OperationalWebSite,
        [EnumMember]
        OperationalMasterPage,
        [EnumMember]
        OperationalDesktop
    }

    [DataContract]
    public class ResourcePredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Categories { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Indexes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> LastUsedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Resource>> Resources { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public EmplacementPredicate EmplacementPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public ApplicationPredicate ApplicationPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Resource")]
    [DatabaseMapping(StoredProcedure = "[Multilanguage].[Resource.Action]")]
    public class Resource : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "ResourceId", IsIdentity = true)]
        [DisplayName("Resource id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Resource emplacement")]
        [UndefinedValues(ConstantType.NullReference)]
        public Emplacement Emplacement { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Resource application")]
        [UndefinedValues(ConstantType.NullReference)]
        public Application Application { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "ResourceCode")]
        [DisplayName("Resource code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmpty)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "ResourceCategory")]
        [DisplayName("Resource category")]
        [UndefinedValues(ConstantType.NullReference)]
        public string Category { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "ResourceIndex")]
        [DisplayName("Resource index")]
        public string Index { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "ResourceCreatedOn")]
        [DisplayName("Resource created on")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "ResourceLastUsedOn")]
        [DisplayName("Resource last used on")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? LastUsedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "ResourceVersion")]
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
            if (HasValue(Emplacement) &&
                HasValue(Application))
            {
                var emplacementApplicationIds = Emplacement.GetIdCode() + Application.GetIdCode();
                if (!string.IsNullOrEmpty(Code))
                {
                    keys.Add(emplacementApplicationIds + Code + Category);
                }
                if (!string.IsNullOrEmpty(Index))
                {
                    keys.Add(emplacementApplicationIds + Index);
                }
            }
            if (Emplacement != null &&
                Application != null)
            {
                foreach (var emplacementNaturalKey in Emplacement.GetNaturalKeys())
                {
                    keys.AddRange(Application.GetNaturalKeys().Select(applicationNaturalKey => emplacementNaturalKey + applicationNaturalKey + Code + Category));
                }
            }
            return keys;
        }

        public override FaultExceptionDetail Validate()
        {
            var faultExceptionDetail = new FaultExceptionDetail();
            faultExceptionDetail.Items.Add(StringValidate("Code", Code));
            faultExceptionDetail.Items.Add(StringValidate("Category", Category));
            return faultExceptionDetail;
        }

        public override void SetDefaults()
        {
            CreatedOn = LastUsedOn = DateTimeOffset.Now;
        }

        #endregion Methods

        #endregion Public Members
    }
}