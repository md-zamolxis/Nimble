#region Using

using System;

#endregion Using

namespace Nimble.Business.Library.Attributes
{
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Property)]
    public sealed class ExternalReference : Attribute
    {
        #region Public Members

        #region Properties

        public string Name { get; private set; }

        public bool DenyRequest { get; private set; }

        public bool IsEnumValue { get; private set; }

        #endregion Properties

        #region Methods

        public ExternalReference(string name)
        {
            Name = name;
        }

        public ExternalReference(string name, bool denyRequest)
        {
            Name = name;
            DenyRequest = denyRequest;
        }

        public ExternalReference(string name, bool denyRequest, bool isEnumValue)
        {
            Name = name;
            DenyRequest = denyRequest;
            IsEnumValue = isEnumValue;
        }

        #endregion Methods

        #endregion Public Members
    }
}