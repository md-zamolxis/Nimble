#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Common
{
    [DataContract]
    [DisplayName("Profile")]
    [DatabaseMapping(StoredProcedure = "[Common].[Profile.Action]")]
    public class Profile : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "ProfileId", IsIdentity = true)]
        [DisplayName("Profile id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Profile properties")]
        [UndefinedValues(ConstantType.NullReference)]
        public List<Property> Properties { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}