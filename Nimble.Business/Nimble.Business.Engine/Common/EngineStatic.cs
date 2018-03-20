#region Usings

using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Web.Script.Serialization;
using System.Web.UI.WebControls;
using System.Xml;
using System.Xml.Serialization;
using Nimble.Business.Engine.Core;
using Nimble.Business.Library.Common;

#endregion Usings

namespace Nimble.Business.Engine.Common
{
    public class EngineStatic
    {
        #region Public

        #region Fields

        public static readonly Type ServerConfiguration = typeof(ServerConfiguration);

        #endregion Fields

        #region Methods

        #region Common

        public static Bitmap ResizeImage(Stream stream, int? inputWidth, int? inputHeight)
        {
            Bitmap output = null;
            var outputWidth = inputWidth.HasValue ? inputWidth.Value : Constants.DEFAULT_IMAGE_WIDTH;
            var outputHeight = inputHeight.HasValue ? inputHeight.Value : Constants.DEFAULT_IMAGE_HEIGHT;
            var input = new Bitmap(stream);
            if (input.Width >= outputWidth || input.Height >= outputHeight)
            {
                if (input.Width > input.Height)
                {
                    outputHeight = (int) (input.Height * (decimal) outputWidth / input.Width);
                }
                else
                {
                    outputWidth = (int) (input.Width * (decimal) outputHeight / input.Height);
                }
                output = new Bitmap(outputWidth, outputHeight);
                using (var graphics = Graphics.FromImage(output))
                {
                    graphics.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                    graphics.FillRectangle(Brushes.White, 0, 0, outputWidth, outputHeight);
                    graphics.DrawImage(input, 0, 0, outputWidth, outputHeight);
                }
            }
            return output;
        }

        public static string EncryptMd5(string value)
        {
            var stringBuilder = new StringBuilder();
            var md5CryptoServiceProvider = new MD5CryptoServiceProvider();
            var bytes = md5CryptoServiceProvider.ComputeHash(Encoding.UTF8.GetBytes(value ?? string.Empty));
            foreach (var item in bytes)
            {
                stringBuilder.Append(item.ToString("x2").ToLower());
            }
            return stringBuilder.ToString();
        }

        public static T SoapXmlClone<T>(T entity)
        {
            return (T) SoapXmlDeserialize(SoapXmlSerialize(entity), typeof(T));
        }

        public static T XmlClone<T>(T entity)
        {
            return (T) XmlDeserialize(XmlSerialize(entity), typeof(T));
        }

        public static void ComplementDropDownList(DropDownList dropDownList, bool hasEmptyItem)
        {
            var emptyItemIndex = -1;
            for (var index = 0; index < dropDownList.Items.Count; index++)
            {
                if (!string.IsNullOrEmpty(dropDownList.Items[index].Value)) continue;
                emptyItemIndex = index;
                break;
            }
            if (hasEmptyItem)
            {
                if (emptyItemIndex < 0)
                {
                    dropDownList.Items.Insert(0, new ListItem());
                    dropDownList.SelectedIndex = 0;
                }
            }
            else
            {
                if (emptyItemIndex >= 0)
                {
                    dropDownList.Items.RemoveAt(emptyItemIndex);
                }
            }
        }

        public static string RemoveXmlIllegalsCharacters(string value)
        {
            return Regex.Replace(value, Constants.XML_ILLEGAL_CHARACTERS, string.Empty);
        }

        #endregion Common

        #region Serialization

        public static string SoapXmlSerialize(object value)
        {
            var stringBuilder = new StringBuilder();
            var xmlWriterSettings = new XmlWriterSettings
            {
                OmitXmlDeclaration = true,
                Indent = true,
                CheckCharacters = false
            };
            using (var xmlWriter = XmlWriter.Create(stringBuilder, xmlWriterSettings))
            {
                var type = value.GetType();
                xmlWriter.WriteStartElement(type.FullName);
                var xmlSerializerNamespaces = new XmlSerializerNamespaces();
                xmlSerializerNamespaces.Add(string.Empty, string.Empty);
                var xmlSerializer = new XmlSerializer(new SoapReflectionImporter().ImportTypeMapping(type));
                xmlSerializer.Serialize(xmlWriter, value, xmlSerializerNamespaces);
            }
            return stringBuilder.ToString();
        }

        public static object SoapXmlDeserialize(string value, Type type)
        {
            var xmlTypeMapping = new SoapReflectionImporter().ImportTypeMapping(type);
            var xmlSerializer = new XmlSerializer(xmlTypeMapping);
            var xmlDocument = new XmlDocument();
            xmlDocument.LoadXml(value);
            var xmlTextReader = new XmlTextReader(new StringReader(xmlDocument.OuterXml));
            xmlTextReader.ReadStartElement(type.FullName);
            return xmlSerializer.Deserialize(xmlTextReader);
        }

