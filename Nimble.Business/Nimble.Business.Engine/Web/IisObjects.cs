#region Using

using System;
using System.Collections.Generic;
using System.Web;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Engine.Web
{
    public class IisObjects
    {
        #region Public Members

        #region Methods

        public static string GetName(Type type, string objectName)
        {
            var name = type.FullName;
            if (!string.IsNullOrEmpty(objectName))
            {
                name += objectName;
            }
            return name;
        }

        public static string GetName(Type type, ObjectNameType objectNameType)
        {
            var name = type.FullName;
            if (objectNameType != ObjectNameType.None)
            {
                name += objectNameType.ToString();
            }
            return name;
        }

        #region Session

        public static object SessionGet(Type type, string name, bool createNew)
        {
            object item = null;
            if (HttpContext.Current != null &&
                HttpContext.Current.Session != null)
            {
                if (HttpContext.Current.Session[name] != null)
                {
                    item = HttpContext.Current.Session[name];
                }
                else if (createNew)
                {
                    item = ClientStatic.CreateInstance(type);
                    HttpContext.Current.Session[name] = item;
                }
            }
            return item;
        }

        public static object SessionGet(Type type, string name)
        {
            return SessionGet(type, name, false);
        }

        public static void SessionSet(string name, object item)
        {
            if (HttpContext.Current != null &&
                HttpContext.Current.Session != null)
            {
                HttpContext.Current.Session[name] = item;
            }
        }

        public static void SessionRemove(string name, int startIndex)
        {
            if (HttpContext.Current == null || HttpContext.Current.Session == null) return;
            if (startIndex < 0)
            {
                HttpContext.Current.Session.Remove(name);
            }
            else
            {
                var keys = new List<string>();
                foreach (var key in HttpContext.Current.Session.Keys)
                {
                    var item = key.ToString();
                    if (item.IndexOf(name, startIndex, StringComparison.OrdinalIgnoreCase) < 0) continue;
                    keys.Add(item);
                }
                foreach (var key in keys)
                {
                    HttpContext.Current.Session.Remove(key);
                }
            }
        }

        #endregion Session

        #region Cache

        public static object CacheGet(Type type, string name, bool createNew)
        {
            object item = null;
            if (HttpContext.Current != null &&
                HttpContext.Current.Cache != null)
            {
                if (HttpContext.Current.Cache[name] != null)
                {
                    item = HttpContext.Current.Cache[name];
                }
                else if (createNew)
                {
                    item = ClientStatic.CreateInstance(type);
                    HttpContext.Current.Cache[name] = item;
                }
            }
            return item;
        }

        public static object CacheGet(Type type, string name)
        {
            return CacheGet(type, name, false);
        }

        public static void CacheSet(string name, object item)
        {
            if (HttpContext.Current != null &&
                HttpContext.Current.Cache != null)
            {
                HttpContext.Current.Cache[name] = item;
            }
        }

        public static void CacheRemove(string name)
        {
            if (HttpContext.Current != null &&
                HttpContext.Current.Cache != null)
            {
                HttpContext.Current.Cache.Remove(name);
            }
        }

        #endregion Cache

        #endregion Methods

        #endregion Public Members
    }

    public static class SessionObjects<T>
    {
        #region Private Members

        #region Properties

        private static readonly SessionObject<T> item = new SessionObject<T>();

        #endregion Properties

        #endregion Private Members

        #region Public Members

        #region Properties

        public static T Current
        {
            get
            {
                return item[false];
            }
        }

        public static SessionObject<T> Object
        {
            get
            {
                return item;
            }
        }

        #endregion Properties

        #endregion Public Members
    }

    public static class CacheObjects<T>
    {
        #region Private Members

        #region Properties

        private static readonly CacheObject<T> item = new CacheObject<T>();

        #endregion Properties

        #endregion Private Members

        #region Public Members

        #region Properties

        public static T Current
        {
            get
            {
                return item[false];
            }
        }

        public static CacheObject<T> Object
        {
            get
            {
                return item;
            }
        }

        #endregion Properties

        #endregion Public Members
    }

    public class SessionObject<T>
    {
        #region Private Members

        #region Properties

        private readonly object semaphore = new object();

        #endregion Properties

        #region Methods

        private static T SessionGetItem(string name, bool createNew)
        {
            var generic = default(T);
            var item = IisObjects.SessionGet(typeof(T), name, createNew);
            if (item != null)
            {
                generic = (T)item;
            }
            return generic;
        }

        private static void SessionSetItem(string name, T item)
        {
            IisObjects.SessionSet(name, item);
        }

        private T SessionGet(string objectName, bool createNew)
        {
            lock (semaphore)
            {
                return SessionGetItem(IisObjects.GetName(typeof(T), objectName), createNew);
            }
        }

        private T SessionGet(ObjectNameType objectNameType, bool createNew)
        {
            lock (semaphore)
            {
                return SessionGetItem(IisObjects.GetName(typeof(T), objectNameType), createNew);
            }
        }

        private T SessionGet(bool createNew)
        {
            return SessionGet(null, createNew);
        }

        private void SessionSet(ObjectNameType objectNameType, T item)
        {
            lock (semaphore)
            {
                SessionSetItem(IisObjects.GetName(typeof(T), objectNameType), item);
            }
        }

        private void SessionSet(string objectName, T item)
        {
            lock (semaphore)
            {
                SessionSetItem(IisObjects.GetName(typeof(T), objectName), item);
            }
        }

        private void SessionSet(T item)
        {
            SessionSet(null, item);
        }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        public T this[string objectName, bool createNew]
        {
            get
            {
                return SessionGet(objectName, createNew);
            }
            set
            {
                SessionSet(objectName, value);
            }
        }

        public T this[ObjectNameType objectNameType, bool createNew]
        {
            get
            {
                return SessionGet(objectNameType, createNew);
            }
            set
            {
                SessionSet(objectNameType, value);
            }
        }

        public T this[string objectName]
        {
            get
            {
                return SessionGet(objectName, false);
            }
            set
            {
                SessionSet(objectName, value);
            }
        }

        public T this[ObjectNameType objectNameType]
        {
            get
            {
                return SessionGet(objectNameType, false);
            }
            set
            {
                SessionSet(objectNameType, value);
            }
        }

        public T this[bool createNew]
        {
            get
            {
                return SessionGet(createNew);
            }
            set
            {
                SessionSet(value);
            }
        }

        #endregion Properties

        #endregion Public Members
    }

    public class CacheObject<T>
    {
        #region Private Members

        #region Properties

        private readonly object semaphore = new object();

        #endregion Properties

        #region Methods

        private static T CacheGetItem(string name, bool createNew)
        {
            var generic = default(T);
            var item = IisObjects.CacheGet(typeof(T), name, createNew);
            if (item != null)
            {
                generic = (T)item;
            }
            return generic;
        }

        private static void CacheSetItem(string name, T item)
        {
            IisObjects.CacheSet(name, item);
        }

        private T CacheGet(string objectName, bool createNew)
        {
            lock (semaphore)
            {
                return CacheGetItem(IisObjects.GetName(typeof(T), objectName), createNew);
            }
        }

        private T CacheGet(ObjectNameType objectNameType, bool createNew)
        {
            lock (semaphore)
            {
                return CacheGetItem(IisObjects.GetName(typeof(T), objectNameType), createNew);
            }
        }

        private T CacheGet(bool createNew)
        {
            return CacheGet(null, createNew);
        }

        private void CacheSet(ObjectNameType objectNameType, T item)
        {
            lock (semaphore)
            {
                CacheSetItem(IisObjects.GetName(typeof(T), objectNameType), item);
            }
        }

        private void CacheSet(string objectName, T item)
        {
            lock (semaphore)
            {
                CacheSetItem(IisObjects.GetName(typeof(T), objectName), item);
            }
        }

        private void CacheSet(T item)
        {
            CacheSet(null, item);
        }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        public T this[string objectName, bool createNew]
        {
            get
            {
                return CacheGet(objectName, createNew);
            }
            set
            {
                CacheSet(objectName, value);
            }
        }

        public T this[ObjectNameType objectNameType, bool createNew]
        {
            get
            {
                return CacheGet(objectNameType, createNew);
            }
            set
            {
                CacheSet(objectNameType, value);
            }
        }

        public T this[string objectName]
        {
            get
            {
                return CacheGet(objectName, false);
            }
            set
            {
                CacheSet(objectName, value);
            }
        }

        public T this[ObjectNameType objectNameType]
        {
            get
            {
                return CacheGet(objectNameType, false);
            }
            set
            {
                CacheSet(objectNameType, value);
            }
        }

        public T this[bool createNew]
        {
            get
            {
                return CacheGet(createNew);
            }
            set
            {
                CacheSet(value);
            }
        }

        #endregion Properties

        #endregion Public Members
    }
}