#region Usings

using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Owner;
using Nimble.Business.Library.Model.Framework.Security;

#endregion Usings

namespace Nimble.Business.Library.DataAccess
{
    [DataContract]
    public class GenericInput<T, P> where T : GenericEntity where P : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public PermissionType PermissionType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public T Entity { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public P Predicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Emplacement Emplacement { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Application Application { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Person Person { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public List<Organisation> Organisations { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public List<Branch> Branches { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public double Latitude { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public double Longitude { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}