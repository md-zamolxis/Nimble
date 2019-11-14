#region Using

using System;
using System.Collections.Generic;
using System.Runtime.Serialization;

#endregion Using

namespace Nimble.Business.Library.Common
{
    [DataContract]
    public class KeyValue
    {
        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false)]
        public string Key { get; set; }

        [DataMember(EmitDefaultValue = false)]
        public string Value { get; set; }

        #endregion Properties

        #region Methods

        public KeyValue()
        {
        }

        public KeyValue(string key, string value)
        {
            Key = key;
            Value = value;
        }

        public static KeyValue[] Create(List<string> keys)
        {
            KeyValue[] keyValues = null;
            if (keys != null)
            {
                var items = new List<KeyValue>();
                foreach (var key in keys)
                {
                    var exists = false;
                    foreach (var item in items)
                    {
                        if (string.Compare(item.Key, key, StringComparison.Ordinal) != 0) continue;
                        exists = true;
                        break;
                    }
                    if (!exists)
                    {
                        items.Add(new KeyValue
                            {
                                Key = key
                            });
                    }
                }
                keyValues = items.ToArray();
            }
            return keyValues;
        }

        public static KeyValue Find(KeyValue[] keyValues, string key)
        {
            KeyValue keyValue = null;
            if (keyValues != null)
            {
                foreach (var item in keyValues)
                {
                    if (string.Compare(item.Key, key, StringComparison.Ordinal) != 0) continue;
                    keyValue = item;
                    break;
                }
            }
            return keyValue;
        }

        public static KeyValue[] Add(KeyValue[] keyValues, KeyValue keyValue)
        {
            if (keyValue != null)
            {
                if (keyValues == null)
                {
                    keyValues = new KeyValue[] {};
                }
                Array.Resize(ref keyValues, keyValues.Length + 1);
                keyValues[keyValues.Length - 1] = keyValue;
            }
            return keyValues;
        }

        public static KeyValue Find(ref KeyValue[] keyValues, string key)
        {
            KeyValue keyValue = null;
            if (keyValues != null &&
                !string.IsNullOrEmpty(key))
            {
                keyValue = Find(keyValues, key);
                if (keyValue == null)
                {
                    keyValue = new KeyValue
                        {
                            Key = key
                        };
                    Add(keyValues, keyValue);
                }
            }
            return keyValue;
        }

        public static KeyValue[] Add(KeyValue[] toValues, KeyValue[] fromValues)
        {
            if (fromValues != null)
            {
                if (toValues == null)
                {
                    toValues = fromValues;
                }
                else
                {
                    foreach (var fromValue in fromValues)
                    {
                        if (Find(toValues, fromValue.Key) != null) continue;
                        toValues = Add(toValues, fromValue);
                    }
                }
            }
            return toValues;
        }

        public static bool Equals(KeyValue[] keyValues, KeyValue keyValue)
        {
            var equals = false;
            if (keyValue != null)
            {
                var find = Find(keyValues, keyValue.Key);
                equals = find != null && string.Compare(find.Value, keyValue.Value, StringComparison.Ordinal) == 0;
            }
            return equals;
        }

        public static KeyValue[] Replace(KeyValue[] keyValues, KeyValue keyValue)
        {
            if (keyValue != null)
            {
                if (keyValues == null)
                {
                    keyValues = new KeyValue[] { };
                }
                var find = Find(keyValues, keyValue.Key);
                if (find == null)
                {
                    Add(keyValues, keyValue);
                }
                else
                {
                    find.Value = keyValue.Value;
                }
            }
            return keyValues;
        }

        public static string Find(KeyValue[] keyValues, string key, string value)
        {
            var keyValue = Find(keyValues, key);
            return string.IsNullOrWhiteSpace(keyValue?.Value) ? value : keyValue.Value;
        }

        #endregion Methods

        #endregion Public Members
    }
}