#region Using

using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;
using System.Xml;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.DataAccess;
using Nimble.Business.Library.Model;
using Nimble.Business.Library.Model.Framework.Geolocation;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.DataAccess.MsSql2008.Framework;
using Nimble.Business.Engine.Core;
using Nimble.Business.Service.Core;

#endregion Using

namespace Nimble.Business.Logic.Framework
{
    public class GeolocationLogic : GenericLogic
    {
        #region Private Members

        #region Properties

        private static readonly GeolocationLogic instance = new GeolocationLogic();

        #endregion Properties

        #region Methods

        private Source SourceModify(Source source)
        {
            var sourceEntity = SourceRead(new Source
            {
                Id = source.Id,
                Code = source.Code
            });
            if (GenericEntity.HasValue(sourceEntity) &&
                sourceEntity.ApprovedOn.HasValue)
            {
                ThrowException("Cannot modify - source has been approved on {0}.", sourceEntity.ApprovedOn);
            }
            return sourceEntity;
        }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        internal static GeolocationLogic Instance
        {
            get { return instance; }
        }

        #endregion Properties

        #region Methods

        public static GeolocationLogic InstanceCheck(PermissionType permissionType)
        {
            GenericCheck(permissionType);
            return instance;
        }

        #region Sources

        public Source SourceCreate(Source source)
        {
            EntityPropertiesCheck(
                source,
                "Code",
                "SourceInputType",
                "Input");
            source.CreatedOn = DateTimeOffset.Now;
            source.ApprovedOn = null;
            var portions = new List<Portion>();
            if (source.InputStream == null)
            {
                source.Input = null;
                source.Errors = null;
            }
            else
            {
                XsdGeneric xsdGeneric = null;
                string xsdSchema = null;
                switch (source.SourceInputType)
                {
                    case SourceInputType.MaxMindLocations:
                    {
                        xsdGeneric = Location.XsdGeneric;
                        xsdSchema = Location.XsdSchema;
                        break;
                    }
                    case SourceInputType.MaxMindBlocks:
                    {
                        xsdGeneric = Block.XsdGeneric;
                        xsdSchema = Block.XsdSchema;
                        break;
                    }
                }
                if (xsdGeneric != null)
                {
                    var pathEntries = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
                    var pathErrors = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString());
                    var fileStreamEntries = new FileStream(pathEntries, FileMode.Create, FileAccess.Write);
                    var fileStreamErrors = new FileStream(pathErrors, FileMode.Create, FileAccess.Write);
                    var xmlWriterSettings = new XmlWriterSettings {OmitXmlDeclaration = true, Indent = true};
                    var xmlWriterEntries = XmlWriter.Create(fileStreamEntries, xmlWriterSettings);
                    var xmlWriterErrors = XmlWriter.Create(fileStreamErrors, xmlWriterSettings);
                    xmlWriterEntries.WriteStartElement(xsdGeneric.ParentEntry);
                    xmlWriterErrors.WriteStartElement(xsdGeneric.ParentError);
                    var regex = new Regex(Constants.CSV_REGEX_EXPRESSION, RegexOptions.IgnorePatternWhitespace);
                    var entriesLoaded = 0;
                    using (var streamReader = new StreamReader(source.InputStream))
                    {
                        var values = new List<string>();
                        source.EntriesLoaded = source.ErrorsLoaded = 0;
                        while (!streamReader.EndOfStream)
                        {
                            if (xsdGeneric.Portion > 0 &&
                                entriesLoaded == xsdGeneric.Portion)
                            {
                                xmlWriterEntries.WriteEndElement();
                                xmlWriterEntries.Flush();
                                xmlWriterEntries.Close();
                                fileStreamEntries.Close();
                                var streamReaderPortionEntries = new StreamReader(pathEntries);
                                portions.Add(new Portion {Entries = streamReaderPortionEntries.ReadToEnd(), EntriesLoaded = entriesLoaded});
                                streamReaderPortionEntries.Close();
                                fileStreamEntries = new FileStream(pathEntries, FileMode.Create, FileAccess.Write);
                                xmlWriterEntries = XmlWriter.Create(fileStreamEntries, xmlWriterSettings);
                                xmlWriterEntries.WriteStartElement(xsdGeneric.ParentEntry);
                                source.EntriesLoaded += entriesLoaded;
                                entriesLoaded = 0;
                            }
                            values.Clear();
                            var input = streamReader.ReadLine();
                            if (input != null)
                            {
                                foreach (Match match in regex.Matches(input))
                                {
                                    if (!match.Success) continue;
                                    foreach (Capture capture in match.Groups[Constants.CSV_COLUMN_NAME].Captures)
                                    {
                                        values.Add(capture.Value);
                                    }
                                }
                            }
                            var xmlDocument = new XmlDocument();
                            var entry = xmlDocument.CreateElement(xsdGeneric.RootEntry);
                            xmlDocument.AppendChild(entry);
                            foreach (var node in xsdGeneric.Nodes)
                            {
                                if (node.Index >= values.Count) continue;
                                var value = node.Index < 0 ? node.Default : values[node.Index].Trim();
                                if (string.IsNullOrEmpty(value)) continue;
                                var property = xmlDocument.CreateElement(node.Name);
                                property.AppendChild(xmlDocument.CreateTextNode(value));
                                entry.AppendChild(property);
                            }
                            if (string.IsNullOrEmpty(xsdSchema))
                            {
                                xmlDocument.WriteTo(xmlWriterEntries);
                                entriesLoaded++;
                            }
                            else
                            {
                                var validation = new XmlDocument();
                                validation.LoadXml(xmlDocument.OuterXml);
                                validation.Schemas.Add(xsdGeneric.TargetNamespace, XmlReader.Create(new StringReader(xsdSchema)));
                                if (validation.DocumentElement == null) continue;
                                validation.DocumentElement.SetAttribute(Constants.XML_NAMESPACE_ATTRIBUTE_NAME, xsdGeneric.TargetNamespace);
                                XmlValidationMessage = null;
                                validation.LoadXml(validation.OuterXml);
                                validation.Validate(XmlValidationEventHandler);
                                if (string.IsNullOrEmpty(XmlValidationMessage))
                                {
                                    xmlDocument.WriteTo(xmlWriterEntries);
                                    entriesLoaded++;
                                }
                                else
                                {
                                    xmlDocument = new XmlDocument();
                                    entry = xmlDocument.CreateElement(xsdGeneric.RootError);
                                    xmlDocument.AppendChild(entry);
                                    var property = xmlDocument.CreateElement(xsdGeneric.Input);
                                    property.AppendChild(xmlDocument.CreateTextNode(input));
                                    entry.AppendChild(property);
                                    property = xmlDocument.CreateElement(xsdGeneric.ValidationMessage);
                                    property.AppendChild(xmlDocument.CreateTextNode(XmlValidationMessage));
                                    entry.AppendChild(property);
                                    xmlDocument.WriteTo(xmlWriterErrors);
                                    source.ErrorsLoaded++;
                                }
                            }
                        }
                    }
                    xmlWriterEntries.WriteEndElement();
                    xmlWriterEntries.Flush();
                    xmlWriterEntries.Close();
                    fileStreamEntries.Close();
                    var streamReaderEntries = new StreamReader(pathEntries);
                    portions.Add(new Portion {Entries = streamReaderEntries.ReadToEnd(), EntriesLoaded = entriesLoaded});
                    streamReaderEntries.Close();
                    source.EntriesLoaded += entriesLoaded;
                    xmlWriterErrors.WriteEndElement();
                    xmlWriterErrors.Flush();
                    xmlWriterErrors.Close();
                    fileStreamErrors.Close();
                    var streamReaderErrors = new StreamReader(pathErrors);
                    source.Errors = streamReaderErrors.ReadToEnd();
                    streamReaderErrors.Close();
                }
            }
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GeolocationDatabase}, new List<LockType> {LockType.Source});
                source = GeolocationSql.Instance.SourceCreate(source);
                foreach (var portion in portions)
                {
                    portion.Source = source;
                    GeolocationSql.Instance.PortionCreate(portion);
                }
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return source;
        }

        public Source SourceRead(Source source)
        {
            EntityInstanceCheck(source);
            return GeolocationSql.Instance.SourceRead(source);
        }

        public Source SourceUpdate(Source source)
        {
            EntityPropertiesCheck(
                source,
                "Code");
            SourceModify(source);
            source.ApprovedOn = null;
            source.InputStream = null;
            source.Errors = null;
            return GeolocationSql.Instance.SourceUpdate(source);
        }

        public bool SourceDelete(Source source)
        {
            EntityInstanceCheck(source);
            return GeolocationSql.Instance.SourceDelete(source);
        }

        public GenericOutput<Source> SourceSearch(SourcePredicate sourcePredicate)
        {
            return GeolocationSql.Instance.SourceSearch(GenericInputCheck<Source, SourcePredicate>(sourcePredicate));
        }

        public Source SourceLoad(Source source)
        {
            EntityInstanceCheck(source);
            return GeolocationSql.Instance.SourceLoad(source);
        }

        public Source SourceApprove(Source source)
        {
            EntityPropertiesCheck(
                source,
                "Code");
            SourceModify(source);
            source.ApprovedOn = DateTimeOffset.Now;
            try
            {
                TransactionBegin(new[] {Kernel.Instance.ServerConfiguration.GeolocationDatabase}, new List<LockType> {LockType.Source});
                source = GeolocationSql.Instance.SourceUpdate(source);
                GeolocationSql.Instance.SourceApprove(source);
                TransactionComplete();
            }
            catch (Exception exception)
            {
                TransactionRollback(exception);
            }
            return source;
        }

        #endregion Sources

        #region Locations

        public GenericOutput<Location> LocationSearch(LocationPredicate locationPredicate)
        {
            return GeolocationSql.Instance.LocationSearch(GenericInputCheck<Location, LocationPredicate>(locationPredicate));
        }

        #endregion Locations

        #region Blocks

        public Block BlockRead(Block block)
        {
            EntityInstanceCheck(block);
            return GeolocationSql.Instance.BlockRead(block);
        }

        public GenericOutput<Block> BlockSearch(BlockPredicate blockPredicate)
        {
            return GeolocationSql.Instance.BlockSearch(GenericInputCheck<Block, BlockPredicate>(blockPredicate));
        }

        #endregion Blocks

        #endregion Methods

        #endregion Public Members
    }
}