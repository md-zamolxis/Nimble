#region Using

using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Owner
{
    [DataContract]
    public class BranchBondPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<BranchBond>> BranchBonds { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public BranchPredicate BranchPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public BranchGroupPredicate BranchGroupPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Branch bond")]
    [DatabaseMapping(StoredProcedure = "[Owner.Branch].[Bond.Action]")]
    public class BranchBond : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Branch bond branch")]
        [UndefinedValues(ConstantType.NullReference)]
        public Branch Branch { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Branch bond group")]
        [UndefinedValues(ConstantType.NullReference)]
        public BranchGroup BranchGroup { get; set; }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(Branch))
            {
                var branchId = Branch.GetIdCode();
                if (HasValue(BranchGroup))
                {
                    keys.Add(branchId + BranchGroup.GetIdCode());
                    if (HasValue(BranchGroup.BranchSplit))
                    {
                        keys.Add(branchId + BranchGroup.BranchSplit.GetIdCode());
                    }
                }
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}