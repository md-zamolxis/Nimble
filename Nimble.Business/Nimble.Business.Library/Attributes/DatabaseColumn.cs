#region Using

using System;
using System.Collections.Generic;

#endregion Using

namespace Nimble.Business.Library.Attributes
{
    [AttributeUsage(AttributeTargets.Property)]
    public sealed class DatabaseColumn : Attribute
    {
        #region Private Members

        #region Properties

        private readonly List<Type> disableMappings = new List<Type>();

        #endregion Properties

        #endregion Private Members

        #region Public Members

        #region Properties

        public string Name { get; set; }

        public string Alias { get; set; }

        public bool IsIdentity { get; set; }

        public bool ForceValue { get; set; }

        public bool DisableMapping { get; set; }

        public bool DisableCaching { get; set; }

        public bool DisableIndexing { get; set; }

        public string Prefix { get; set; }

        public Type BlockPrefix { get; set; }

        public bool AllowGrouping { get; set; }

        public string Format { get; set; }

        public List<Type> DisableMappings
        {
            get { return disableMappings; }
        }

        #endregion Properties

        #region Methods

        public DatabaseColumn()
        {
        }

        public DatabaseColumn(params Type[] disableMappings)
        {
            if (disableMappings != null)
            {
                this.disableMappings.AddRange(disableMappings);
            }
        }

        #endregion Methods

        #endregion Public Members
    }
}