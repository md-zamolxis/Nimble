#region Usings

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using System.Text;
using System.Text.RegularExpressions;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model.Framework.Security;

#endregion Usings

namespace Nimble.Business.Library.Model
{
    [DataContract]
    public enum EntityActionType
    {
        [EnumMember]
        [FieldCategory(Name = "none")]
        None,
        [EnumMember]
        [FieldCategory(Name = "create")]
        Create,
        [EnumMember]
        [FieldCategory(Name = "update")]
        Update,
        [EnumMember]
        [FieldCategory(Name = "delete")]
        Delete,
        [EnumMember]
        [FieldCategory(Name = "save")]
        Save
    }

    [DataContract]
    public abstract class GenericEntity
    {
        #region Protected Members

        #region Properties

        protected Guid? id;
        protected string code;
        protected double? latitude;
        protected double? longitude;
        protected double? distance;
        protected DateTimeOffset? createdOn;
        protected DateTimeOffset? updatedOn;
        protected DateTimeOffset? deletedOn;
        protected byte[] version;
        protected EntityActionType entityActionType;
        protected GenericEntity previous;

        #endregion Properties

        #endregion Protected Members

        #region Public Members

        #region Methods

        public bool Equals(GenericEntity genericEntity)
        {
            var equals = false;
            if (id.HasValue &&
                HasValue(genericEntity) &&
                GetType() == genericEntity.GetType())
            {
                equals = id.Equals(genericEntity.id);
            }
            return equals;
        }

        public static bool HasValue(GenericEntity genericEntity)
        {
            return genericEntity != null && genericEntity.id.HasValue;
        }

        public static bool EmailIsValid(string email, bool isNullable)
        {
            var isValid = isNullable;
            email = (email ?? string.Empty).Trim();
            isValid = isValid && string.IsNullOrEmpty(email);
            if (!isValid)
            {
                isValid = Regex.Match(email, Constants.EMAIL_VALIDATION_PATTERN, RegexOptions.IgnoreCase).Success;
            }
            return isValid;
        }

        public static FaultExceptionDetail StringValidate(string name, string value)
        {
            var faultExceptionDetail = new FaultExceptionDetail();
            if (!string.IsNullOrEmpty(value) && 
                value.Length > Constants.STRING_CODE_MAX_LENGTH)
            {
                faultExceptionDetail.Code = Constants.STRING_CODE_MAX_WARNING;
                faultExceptionDetail.Parameters = new object[]
                {
                    name,
                    Constants.STRING_CODE_MAX_LENGTH,
                    value
                };
            }
            return faultExceptionDetail;
        }

        public static bool IpAddressIsValid(string ipData, bool isNullable)
        {
            var isValid = isNullable;
            ipData = (ipData ?? string.Empty).Trim();
            isValid = isValid && string.IsNullOrEmpty(ipData);
            if (!isValid)
            {
                isValid = Regex.Match(ipData, Constants.IP_VALIDATION_PATTERN, RegexOptions.IgnoreCase).Success;
            }
            return isValid;
        }

        public virtual Guid? GetId()
        {
            return id;
        }

        public virtual void SetId(Guid? guid)
        {
            id = guid;
        }

        public virtual string GetIdCode()
        {
            return id.HasValue ? id.Value.ToString() : string.Empty;
        }

        public virtual byte[] GetVersion()
        {
            return version;
        }

        public virtual void SetVersion(byte[] bytes)
        {
            version = bytes;
        }

        public virtual GenericEntity GetPrevious()
        {
            return previous;
        }

        public virtual void SetPrevious(GenericEntity genericEntity)
        {
            previous = genericEntity;
        }

        public virtual List<string> GetNaturalKeys()
        {
            return new List<string>();
        }

        public virtual FaultExceptionDetail Validate()
        {
            return new FaultExceptionDetail();
        }

        public virtual void SetDefaults()
        {
        }

        public virtual GenericEntity Clone()
        {
            return this;
        }

