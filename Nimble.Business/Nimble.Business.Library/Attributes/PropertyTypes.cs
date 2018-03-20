#region Using

using System;
using System.Collections.Generic;

#endregion Using

namespace Nimble.Business.Library.Attributes
{
    [AttributeUsage(AttributeTargets.Property)]
    public sealed class PropertyTypes : Attribute
    {
        #region Private Members

        #region Properties

        private readonly List<Type> types = new List<Type>();

        #endregion Properties

        #endregion Private Members

        #region Public Members

        #region Properties

        public List<Type> Types
        {
            get { return types; }
        }

        #endregion Properties

        #region Methods

        public PropertyTypes(params Type[] types)
        {
            if (types != null)
            {
                this.types.AddRange(types);
            }
        }

        #endregion Methods

        #endregion Public Members
    }
}