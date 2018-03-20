#region Using

using System;
using System.Collections.Generic;
using Nimble.Business.Library.Model;

#endregion Using

namespace Nimble.Business.Library.Common
{
    public sealed class GenericCache
    {
        #region Private Members

        #region Properties

        private readonly object semaphore = new object();
        private readonly Dictionary<Type, Dictionary<string, object>> items = new Dictionary<Type, Dictionary<string, object>>();
        private readonly Dictionary<Type, Dictionary<string, string>> itemNaturalKeys = new Dictionary<Type, Dictionary<string, string>>();
        private readonly List<string> cachedEntities = new List<string>();

        #endregion Properties

        #region Methods

        private void RemoveItemKeys(Type type, string idCode)
        {
            var codes = new List<string>();
            foreach (var pair in itemNaturalKeys[type])
            {
                if (string.Compare(pair.Value, idCode, StringComparison.Ordinal) != 0) continue;
                codes.Add(pair.Key);
            }
            foreach (var code in codes)
            {
                itemNaturalKeys[type].Remove(code);
            }
        }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Methods

        public GenericCache()
        {
        }

        public GenericCache(string cachedEntityTypeNames)
        {
            if (string.IsNullOrEmpty(cachedEntityTypeNames)) return;
            var typeNames = cachedEntityTypeNames.Split(Constants.SEMICOLON);
            for (var index = 0; index < typeNames.Length; index++)
            {
                var typeName = typeNames[index].Trim();
                if (cachedEntities.Contains(typeName)) continue;
                cachedEntities.Add(typeName);
            }
        }

        public bool Contains(Type type)
        {
            lock (semaphore)
            {
                return items.ContainsKey(type) && itemNaturalKeys.ContainsKey(type);
            }
        }

        public void Add(object item)
        {
            lock (semaphore)
            {
                if (item == null) return;
                var type = item.GetType();
                if (!Contains(type))
                {
                    items.Add(type, new Dictionary<string, object>());
                    itemNaturalKeys.Add(type, new Dictionary<string, string>());
                }
                string idCode;
                var genericEntity = item as GenericEntity;
                if (genericEntity == null)
                {
                    idCode = item.GetHashCode().ToString();
                    if (items[type].ContainsKey(idCode))
                    {
                        items[type][idCode] = item;
                    }
                    else
                    {
                        items[type].Add(idCode, item);
                    }
                }
                else
                {
                    idCode = genericEntity.GetIdCode();
                    if (string.IsNullOrEmpty(idCode)) return;
                    if (items[type].ContainsKey(idCode))
                    {
                        items[type][idCode] = item;
                        RemoveItemKeys(type, idCode);
                    }
                    else
                    {
                        items[type].Add(idCode, item);
                    }
                    var naturalKeys = genericEntity.GetNaturalKeys();
                    foreach (var naturalKey in naturalKeys)
                    {
                        if (itemNaturalKeys[type].ContainsKey(naturalKey))
                        {
                            itemNaturalKeys[type][naturalKey] = idCode;
                        }
                        else
                        {
                            itemNaturalKeys[type].Add(naturalKey, idCode);
                        }
                    }
                }
            }
        }

        public void AddRange(IList<object> entities)
        {
            foreach (var entity in entities)
            {
                Add(entity);
            }
        }

        public bool Remove(object item)
        {
            lock (semaphore)
            {
                var removed = false;
                if (item != null)
                {
                    var entity = Get(item);
                    if (entity != null)
                    {
                        var type = entity.GetType();
                        var genericEntity = item as GenericEntity;
                        if (genericEntity == null)
                        {
                            removed = items[type].Remove(entity.GetHashCode().ToString());
                        }
                        else
                        {
                            var idCode = genericEntity.GetIdCode();
                            removed = items[type].Remove(idCode);
                            var naturalKeys = genericEntity.GetNaturalKeys();
                            foreach (var naturalKey in naturalKeys)
                            {
                                items[type].Remove(itemNaturalKeys[type][naturalKey]);
                                itemNaturalKeys[type].Remove(naturalKey);
                            }
                            RemoveItemKeys(type, idCode);
                        }
                    }
                }
                return removed;
            }
        }

        public bool Remove(Type type)
        {
            lock (semaphore)
            {
                return items.Remove(type) && itemNaturalKeys.Remove(type);
            }
        }

        public object Get(object item)
        {
            lock (semaphore)
            {
                object entity = null;
                if (item != null)
                {
                    var type = item.GetType();
                    if (Contains(type))
                    {
                        string idCode;
                        var genericEntity = item as GenericEntity;
                        if (genericEntity == null)
                        {
                            idCode = item.GetHashCode().ToString();
                            if (items[type].ContainsKey(idCode))
                            {
                                entity = items[type][idCode];
                            }
                        }
                        else
                        {
                            idCode = genericEntity.GetIdCode();
                            if (items[type].ContainsKey(idCode))
                            {
                                entity = items[type][idCode];
                            }
                            else
                            {
                                var naturalKeys = genericEntity.GetNaturalKeys();
                                foreach (var naturalKey in naturalKeys)
                                {
                                    if (!itemNaturalKeys[type].ContainsKey(naturalKey)) continue;
                                    entity = items[type][itemNaturalKeys[type][naturalKey]];
                                    break;
                                }
                            }
                        }
                    }
                }
                return entity;
            }
        }

        public T GetEntity<T>(T item)
        {
            return (T)Get(item);
        }

        public List<T> GetEntities<T>()
        {
            lock (semaphore)
            {
                var entities = new List<T>();
                var type = typeof (T);
                if (Contains(type))
                {
                    foreach (var item in items[type])
                    {
                        entities.Add((T) item.Value);
                    }
                }
                return entities;
            }
        }

        public bool EntityIsCached(Type type)
        {
            var entityIsCached = false;
            foreach (var cachedEntity in cachedEntities)
            {
                if (!string.Equals(cachedEntity, type.Name, StringComparison.Ordinal)) continue;
                entityIsCached = true;
                break;
            }
            return entityIsCached;
        }

        #endregion Methods

        #endregion Public Members
    }
}