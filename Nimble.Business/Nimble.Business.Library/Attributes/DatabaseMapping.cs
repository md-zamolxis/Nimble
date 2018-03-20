#region Using

using System;

#endregion Using

namespace Nimble.Business.Library.Attributes
{
    [AttributeUsage(AttributeTargets.Class)]
    public sealed class DatabaseMapping : Attribute
    {
        #region Public Members

        #region Properties

        public string StoredProcedure { get; set; }

        public string Table { get; set; }

        public bool DisableIndexing { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}