        public T Clone<T>() where T : GenericEntity
        {
            return (T)Clone();
        }

        public T Reduce<T>() where T : GenericEntity, new()
        {
            var entity = (T)this;
            if (id.HasValue)
            {
                entity = new T
                    {
                        id = id
                    };
            }
            return entity;
        }

        public static void SetGenericEntity(bool exists, GenericEntity to, GenericEntity from)
        {
            if (!exists ||
                to == null ||
                from == null ||
                to.GetType() != from.GetType()) return;
            to.SetId(from.GetId());
            to.SetVersion(from.GetVersion());
        }

        public static void SetGenericEntity(GenericEntity to, GenericEntity from)
        {
            SetGenericEntity(true, to, from);
        }

        public static Tuple<double, double> GetCoordinates(string geospatial)
        {
            Tuple<double, double> coordinates = null;
            if (!string.IsNullOrWhiteSpace(geospatial))
            {
                coordinates = GetCoordinates(geospatial.Split(Constants.COMMA));
            }
            return coordinates;
        }

        public static Tuple<double, double> GetCoordinates(string[] data)
        {
            Tuple<double, double> coordinates = null;
            double latitude;
            double longitude;
            if (data != null &&
                data.Length == 2 &&
                double.TryParse(data[0], out latitude) &&
                double.TryParse(data[1], out longitude))
            {
                coordinates = new Tuple<double, double>(latitude, longitude);
            }
            return coordinates;
        }

        public void SetCoordinates(Token token)
        {
            var coordinates = GetCoordinates(token.ClientGeospatial);
            if (coordinates == null ||
                distance.HasValue ||
                !latitude.HasValue ||
                !longitude.HasValue) return;
            distance = CalculateDistance(coordinates, new Tuple<double, double>(latitude.Value, longitude.Value));
        }

        public static double? CalculateDistance(Tuple<double, double> pointA, Tuple<double, double> pointB)
        {
            double? calculate = null;
            if (pointA != null &&
                pointB != null)
            {
                var latitudeA = Math.PI*pointA.Item1/180;
                var latitudeB = Math.PI*pointB.Item1/180;
                var theta = Math.PI*(pointA.Item2 - pointB.Item2)/180;
                calculate = Math.Sin(latitudeA)*Math.Sin(latitudeB) + Math.Cos(latitudeA)*Math.Cos(latitudeB)*Math.Cos(theta);
                calculate = Math.Acos(calculate.Value);
                calculate = calculate*180/Math.PI;
                calculate = calculate*60*1.1515;
            }
            return calculate;
        }

        public static string StringToBase64(string value)
        {
            if (!string.IsNullOrEmpty(value))
            {
                value = Convert.ToBase64String(Encoding.UTF8.GetBytes(value));
            }
            return value;
        }

        public static bool IsBase64String(string value)
        {
            var isBase64String = false;
            if (!string.IsNullOrEmpty(value))
            {
                isBase64String = (value.Length % 4 == 0) && Regex.IsMatch(value, Constants.BASE64_VALIDATION_PATTERN, RegexOptions.None);
            }
            return isBase64String;

        }

        public static string Base64ToString(string value)
        {
            if (IsBase64String(value))
            {
                var bytes = Convert.FromBase64String(value);
                value = Encoding.UTF8.GetString(bytes, 0, bytes.Length);
            }
            else
            {
                value = null;
            }
            return value;
        }

        public static string GuidToBase64(Guid? guid)
        {
            string value = null;
            if (guid.HasValue)
            {
                value = StringToBase64(guid.Value.ToString());
            }
            return value;
        }

        public static Guid? Base64ToGuid(string value)
        {
            Guid? guid = null;
            value = Base64ToString(value);
            Guid parse;
            if (Guid.TryParse(value, out parse))
            {
                guid = parse;
            }
            return guid;
        }

        #endregion Methods

        #endregion Public Members
    }
}