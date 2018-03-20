#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Geolocation
{
    [DataContract]
    public class BlockPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<long?>> IpNumbers { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> IpDataFrom { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> IpDataTo { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Block>> Blocks { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public LocationPredicate LocationPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Block")]
    [DatabaseMapping(StoredProcedure = "[Geolocation].[Block.Action]")]
    public class Block : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BlockIPNumberFrom")]
        [DisplayName("Block IP number from")]
        [UndefinedValues(ConstantType.NullReference)]
        public long? IpNumberFrom { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BlockIPNumberTo")]
        [DisplayName("Block IP number to")]
        [UndefinedValues(ConstantType.NullReference)]
        public long? IpNumberTo { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Block location")]
        [UndefinedValues(ConstantType.NullReference)]
        public Location Location { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BlockIPDataFrom")]
        [DisplayName("Block IP data from")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string IpDataFrom { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "BlockIPDataTo")]
        [DisplayName("Block IP data to")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string IpDataTo { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Validation message")]
        public string ValidationMessage { get; set; }

        public static XsdGeneric XsdGeneric
        {
            get
            {
                return new XsdGeneric
                           {
                               ParentEntry = "Blocks",
                               RootEntry = "Block",
                               ParentError = "Errors",
                               RootError = "Error",
                               TargetNamespace = "http://tempuri.org//Blocks",
                               Input = "Input",
                               ValidationMessage = "ValidationMessage",
                               Portion = 2000,
                               Nodes = new List<XsdNode>
                                           {
                                               new XsdNode {Name = "IPNumberFrom", Index = 0},
                                               new XsdNode {Name = "IPNumberTo", Index = 1},
                                               new XsdNode {Name = "LocationCode", Index = 2}
                                           }
                           };
            }
        }

        [DataMember(EmitDefaultValue = false)]
        public const string XsdSchema = @"<?xml version=""1.0"" encoding=""utf-8""?>
                                            <xs:schema 
                                            attributeFormDefault=""unqualified""
                                            elementFormDefault=""qualified""
                                            targetNamespace=""http://tempuri.org//Blocks""
                                            xmlns:xs=""http://www.w3.org/2001/XMLSchema"" >
                                                        <xs:element name=""Block"">
                                                            <xs:complexType>
                                                                <xs:all>
                                                                    <xs:element name=""IPNumberFrom""   type=""xs:long""    minOccurs=""1"" maxOccurs=""1"" />
                                                                    <xs:element name=""IPNumberTo""     type=""xs:long""    minOccurs=""1"" maxOccurs=""1"" />
                                                                    <xs:element name=""LocationCode""   type=""xs:long""    minOccurs=""1"" maxOccurs=""1"" />
                                                                </xs:all>
                                                            </xs:complexType>
                                                        </xs:element>
                                            </xs:schema>";

        #endregion Properties

        #region Methods

        public static long? GetIpNumber(string ipValue)
        {
            long? ipNumber = null;
            if (!string.IsNullOrEmpty(ipValue))
            {
                ipNumber = 0;
                var numbers = ipValue.Split(Constants.POINT);
                const int subnetMask = byte.MaxValue + 1;
                for (var index = numbers.Length - 1; index >= 0; index--)
                {
                    long number;
                    if (long.TryParse(numbers[index], out number))
                    {
                        ipNumber += number*(long) Math.Pow(subnetMask, numbers.Length - index - 1);
                    }
                    else
                    {
                        ipNumber = null;
                        break;
                    }
                }
            }
            return ipNumber;
        }

        public static string GetIpValue(long ipNumber)
        {
            var ip = string.Empty;
            const int subnetMask = byte.MaxValue + 1;
            var index = (int)Math.Log(ipNumber, subnetMask);
            while (index >= 0)
            {
                var subnetOrder = (long)Math.Pow(subnetMask, index);
                var number = ipNumber / subnetOrder;
                ip += number;
                ipNumber -= number * subnetOrder;
                index--;
                if (index >= 0)
                {
                    ip += Constants.POINT;
                }
            }
            return ip;
        }

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (IpNumberFrom.HasValue &&
                IpNumberTo.HasValue)
            {
                keys.Add(IpNumberFrom.ToString() + IpNumberTo);
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}