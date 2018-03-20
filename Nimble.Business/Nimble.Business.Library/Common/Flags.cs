#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using System.Text.RegularExpressions;
using Nimble.Business.Library.Attributes;

#endregion Using

namespace Nimble.Business.Library.Common
{
    [DataContract]
    [DisplayName("Flags")]
    public class Flags<E>
    {
        #region Private Members

        #region Properties

        private int number;
        private string line;

        #endregion Properties

        #region Methods

        private void SetEnumerator(int enumerator)
        {
            Enumerator = (E)Enum.ToObject(typeof(E), enumerator);
        }

        private void SetEnumerator(string enumerator)
        {
            if (Regex.IsMatch(enumerator, Constants.BINARY_VALIDATION_PATTERN))
            {
                Enumerator = (E)Enum.ToObject(typeof(E), Convert.ToInt32(enumerator, Constants.BINARY_BASE));
            }
        }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public bool IsExact { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public E Enumerator { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public int Number
        {
            get
            {
                if (!Enumerator.Equals(default(E)))
                {
                    number = Convert.ToInt32(Enumerator);
                }
                return number;
            }
            set
            {
                number = value;
            }
        }

        [DataMember(EmitDefaultValue = false)]
        public string Line
        {
            get
            {
                if (!Enumerator.Equals(default(E)))
                {
                    line = Convert.ToString(Convert.ToInt32(Enumerator), Constants.BINARY_BASE);
                }
                if (!string.IsNullOrEmpty(line) &&
                    line.Length != Constants.BINARY_LENGTH)
                {
                    line = line.PadLeft(Constants.BINARY_LENGTH, Constants.BINARY_LEADING_CHAR);
                }
                return line;
            }
            set
            {
                line = value;
            }
        }

        #endregion Properties

        #region Methods

        public Flags()
        {
            if (Enumerator.Equals(default(E)))
            {
                if (Number > 0)
                {
                    SetEnumerator(Number);
                }
                else if (!string.IsNullOrEmpty(Line))
                {
                    SetEnumerator(Line);
                }
            }
        }

        public Flags(E enumerator)
        {
            Enumerator = enumerator;
        }

        public Flags(IEnumerable<E> enumerators)
        {
            SetValues(enumerators);
        }

        public Flags(int enumerator)
        {
            SetEnumerator(enumerator);
        }

        public Flags(string enumerator)
        {
            SetEnumerator(enumerator);
        }

        public bool HasValue(E enumerator)
        {
            var value = Convert.ToInt32(enumerator);
            return (Number & value) == value;
        }

        public bool HasValues(IEnumerable<E> enumerators)
        {
            var hasValue = false;
            foreach (var enumerator in enumerators)
            {
                hasValue = HasValue(enumerator);
                if (hasValue) break;
            }
            return hasValue;
        }

        public List<E> GetValues()
        {
            var values = new List<E>();
            var enumerators = ClientStatic.GetEnumValues<E>();
            if (enumerators != null)
            {
                foreach (var enumerator in enumerators)
                {
                    if (!HasValue(enumerator)) continue;
                    values.Add(enumerator);
                }
            }
            return values;
        }

        public void SetValues(IEnumerable<E> enumerators)
        {
            var value = 0;
            foreach (var enumerator in enumerators)
            {
                value = value | Convert.ToInt32(enumerator);
            }
            SetEnumerator(value);
        }

        public void AddValues(IEnumerable<E> enumerators)
        {
            var value = Number;
            foreach (var enumerator in enumerators)
            {
                if (HasValue(enumerator)) continue;
                value = value | Convert.ToInt32(enumerator);
            }
            SetEnumerator(value);
        }

        public void AddValue(E enumerator)
        {
            AddValues(new List<E>
            {
                enumerator
            });
        }

        public void RemoveValues(IEnumerable<E> enumerators)
        {
            var value = Number;
            foreach (var enumerator in enumerators)
            {
                if (!HasValue(enumerator)) continue;
                value = value ^ Convert.ToInt32(enumerator);
            }
            SetEnumerator(value);
        }

        public void RemoveValue(E enumerator)
        {
            RemoveValues(new List<E>
            {
                enumerator
            });
        }

        public static Flags<E> SetAllValues()
        {
            return new Flags<E>(ClientStatic.GetEnumValues<E>());
        }

        #endregion Methods

        #endregion Public Members
    }
}