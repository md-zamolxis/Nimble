#region Using

using System;
using System.Collections.Generic;

#endregion Using

namespace Nimble.Business.Library.Attributes
{
    [Flags]
    public enum ConstantType
    {
        None,
        NullReference,
        StringEmpty,
        StringEmptyTrim,
        StringEmptyTrimEnd,
        GuidEmpty,
        IntEmpty
    }

    [AttributeUsage(AttributeTargets.Property)]
    public sealed class UndefinedValues : Attribute
    {
        #region Private Members

        #region Properties

        private readonly Dictionary<ConstantType, object[]> values = new Dictionary<ConstantType, object[]>();

        #endregion Properties

        #endregion Private Members

        #region Public Members

        #region Properties

        public Dictionary<ConstantType, object[]> Values
        {
            get { return values; }
        }

        public ConstantType ConstantType { get; private set; }

        #endregion Properties

        #region Methods

        public UndefinedValues(params object[] values)
        {
            if (values != null)
            {
                this.values.Add(ConstantType.None, values);
            }
        }

        public UndefinedValues(ConstantType constantType, params object[] values) : this(values)
        {
            ConstantType = constantType;
            if ((ConstantType & ConstantType.NullReference) == ConstantType.NullReference)
            {
                Values.Add(ConstantType.NullReference, new object[] {null});
            }
            if ((ConstantType & ConstantType.StringEmpty) == ConstantType.StringEmpty)
            {
                Values.Add(ConstantType.StringEmpty, new object[] {string.Empty});
            }
            if ((ConstantType & ConstantType.StringEmptyTrim) == ConstantType.StringEmptyTrim)
            {
                Values.Add(ConstantType.StringEmptyTrim, new object[] {string.Empty});
            }
            if ((ConstantType & ConstantType.StringEmptyTrimEnd) == ConstantType.StringEmptyTrimEnd)
            {
                Values.Add(ConstantType.StringEmptyTrimEnd, new object[] {string.Empty});
            }
            if ((ConstantType & ConstantType.GuidEmpty) == ConstantType.GuidEmpty)
            {
                Values.Add(ConstantType.GuidEmpty, new object[] {Guid.Empty});
            }
            if ((ConstantType & ConstantType.IntEmpty) == ConstantType.IntEmpty)
            {
                Values.Add(ConstantType.IntEmpty, new object[] {0});
            }
        }

        #endregion Methods

        #endregion Public Members
    }
}