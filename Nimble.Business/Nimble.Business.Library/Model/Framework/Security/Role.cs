#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Security
{
    [DataContract]
    public class RolePredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Descriptions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Role>> Roles { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public EmplacementPredicate EmplacementPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public ApplicationPredicate ApplicationPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public PermissionPredicate PermissionPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public AccountPredicate AccountPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Role")]
    [DatabaseMapping(StoredProcedure = "[Security].[Role.Action]")]
    public class Role : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "RoleId", IsIdentity = true)]
        [DisplayName("Role id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Role emplacement")]
        [UndefinedValues(ConstantType.NullReference)]
        public Emplacement Emplacement { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Role application")]
        [UndefinedValues(ConstantType.NullReference)]
        public Application Application { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "RoleCode")]
        [DisplayName("Role code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmpty)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "RoleDescription")]
        [DisplayName("Role description")]
        public string Description { get; set;}

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "RoleVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Role permissions")]
        public List<Permission> Permissions { get; set; }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (HasValue(Emplacement) &&
                HasValue(Application) &&
                !string.IsNullOrEmpty(Code))
            {
                keys.Add(Emplacement.GetIdCode() + Application.GetIdCode() + Code.ToUpper());
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}