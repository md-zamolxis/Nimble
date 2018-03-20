#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Common
{
    [DataContract]
    [DisplayName("Hierarchy")]
    [DatabaseMapping(StoredProcedure = "[Common].[Hierarchy.Action]")]
    public class Hierarchy : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "HierarchyCode")]
        [DisplayName("Hierarchy code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmpty)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "HierarchyEntityId")]
        [DisplayName("Hierarchy entity id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? EntityId { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Hierarchy parent id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? ParentId { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "HierarchyLeft")]
        [DisplayName("Hierarchy left")]
        [UndefinedValues(ConstantType.NullReference)]
        public int? Left { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "HierarchyRight")]
        [DisplayName("Hierarchy right")]
        [UndefinedValues(ConstantType.NullReference)]
        public int? Right { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "HierarchyLevel")]
        [DisplayName("Hierarchy level")]
        [UndefinedValues(ConstantType.NullReference)]
        public int? Level { get; set; }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (EntityId.HasValue)
            {
                keys.Add(EntityId.Value.ToString());
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}