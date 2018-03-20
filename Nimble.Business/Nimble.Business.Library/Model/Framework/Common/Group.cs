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
    public class GroupPredicate : GenericPredicate
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
        public Criteria<List<Group>> Groups { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public SplitPredicate SplitPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool LoadEntities { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Group")]
    [DatabaseMapping(StoredProcedure = "[Common].[Group.Action]", Table = "Common.Group")]
    public class Group : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupId", IsIdentity = true)]
        [DisplayName("Group id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Group split")]
        [UndefinedValues(ConstantType.NullReference)]
        public Split Split { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupCode")]
        [DisplayName("Group code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupName")]
        [DisplayName("Group name")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Name { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupNames")]
        [DisplayName("Group names")]
        public KeyValue[] Names { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupDescription")]
        [DisplayName("Group description")]
        public string Description { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupDescriptions")]
        [DisplayName("Group descriptions")]
        public KeyValue[] Descriptions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupIsDefault")]
        [DisplayName("Group is default")]
        public bool IsDefault { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupSettings")]
        [DisplayName("Group settings")]
        public KeyValue[] Settings { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "GroupVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Group entities")]
        public List<Guid?> Entities { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Group branches")]
        public List<Branch> Branches { get; set; }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(Split))
            {
                var splitId = Split.GetIdCode();
                if (!string.IsNullOrEmpty(Code))
                {
                    keys.Add(splitId + Code.ToUpper());
                }
                if (IsDefault)
                {
                    keys.Add(splitId);
                }
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}