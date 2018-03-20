#region Using

using System;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Library.Attributes
{
    [AttributeUsage(AttributeTargets.Field)]
    public sealed class IisState : Attribute
    {
        #region Public Members

        #region Properties

        public string Key { get; private set; }

        public bool CreateNew { get; private set; }

        public IisStateType IisStateType { get; private set; }

        #endregion Properties

        #region Methods

        public IisState(string key)
        {
            Key = key;
        }

        public IisState(string key, bool createNew) : this(key)
        {
            CreateNew = createNew;
        }

        public IisState(string key, bool createNew, IisStateType iisStateType) : this(key, createNew)
        {
            IisStateType = iisStateType;
        }

        public IisState()
        {

        }

        public IisState(bool createNew) : this()
        {
            CreateNew = createNew;
        }

        public IisState(bool createNew, IisStateType iisStateType) : this(createNew)
        {
            IisStateType = iisStateType;
        }

        #endregion Methods

        #endregion Public Members
    }
}