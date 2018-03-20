#region Using

using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Owner
{
    [DataContract]
    public class PostBondPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<PostBond>> PostBonds { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public PostPredicate PostPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public PostGroupPredicate PostGroupPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Post bond")]
    [DatabaseMapping(StoredProcedure = "[Owner.Post].[Bond.Action]")]
    public class PostBond : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Post bond post")]
        [UndefinedValues(ConstantType.NullReference)]
        public Post Post { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Post bond group")]
        [UndefinedValues(ConstantType.NullReference)]
        public PostGroup PostGroup { get; set; }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(Post))
            {
                var postId = Post.GetIdCode();
                if (HasValue(PostGroup))
                {
                    keys.Add(postId + PostGroup.GetIdCode());
                    if (HasValue(PostGroup.PostSplit))
                    {
                        keys.Add(postId + PostGroup.PostSplit.GetIdCode());
                    }
                }
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}