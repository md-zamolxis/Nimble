#region Usings

using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;

#endregion Usings

namespace Nimble.Business.Library.Model.Framework.Security
{
    [DataContract]
    public enum LogActionType
    {
        [EnumMember]
        [FieldCategory(Name = "undefined", Description = "emplacement - [{0}]; application - [{1}]; client host - [{2}]; user - [{3}]; request host - [{4}]; request port - [{5}]; start - [{6}]; end - [{7}]; duration - [{8}]; ")]
        Undefined,
        [EnumMember]
        [FieldCategory(Name = "query delay", Description = "command - [{0}]; parameters - [{1}]; duration - [{2}]; start - [{3}]; end - [{4}]; emplacement - [{5}]; application - [{6}]; client host - [{7}]; user - [{8}]; request host - [{9}]; request port - [{10}].")]
        SqlCommandDelay,
        [EnumMember]
        [FieldCategory(Name = "login success")]
        LoginSuccess,
        [EnumMember]
        [FieldCategory(Name = "sign in organisation", Description = "organisation - [{0}].")]
        SignInOrganisation,
        [EnumMember]
        [FieldCategory(Name = "login fault", Description = "code - [{0}]; password - [{1}].")]
        LoginFault,
        [EnumMember]
        [FieldCategory(Name = "login locked", Description = "code - [{0}]; locked on - [{1}].")]
        LoginLocked,
        [EnumMember]
        [FieldCategory(Name = "logout")]
        Logout,
        [EnumMember]
        [FieldCategory(Name = "page", Description = "page - [{0}].")]
        Page
    }

    [DataContract]
    public class LogPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<LogActionType>> LogActionTypes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Comments { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Log>> Logs { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public ApplicationPredicate ApplicationPredicate { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public AccountPredicate AccountPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Log")]
    [DatabaseMapping(StoredProcedure = "[Security].[Log.Action]")]
    public class Log : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LogId", IsIdentity = true)]
        [DisplayName("Log id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Log application")]
        [UndefinedValues(ConstantType.NullReference)]
        public Application Application { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(DisableCaching = true, ForceValue = true)]
        [DisplayName("Log account")]
        public Account Account { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LogTokenId")]
        [DisplayName("Log token id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? TokenId { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LogCreatedOn")]
        [DisplayName("Log created on")]
        [UndefinedValues(ConstantType.NullReference)]
        public DateTimeOffset? CreatedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LogActionType")]
        [DisplayName("Log action type")]
        [UndefinedValues(LogActionType.Undefined)]
        public LogActionType LogActionType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LogComment")]
        [DisplayName("Log comment")]
        public string Comment { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LogParameters")]
        [DisplayName("Log parameters")]
        public string[] Parameters { get; set; }

        #endregion Properties

        #region Methods

        public void InsertParameters(object[] parameters)
        {
            var strings = new List<string>();
            if (parameters != null &&
                parameters.Length > 0)
            {
                strings.AddRange(parameters.Select(parameter => parameter == null ? string.Empty : parameter.ToString()));
            }
            InsertParameters(strings.ToArray());
        }

        public void InsertParameters(string[] parameters)
        {
            if (parameters == null || 
                parameters.Length == 0) return;
            if (Parameters == null ||
                Parameters.Length == 0)
            {
                Parameters = parameters;
            }
            else
            {
                var strings = new List<string>();
                strings.AddRange(parameters);
                strings.AddRange(Parameters);
                Parameters = strings.ToArray();
            }
        }

        #endregion Methods

        #endregion Public Members
    }
}