#region Using

using System.Collections.Generic;
using System.Runtime.Serialization;

#endregion Using

namespace Nimble.Business.Library.Common
{
    [DataContract]
    public class XsdNode
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public string Name { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public int Index { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string Default { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    public class XsdGeneric
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public string ParentEntry { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string RootEntry { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string ParentError { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string RootError { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string TargetNamespace { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string Input { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string ValidationMessage { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public long Portion { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public List<XsdNode> Nodes { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}