        public static T SoapXmlDeserialize<T>(string value)
        {
            return (T) SoapXmlDeserialize(value, typeof(T));
        }

        public static string PortableXmlSerialize(object value)
        {
            byte[] bytes;
            var memoryStream = new MemoryStream();
            using (var customXmlTextWriter = new CustomXmlTextWriter(memoryStream, null) {Formatting = Formatting.Indented})
            {
                var dataContractSerializer = new DataContractSerializer(value.GetType());
                dataContractSerializer.WriteObject(customXmlTextWriter, value);
                customXmlTextWriter.Flush();
                memoryStream.Seek(0, SeekOrigin.Begin);
                bytes = new byte[memoryStream.Length];
                memoryStream.Read(bytes, 0, (int) memoryStream.Length);
            }
            memoryStream.Dispose();
            return Encoding.UTF8.GetString(bytes);
        }

        public static string XmlSerialize(object value)
        {
            var stringBuilder = new StringBuilder();
            var xmlWriterSettings = new XmlWriterSettings
            {
                OmitXmlDeclaration = true,
                Indent = true,
                CheckCharacters = false
            };
            using (var xmlWriter = XmlWriter.Create(stringBuilder, xmlWriterSettings))
            {
                var xmlSerializerNamespaces = new XmlSerializerNamespaces();
                xmlSerializerNamespaces.Add(string.Empty, string.Empty);
                var xmlSerializer = new XmlSerializer(value.GetType());
                xmlSerializer.Serialize(xmlWriter, value, xmlSerializerNamespaces);
            }
            return stringBuilder.ToString();
        }

        public static object XmlDeserialize(string value, Type type)
        {
            var xmlSerializer = new XmlSerializer(type);
            var xmlDocument = new XmlDocument();
            xmlDocument.LoadXml(value);
            return xmlSerializer.Deserialize(new XmlTextReader(new StringReader(xmlDocument.OuterXml)));
        }

        public static T XmlDeserialize<T>(string value)
        {
            return (T) XmlDeserialize(value, typeof(T));
        }

        public static string JsonSerialize(object value)
        {
            var dataContractJsonSerializer = new DataContractJsonSerializer(value.GetType());
            var memoryStream = new MemoryStream();
            dataContractJsonSerializer.WriteObject(memoryStream, value);
            memoryStream.Seek(0, SeekOrigin.Begin);
            var bytes = new byte[memoryStream.Length];
            memoryStream.Read(bytes, 0, (int) memoryStream.Length);
            return Encoding.UTF8.GetString(bytes);
        }

        public static object JsonDeserialize(string value, Type type)
        {
            object entity;
            using (var memoryStream = new MemoryStream())
            {
                var bytes = Encoding.UTF8.GetBytes(value);
                memoryStream.Write(bytes, 0, bytes.Length);
                memoryStream.Seek(0, SeekOrigin.Begin);
                using (var xmlDictionaryReader = JsonReaderWriterFactory.CreateJsonReader(memoryStream, Encoding.UTF8, XmlDictionaryReaderQuotas.Max, null))
                {
                    var dataContractJsonSerializer = new DataContractJsonSerializer(type);
                    entity = dataContractJsonSerializer.ReadObject(xmlDictionaryReader);
                }
            }
            return entity;
        }

        public static string JsonScriptSerialize(List<KeyValuePair<string, object>> parameters)
        {
            var jsonScriptSerialize = string.Empty;
            if (parameters != null &&
                parameters.Count > 0)
            {
                var values = new List<string>();
                foreach (var parameter in parameters)
                {
                    if (string.IsNullOrEmpty(parameter.Key)) continue;
                    values.Add(string.Format(@"""{0}"":{1}", parameter.Key, parameter.Value == null ? "null" : JsonSerialize(parameter.Value)));
                }
                jsonScriptSerialize = string.Format(@"{{{0}}}", string.Join(Constants.COMMA.ToString(), values));
            }
            return jsonScriptSerialize;
        }

        public static string JsonScriptSerialize(string key, object value)
        {
            return JsonScriptSerialize(new List<KeyValuePair<string, object>>
            {
                new KeyValuePair<string, object>(key, value)
            });
        }

        public static T JsonDeserialize<T>(string value)
        {
            return (T) JsonDeserialize(value, typeof(T));
        }

        public static string JsonScriptSerialize(object value)
        {
            var javaScriptSerializer = new JavaScriptSerializer();
            return javaScriptSerializer.Serialize(value);
        }

        public static T JsonScriptDeserialize<T>(string value)
        {
            var javaScriptSerializer = new JavaScriptSerializer();
            return javaScriptSerializer.Deserialize<T>(value);
        }

        #endregion Serialization

        #endregion Methods

        #endregion Public
    }
}