#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Model.Framework.Owner;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Common
{
    [DataContract]
    public class BondPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Bond>> Bonds { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public BranchPredicate BranchPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public GroupPredicate GroupPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Bond")]
    [DatabaseMapping(StoredProcedure = "[Common].[Bond.Action]")]
    public class Bond : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BondEntityId")]
        [DisplayName("Bond entity")]
        [UndefinedValues(ConstantType.NullReference)]
        public Guid? Entity { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Bond group")]
        [UndefinedValues(ConstantType.NullReference)]
        public Group Group { get; set; }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (Entity.HasValue)
            {
                var entityId = Entity.ToString();
                if (HasValue(Group))
                {
                    keys.Add(entityId + Group.GetIdCode());
                    if (HasValue(Group.Split))
                    {
                        keys.Add(entityId + Group.Split.GetIdCode());
                    }
                }
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}