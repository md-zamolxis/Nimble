#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model.Framework.Geolocation;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Owner
{
    [DataContract]
    public class RangePredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Codes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<long?>> IpNumbers { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> IpDataFrom { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> IpDataTo { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<DateInterval> LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Descriptions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Range>> Ranges { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public BranchPredicate BranchPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Range")]
    [DatabaseMapping(StoredProcedure = "[Owner].[Range.Action]")]
    public class Range : GenericEntity
    {
        #region Private Members

        #region Properties

        private long? ipNumberFrom;
        private long? ipNumberTo;

        #endregion Properties

        #endregion Private Members

        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "RangeId", IsIdentity = true)]
        [DisplayName("Range id")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.GuidEmpty)]
        public Guid? Id
        {
            get { return id; }
            set { id = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Range branch")]
        [UndefinedValues(ConstantType.NullReference)]
        public Branch Branch { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "RangeCode")]
        [DisplayName("Range code")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Code
        {
            get { return code; }
            set { code = value; }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "RangeIpDataFrom")]
        [DisplayName("Range Ip data from")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string IpDataFrom { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "RangeIpDataTo")]
        [DisplayName("Range Ip data to")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string IpDataTo { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "RangeIpNumberFrom")]
        [DisplayName("Range Ip number from")]
        public long? IpNumberFrom 
        { 
            get
            {
                ipNumberFrom = Block.GetIpNumber(IpDataFrom);
                return ipNumberFrom;
            }
            set
            {
                ipNumberFrom = value;
            }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "RangeIpNumberTo")]
        [DisplayName("Range Ip number to")]
        public long? IpNumberTo
        {
            get
            {
                ipNumberTo = Block.GetIpNumber(IpDataTo);
                return ipNumberTo;
            }
            set
            {
                ipNumberTo = value;
            }
        }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "RangeLockedOn")]
        [DisplayName("Range locked on")]
        public DateTimeOffset? LockedOn { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "RangeDescription")]
        [DisplayName("Range description")]
        public string Description { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "RangeVersion")]
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
            if (HasValue(Branch) &&
                !string.IsNullOrEmpty(Code))
            {
                keys.Add(Branch.GetIdCode() + Code.ToUpper());
            }
            return keys;
        }

        public override FaultExceptionDetail Validate()
        {
            var faultExceptionDetail = new FaultExceptionDetail();
            if (!IpAddressIsValid(IpDataFrom, false))
            {
                faultExceptionDetail.Items.Add(new FaultExceptionDetail("Range from address not valid."));
            }
            if (!IpAddressIsValid(IpDataTo, false))
            {
                faultExceptionDetail.Items.Add(new FaultExceptionDetail("Range to address not valid."));
            }
            return faultExceptionDetail;
        }

        #endregion Methods

        #endregion Public Members
    }
}