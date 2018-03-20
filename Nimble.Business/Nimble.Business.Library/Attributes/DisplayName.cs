#region Using

using System;

#endregion Using

namespace Nimble.Business.Library.Attributes
{
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Property)]
    public sealed class DisplayName : Attribute
    {
        #region Public Members

        #region Properties

        public string Name { get; private set; }

        #endregion Properties

        #region Methods

        public DisplayName(string name)
        {
            Name = name;
        }

        #endregion Methods

        #endregion Public Members
    }
}