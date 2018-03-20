#region Using

using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using Nimble.Business.Library.Attributes;

#endregion Using

namespace Nimble.Business.Library.Common
{
    [DataContract]
    public enum FaultExceptionDetailType
    {
        [EnumMember]
        [FieldCategory(Name = "undefined")]
        Undefined,
        [EnumMember]
        [FieldCategory(Name = "expired", Description = "Session expired.")]
        Expired,
        [EnumMember]
        [FieldCategory(Name = "unauthorised", Description = "User is not logged.")]
        Unauthorised,
        [EnumMember]
        [FieldCategory(Name = "invalid", Description = "Invalid user or password.")]
        Invalid,
        [EnumMember]
        [FieldCategory(Name = "locked", Description = "User is locked due password expiration.")]
        Locked
    }

    [DataContract]
    public class FaultExceptionDetail
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public FaultExceptionDetailType FaultExceptionDetailType { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string Code { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public object[] Parameters { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string Message { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool Translated { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool Untranslatable { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public bool Unhandled { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string PropertyName { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string ControlName { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public List<FaultExceptionDetail> Items { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string Details { get; set; }

        #endregion Properties

        #region Methods

        public FaultExceptionDetail()
        {
            Items = new List<FaultExceptionDetail>();
        }

        public FaultExceptionDetail(FaultExceptionDetailType faultExceptionDetailType, params object[] parameters) : this()
        {
            FaultExceptionDetailType = faultExceptionDetailType;
            Code = FaultExceptionDetailType.ToString();
            var customAttribute = ClientStatic.GetCustomAttribute<FieldCategory>(ClientStatic.FaultExceptionDetailType.GetField(Code), true);
            if (customAttribute != null)
            {
                Code = string.IsNullOrEmpty(customAttribute.Description) ? customAttribute.Name : customAttribute.Description;
            }
            Parameters = parameters;
            Message = string.Format(Code, Parameters);
        }

        public FaultExceptionDetail(string code, params object[] parameters) : this()
        {
            Code = code;
            Parameters = parameters;
            Message = string.Format(Code, Parameters);
        }

        public static FaultException Create(FaultExceptionDetail faultExceptionDetail)
        {
            if (faultExceptionDetail == null)
            {
                faultExceptionDetail = new FaultExceptionDetail();
            }
            if (string.IsNullOrEmpty(faultExceptionDetail.Message))
            {
                faultExceptionDetail.Message = faultExceptionDetail.Parameters == null ? faultExceptionDetail.Code : string.Format(faultExceptionDetail.Code, faultExceptionDetail.Parameters);
            }
            if (faultExceptionDetail.Parameters != null)
            {
                faultExceptionDetail.Parameters = faultExceptionDetail.Parameters.Where(item => item != null).Select(item => item.ToString()).Cast<object>().ToArray();
            }
            return new FaultException(new FaultReason(faultExceptionDetail.Message), new FaultCode(faultExceptionDetail.Code, ClientStatic.XmlSerialize(faultExceptionDetail)), string.Empty);
        }

        public static FaultExceptionDetail Create(Exception exception)
        {
            FaultExceptionDetail faultExceptionDetail = null;
            var faultException = exception as FaultException;
            if (faultException == null)
            {
                faultExceptionDetail = new FaultExceptionDetail(Constants.UNHANDLED_ERROR, exception.Message)
                {
                    Unhandled = true
                };
            }
            else
            {
                var unhandled = true;
                if (faultException.Code != null &&
                    !string.IsNullOrEmpty(faultException.Code.Namespace))
                {
                    try
                    {
                        faultExceptionDetail = new FaultExceptionDetail();
                        faultExceptionDetail = ClientStatic.XmlDeserialize<FaultExceptionDetail>(faultException.Code.Namespace);
                        faultExceptionDetail.Details = string.Empty;
                        foreach (var item in faultExceptionDetail.Items)
                        {
                            faultExceptionDetail.Details += item.Message + Constants.LINE_FEED;
                        }
                        unhandled = false;
                    }
                    catch
                    {
                    }
                }
                if (unhandled)
                {
                    faultExceptionDetail = new FaultExceptionDetail(faultException.Message)
                    {
                        Untranslatable = true,
                        Unhandled = true
                    };
                }
            }
            return faultExceptionDetail;
        }

        #endregion Methods

        #endregion Public Members
    }
}