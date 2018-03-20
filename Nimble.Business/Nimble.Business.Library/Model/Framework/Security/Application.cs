#region Usings

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;

#endregion Usings

namespace Nimble.Business.Library.Model.Framework.Security
{
    [DataContract]
    public class ApplicationPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Descriptions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool? IsAdministrative { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Application>> Applications { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Application")]
    [DatabaseMapping(StoredProcedure = "[Security].[Application.Action]")]
    public class Application : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "ApplicationId", IsIdentity = true)]
        [DisplayName("Application id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "ApplicationCode")]
        [DisplayName("Application code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrim)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "ApplicationDescription")]
        [DisplayName("Application description")]
        public string Description { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "ApplicationIsAdministrative")]
        [DisplayName("Application is administrative")]
        public bool IsAdministrative { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "ApplicationVersion")]
        public byte[] Version
        {
            get { return version; }
            set { version = value; }
        }

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (!string.IsNullOrEmpty(Code))
            {
                keys.Add(Code.ToUpper());
            }
            return keys;
        }

        public override GenericEntity Clone()
        {
            return new Application
                {
                    Id = Id,
                    Code = Code
                };
        }

        #endregion Methods

        #endregion Public Members
    }
}