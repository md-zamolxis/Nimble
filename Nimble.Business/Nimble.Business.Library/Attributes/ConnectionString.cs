#region Using

using System;

#endregion Using

namespace Nimble.Business.Library.Attributes
{
    [AttributeUsage(AttributeTargets.Property)]
    public sealed class ConnectionString : Attribute
    {
        #region Public Members

        #region Properties

        public string Name { get; private set; }

        #endregion Properties

        #region Methods

        public ConnectionString(string name)
        {
            Name = name;
        }

        #endregion Methods

        #endregion Public Members
    }
}