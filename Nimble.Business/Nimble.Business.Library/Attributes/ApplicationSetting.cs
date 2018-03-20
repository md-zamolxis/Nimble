#region Using

using System;

#endregion Using

namespace Nimble.Business.Library.Attributes
{
    [AttributeUsage(AttributeTargets.Property)]
    public sealed class ApplicationSetting : Attribute
    {
        #region Public Members

        #region Properties

        public string Key { get; private set; }

        #endregion Properties

        #region Methods

        public ApplicationSetting(string key)
        {
            Key = key;
        }

        #endregion Methods

        #endregion Public Members
    }
}