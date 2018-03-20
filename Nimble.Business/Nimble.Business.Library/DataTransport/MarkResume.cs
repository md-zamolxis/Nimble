#region Using

using System;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Owner;

#endregion Using

namespace Nimble.Business.Library.DataTransport
{
    [DataContract]
    [DatabaseMapping(DisableIndexing = true)]
    public class MarkResume : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MarkPersonId", AllowGrouping = true)]
        [DisplayName("Mark person")]
        public Person Person { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MarkEntityType", AllowGrouping = true)]
        [DisplayName("Mark entity type")]
        public MarkEntityType MarkEntityType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MarkEntityId", AllowGrouping = true)]
        [DisplayName("Mark entity id")]
        public Guid? EntityId { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MarkActionType", AllowGrouping = true)]
        [DisplayName("Mark action type")]
        public MarkActionType MarkActionType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "CreatedOn")]
        [DisplayName("Mark created on")]
        public int? CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "MarkCount")]
        [DisplayName("Mark count")]
        public int? Count { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}
