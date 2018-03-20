#region Using

using System;

#endregion Using

namespace Nimble.Business.Library.Attributes
{
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Property)]
    public sealed class ExternalMapping : Attribute
    {
        #region Public Members

        #region Properties

        public string Url { get; private set; }

        public string Parameters { get; private set; }

        public string Format { get; private set; }

        #endregion Properties

        #region Methods

        public ExternalMapping(string url, string parameters, string format)
        {
            Url = url;
            Parameters = parameters;
            Format = format;
        }

        #endregion Methods

        #endregion Public Members
    }
}