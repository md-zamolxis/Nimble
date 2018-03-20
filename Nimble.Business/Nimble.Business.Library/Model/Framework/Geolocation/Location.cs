#region Using

using System.Collections.Generic;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Library.Model.Framework.Geolocation
{
    [DataContract]
    public class LocationPredicate : GenericPredicate
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Countries { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Regions { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> Cities { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> PostalCodes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> MetroCodes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<string>> AreaCodes { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public Criteria<List<Location>> Locations { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public BlockPredicate BlockPredicate { get; set; }

        #endregion Properties

        #endregion Public Members
    }

    [DataContract]
    [DisplayName("Location")]
    [DatabaseMapping(StoredProcedure = "[Geolocation].[Location.Action]")]
    public class Location : GenericEntity
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LocationCode")]
        [DisplayName("Location code")]
        [UndefinedValues(ConstantType.NullReference)]
        public long? Code { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LocationCountry")]
        [DisplayName("Location country")]
        [UndefinedValues(ConstantType.NullReference | ConstantType.StringEmptyTrimEnd)]
        public string Country { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LocationRegion")]
        [DisplayName("Location region")]
        public string Region { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LocationCity")]
        [DisplayName("Location city")]
        public string City { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LocationPostalCode")]
        [DisplayName("Location postal code")]
        public string PostalCode { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LocationLatitude")]
        [DisplayName("Location latitude")]
        [UndefinedValues(ConstantType.NullReference)]
        public decimal? Latitude { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LocationLongitude")]
        [DisplayName("Location longitude")]
        [UndefinedValues(ConstantType.NullReference)]
        public decimal? Longitude { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LocationMetroCode")]
        [DisplayName("Location metro code")]
        public string MetroCode { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DatabaseColumn(Name = "LocationAreaCode")]
        [DisplayName("Location area code")]
        public string AreaCode { get; set; }

        [DataMember(EmitDefaultValue = false)]
        [DisplayName("Validation message")]
        public string ValidationMessage { get; set; }

        public static XsdGeneric XsdGeneric
        {
            get
            {
                return new XsdGeneric
                           {
                               ParentEntry = "Locations",
                               RootEntry = "Location",
                               ParentError = "Errors",
                               RootError = "Error",
                               TargetNamespace = "http://tempuri.org//Locations",
                               Input = "Input",
                               ValidationMessage = "ValidationMessage",
                               Portion = 1000,
                               Nodes = new List<XsdNode>
                                           {
                                               new XsdNode {Name = "Code", Index = 0},
                                               new XsdNode {Name = "Country", Index = 1},
                                               new XsdNode {Name = "Region", Index = 2},
                                               new XsdNode {Name = "City", Index = 3},
                                               new XsdNode {Name = "PostalCode", Index = 4},
                                               new XsdNode {Name = "Latitude", Index = 5},
                                               new XsdNode {Name = "Longitude", Index = 6},
                                               new XsdNode {Name = "MetroCode", Index = 7},
                                               new XsdNode {Name = "AreaCode", Index = 8}
                                           }
                           };
            }
        }

        [DataMember(EmitDefaultValue = false)]
        public const string XsdSchema = @"<?xml version=""1.0"" encoding=""utf-8""?>
                                            <xs:schema 
                                            attributeFormDefault=""unqualified""
                                            elementFormDefault=""qualified""
                                            targetNamespace=""http://tempuri.org//Locations""
                                            xmlns:xs=""http://www.w3.org/2001/XMLSchema"" >
                                                        <xs:element name=""Location"">
                                                            <xs:complexType>
                                                                <xs:all>
                                                                    <xs:element name=""Code""       type=""xs:long""    minOccurs=""1"" maxOccurs=""1"" />
                                                                    <xs:element name=""Country""    type=""xs:string""  minOccurs=""1"" maxOccurs=""1"" />
                                                                    <xs:element name=""Region""     type=""xs:string""  minOccurs=""0"" maxOccurs=""1"" />
                                                                    <xs:element name=""City""       type=""xs:string""  minOccurs=""0"" maxOccurs=""1"" />
                                                                    <xs:element name=""PostalCode"" type=""xs:string""  minOccurs=""0"" maxOccurs=""1"" />
                                                                    <xs:element name=""Latitude""   type=""xs:decimal"" minOccurs=""1"" maxOccurs=""1"" />
                                                                    <xs:element name=""Longitude""  type=""xs:decimal"" minOccurs=""1"" maxOccurs=""1"" />
                                                                    <xs:element name=""MetroCode""  type=""xs:string""  minOccurs=""0"" maxOccurs=""1"" />
                                                                    <xs:element name=""AreaCode""   type=""xs:string""  minOccurs=""0"" maxOccurs=""1"" />
                                                                </xs:all>
                                                            </xs:complexType>
                                                        </xs:element>
                                            </xs:schema>";

        #endregion Properties

        #region Methods

        public override List<string> GetNaturalKeys()
        {
            var keys = new List<string>();
            if (Code.HasValue)
            {
                keys.Add(Code.ToString());
            }
            return keys;
        }

        #endregion Methods

        #endregion Public Members
    }
}