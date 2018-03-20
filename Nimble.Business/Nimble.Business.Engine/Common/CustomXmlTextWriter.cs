#region Usings

using System.IO;
using System.Text;
using System.Xml;

#endregion Usings

namespace Nimble.Business.Engine.Common
{
    public class CustomXmlTextWriter : XmlTextWriter
    {
        #region Public

        #region Methods

        public CustomXmlTextWriter(Stream stream, Encoding encoding) : base(stream, encoding) { }

        public CustomXmlTextWriter(string filename, Encoding encoding) : base(filename, encoding) { }

        public CustomXmlTextWriter(TextWriter w) : base(w) { }

        public override void WriteStartElement(string prefix, string localName, string ns)
        {
            base.WriteStartElement(string.Empty, localName, string.Empty);
        }

        public override string LookupPrefix(string ns)
        {
            return string.Empty;
        }

        #endregion Methods

        #endregion Public
    }
}