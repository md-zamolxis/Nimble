#region Usings

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Security;

#endregion Usings

namespace Nimble.Business.Library.DataAccess
{
    [DataContract]
    public class GenericOutput<T> where T : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public PermissionType PermissionType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public T Entity { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public List<T> Entities { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Pager Pager { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public DateTimeOffset QueryStart { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public DateTimeOffset QueryEnd { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}