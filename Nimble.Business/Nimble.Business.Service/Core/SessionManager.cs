#region Using

using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.ServiceModel;
using System.ServiceModel.Channels;
using System.Threading;
using System.Transactions;
using Microsoft.AspNetCore.Http;
using Nimble.Business.Engine.Common;
using Nimble.Business.Engine.Core;
using Nimble.Business.Engine.Web;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model.Framework.Multilanguage;
using Nimble.Business.Library.Model.Framework.Security;
using Nimble.Business.Library.Server;
using HttpContext = System.Web.HttpContext;

#endregion Using

namespace Nimble.Business.Service.Core
{
    public class SessionManager
    {
        #region Private Members

        #region Properties

        private readonly object semaphore = new object();
        private readonly Dictionary<string, Token> openTokens = new Dictionary<string, Token>();
        private readonly Dictionary<string, Token> lockTokens = new Dictionary<string, Token>();
        private readonly Dictionary<string, Session> openSessions = new Dictionary<string, Session>();

        #endregion Properties

        #region Methods

        private bool LockDelete(string code)
        {
            var deleted = false;
            if (lockTokens.ContainsKey(code))
            {
                var token = lockTokens[code];
                token.Locks = null;
                deleted = lockTokens.Remove(code);
            }
            return deleted;
        }

        private bool TokenDelete(ICollection<string> codes)
        {
            var deleted = false;
            if (codes.Count > 0)
            {
                foreach (var code in codes)
                {
                    LockDelete(code);
                    deleted = openTokens.Remove(code);
                }
            }
            return deleted;
        }

        private bool ContextExists()
        {
            return ContextExists(SessionContext.SessionContextType);
        }

        private bool ContextExists(SessionContextType sessionContextType)
        {
            bool exists;
            switch (sessionContextType)
            {
                case SessionContextType.Wcf:
                {
                    exists = OperationContext.Current != null;
                    break;
                }
                case SessionContextType.Web:
                {
                    exists = HttpContext.Current != null && HttpContext.Current.Session != null;
                    break;
                }
                case SessionContextType.Core:
                {
                    exists = HttpContextAccessor != null && HttpContextAccessor.HttpContext != null && HttpContextAccessor.HttpContext.Session != null;
                    break;
                }
                default:
                {
                    exists = SessionContext.Session != null;
                    break;
                }
            }
            return exists;
        }

        private string ThreadId()
        {
            return Thread.CurrentThread.ManagedThreadId.ToString(CultureInfo.InvariantCulture);
        }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Properties

        public CustomMessageHeader CustomMessageHeader { get; set; }

        public SessionContext SessionContext { get; set; }

        public IHttpContextAccessor HttpContextAccessor { get; set; }

        #endregion Properties

        #region Methods

        public SessionManager(CustomMessageHeader customMessageHeader, SessionContext sessionContext, IHttpContextAccessor httpContextAccessor)
        {
            CustomMessageHeader = customMessageHeader;
            SessionContext = sessionContext;
            HttpContextAccessor = httpContextAccessor;
            Load();
        }

        public void Load()
        {
            if (string.IsNullOrEmpty(SessionContext.OpenTokens)) return;
            lock (semaphore)
            {
                try
                {
                    using (var streamReader = new StreamReader(SessionContext.OpenTokens))
                    {
                        var tokens = EngineStatic.JsonDeserialize<List<Token>>(streamReader.ReadToEnd());
                        foreach (var token in tokens)
                        {
                            openTokens.Add(token.Code, token);
                        }
                        streamReader.Close();
                    }
                    Kernel.Instance.Logging.Information("[{0}] open tokens successfully loaded from [{1}].", openTokens.Count, SessionContext.OpenTokens);
                }
                catch (Exception exception)
                {
                    Kernel.Instance.Logging.Warning("Cannot load open tokens from [{0}] - see exception message [{1}].", SessionContext.OpenTokens, exception.Message);
                }
            }
        }

        public void Save()
        {
            if (string.IsNullOrEmpty(SessionContext.OpenTokens)) return;
            try
            {
                using (var streamWriter = new StreamWriter(SessionContext.OpenTokens, false))
                {
                    var tokens = new List<Token>(openTokens.Values);
                    streamWriter.Write(EngineStatic.JsonSerialize(tokens));
                    streamWriter.Close();
                }
                Kernel.Instance.Logging.Information("[{0}] open tokens successfully saved to [{1}].", openTokens.Count, SessionContext.OpenTokens);
            }
            catch (Exception exception)
            {
                Kernel.Instance.Logging.Warning("Cannot save open tokens from [{0}] - see exception message [{1}].", SessionContext.OpenTokens, exception.Message);
            }
        }

        public int MessageHeaderIndex(string name)
        {
            var index = -1;
            if (ContextExists())
            {
                index = OperationContext.Current.IncomingMessageHeaders.FindHeader(name, CustomMessageHeader.Namespace);
            }
            return index;
        }

        public string MessageHeaderValue(string name)
        {
            return OperationContext.Current.IncomingMessageHeaders.GetHeader<string>(name, CustomMessageHeader.Namespace);
        }

        public string HttpRequestHeaderValue(string name)
        {
            string headerValue = null;
            if (ContextExists())
            {
                var httpRequestMessageProperty = (HttpRequestMessageProperty) OperationContext.Current.IncomingMessageProperties.Values.FirstOrDefault(item => item is HttpRequestMessageProperty);
                if (httpRequestMessageProperty != null)
                {
                    headerValue = httpRequestMessageProperty.Headers[name];
                }
            }
            return headerValue;
        }

        public string EmplacementCode()
        {
            string emplacementCode = null;
            switch (SessionContext.SessionContextType)
            {
                case SessionContextType.Wcf:
                {
                    if (ContextExists())
                    {
                        if (MessageHeaderIndex(CustomMessageHeader.EmplacementCode.Key) >= 0)
                        {
                            emplacementCode = MessageHeaderValue(CustomMessageHeader.EmplacementCode.Key);
                        }
                        else
                        {
                            emplacementCode = HttpRequestHeaderValue(CustomMessageHeader.EmplacementCode.Key);
                        }
                        if (string.IsNullOrEmpty(emplacementCode))
                        {
                            var session = OperationContext.Current.Extensions.Find<Session>();
                            if (session != null &&
                                session.Token != null &&
                                session.Token.Emplacement != null)
                            {
                                emplacementCode = session.Token.Emplacement.Code;
                            }
                        }
                    }
                    break;
                }
                case SessionContextType.Web:
                {
                    if (!string.IsNullOrEmpty(CustomMessageHeader.EmplacementCode.Value))
                    {
                        emplacementCode = CustomMessageHeader.EmplacementCode.Value;
                    }
                    break;
                }
                case SessionContextType.Win:
                {
                    if (!string.IsNullOrEmpty(CustomMessageHeader.EmplacementCode.Value))
                    {
                        emplacementCode = CustomMessageHeader.EmplacementCode.Value;
                    }
                    break;
                }
                case SessionContextType.Silverlight:
                {
                    if (!string.IsNullOrEmpty(CustomMessageHeader.EmplacementCode.Value))
                    {
                        emplacementCode = CustomMessageHeader.EmplacementCode.Value;
                    }
                    break;
                }
                case SessionContextType.Core:
                {
                    if (!string.IsNullOrEmpty(CustomMessageHeader.EmplacementCode.Value))
                    {
                        emplacementCode = CustomMessageHeader.EmplacementCode.Value;
                    }
                    break;
                }
            }
            if (!ContextExists())
            {
                emplacementCode = CustomMessageHeader.EmplacementCode.Value;
            }
            if (string.IsNullOrEmpty(emplacementCode))
            {
                throw FaultExceptionDetail.Create(new FaultExceptionDetail(Constants.SECURITY_VIOLATION_ENTITY_MISSED, "emplacement code"));
            }
            return emplacementCode;
        }

        public string ApplicationCode()
        {
            string applicationCode = null;
            switch (SessionContext.SessionContextType)
            {
                case SessionContextType.Wcf:
                {
                    if (ContextExists())
                    {
                        if (MessageHeaderIndex(CustomMessageHeader.ApplicationCode.Key) >= 0)
                        {
                            applicationCode = MessageHeaderValue(CustomMessageHeader.ApplicationCode.Key);
                        }
                        else
                        {
                            applicationCode = HttpRequestHeaderValue(CustomMessageHeader.ApplicationCode.Key);
                        }
                        if (string.IsNullOrEmpty(applicationCode))
                        {
                            var session = OperationContext.Current.Extensions.Find<Session>();
                            if (session != null &&
                                session.Token != null &&
                                session.Token.Application != null)
                            {
                                applicationCode = session.Token.Application.Code;
                            }
                        }
                    }
                    break;
                }
                case SessionContextType.Web:
                {
                    if (!string.IsNullOrEmpty(CustomMessageHeader.ApplicationCode.Value))
                    {
                        applicationCode = CustomMessageHeader.ApplicationCode.Value;
                    }
                    break;
                }
                case SessionContextType.Win:
                {
                    if (!string.IsNullOrEmpty(CustomMessageHeader.ApplicationCode.Value))
                    {
                        applicationCode = CustomMessageHeader.ApplicationCode.Value;
                    }
                    break;
                }
                case SessionContextType.Silverlight:
                {
                    if (!string.IsNullOrEmpty(CustomMessageHeader.ApplicationCode.Value))
                    {
                        applicationCode = CustomMessageHeader.ApplicationCode.Value;
                    }
                    break;
                }
                case SessionContextType.Core:
                {
                    if (!string.IsNullOrEmpty(CustomMessageHeader.ApplicationCode.Value))
                    {
                        applicationCode = CustomMessageHeader.ApplicationCode.Value;
                    }
                    break;
                }
            }
            if (!ContextExists())
            {
                applicationCode = CustomMessageHeader.ApplicationCode.Value;
            }
            if (string.IsNullOrEmpty(applicationCode))
            {
                throw FaultExceptionDetail.Create(new FaultExceptionDetail(Constants.SECURITY_VIOLATION_ENTITY_MISSED, "application code"));
            }
            return applicationCode;
        }

        public string TokenCode()
        {
            string tokenCode = null;
            switch (SessionContext.SessionContextType)
            {
                case SessionContextType.Wcf:
                {
                    if (MessageHeaderIndex(CustomMessageHeader.TokenCode.Key) >= 0)
                    {
                        tokenCode = MessageHeaderValue(CustomMessageHeader.TokenCode.Key);
                    }
                    else
                    {
                        tokenCode = HttpRequestHeaderValue(CustomMessageHeader.TokenCode.Key);
                    }
                    break;
                }
                case SessionContextType.Web:
                {
                    if (SessionObjects<string>.Object[Constants.SECURITY_SESSION_PATTERN] != null)
                    {
                        tokenCode = SessionObjects<string>.Object[Constants.SECURITY_SESSION_PATTERN];
                    }
                    break;
                }
                case SessionContextType.Win:
                {
                    if (!string.IsNullOrEmpty(SessionContext.TokenCode))
                    {
                        tokenCode = SessionContext.TokenCode;
                    }
                    break;
                }
                case SessionContextType.Silverlight:
                {
                    if (!string.IsNullOrEmpty(SessionContext.TokenCode))
                    {
                        tokenCode = SessionContext.TokenCode;
                    }
                    break;
                }
                case SessionContextType.Core:
                {
                    if (ContextExists())
                    {
                        var value = HttpContextAccessor.HttpContext.Session.GetString(Constants.SECURITY_SESSION_PATTERN);
                        if (!string.IsNullOrEmpty(value))
                        {
                            tokenCode = EngineStatic.JsonDeserialize<string>(value);
                        }
                    }
                    break;
                }
            }
            if (SessionContext.UseProcessToken)
            {
                tokenCode = Process.GetCurrentProcess().Id.ToString(CultureInfo.InvariantCulture);
            }
            else if (!ContextExists())
            {
                tokenCode = ThreadId();
            }
            return tokenCode;
        }

        public string KeyValue(KeyValuePair<string, string> keyValuePair)
        {
            string value = null;
            switch (SessionContext.SessionContextType)
            {
                case SessionContextType.Wcf:
                {
                    if (MessageHeaderIndex(keyValuePair.Key) >= 0)
                    {
                        value = MessageHeaderValue(keyValuePair.Key);
                    }
                    else
                    {
                        value = HttpRequestHeaderValue(keyValuePair.Key);
                    }
                    break;
                }
                case SessionContextType.Web:
                {
                    if (!string.IsNullOrEmpty(keyValuePair.Value))
                    {
                        value = keyValuePair.Value;
                    }
                    break;
                }
                case SessionContextType.Win:
                {
                    if (!string.IsNullOrEmpty(keyValuePair.Value))
                    {
                        value = keyValuePair.Value;
                    }
                    break;
                }
                case SessionContextType.Silverlight:
                {
                    if (!string.IsNullOrEmpty(keyValuePair.Value))
                    {
                        value = keyValuePair.Value;
                    }
                    break;
                }
                case SessionContextType.Core:
                {
                    if (!string.IsNullOrEmpty(keyValuePair.Value))
                    {
                        value = keyValuePair.Value;
                    }
                    break;
                }
            }
            return value;
        }

        #region Session

        public Session SessionContextGet()
        {
            Session session = null;
            switch (SessionContext.SessionContextType)
            {
                case SessionContextType.Wcf:
                {
                    if (ContextExists())
                    {
                        session = OperationContext.Current.Extensions.Find<Session>();
                    }
                    break;
                }
                case SessionContextType.Web:
                {
                    session = SessionObjects<Session>.Current;
                    break;
                }
                case SessionContextType.Win:
                {
                    session = SessionContext.Session;
                    break;
                }
                case SessionContextType.Silverlight:
                {
                    session = SessionContext.Session;
                    break;
                }
                case SessionContextType.Core:
                {
                    var key = typeof(Session).Name;
                    if (HttpContextAccessor.HttpContext.Items.ContainsKey(key))
                    {
                        session = (Session)HttpContextAccessor.HttpContext.Items[key];
                    }
                    break;
                }
            }
            if (!ContextExists())
            {
                var tokenCode = ThreadId();
                if (openSessions.ContainsKey(tokenCode))
                {
                    session = openSessions[tokenCode];
                    if (session.Token != null)
                    {
                        session.Token.LastUsedOn = DateTimeOffset.Now;
                    }
                }

            }
            return session;
        }

        public void SessionContextSet(Session session)
        {
            if (session != null &&
                session.Token != null)
            {
                session.Token.ClientHost = KeyValue(CustomMessageHeader.ClientHost);
                session.Token.ClientGeospatial = KeyValue(CustomMessageHeader.ClientGeospatial);
                session.Token.ClientUUID = KeyValue(CustomMessageHeader.ClientUUID);
                session.Token.ClientDevice = KeyValue(CustomMessageHeader.ClientDevice);
                session.Token.ClientPlatform = KeyValue(CustomMessageHeader.ClientPlatform);
                session.Token.ClientApplication = KeyValue(CustomMessageHeader.ClientApplication);
                session.Token.ExternalReference = KeyValue(CustomMessageHeader.ExternalReference);
            }
            switch (SessionContext.SessionContextType)
            {
                case SessionContextType.Wcf:
                {
                    if (ContextExists())
                    {
                        OperationContext.Current.Extensions.Clear();
                        OperationContext.Current.Extensions.Add(session);
                    }
                    break;
                }
                case SessionContextType.Web:
                {
                    SessionObjects<Session>.Object[false] = session;
                    break;
                }
                case SessionContextType.Win:
                {
                    SessionContext.Session = session;
                    break;
                }
                case SessionContextType.Silverlight:
                {
                    SessionContext.Session = session;
                    break;
                }
                case SessionContextType.Core:
                {
                    if (ContextExists())
                    {
                        var key = typeof(Session).Name;
                        if (HttpContextAccessor.HttpContext.Items.ContainsKey(key))
                        {
                            HttpContextAccessor.HttpContext.Items[key] = session;
                        }
                        else
                        {
                            HttpContextAccessor.HttpContext.Items.Add(key, session);
                        }
                    }
                    break;
                }
            }
            if (!ContextExists())
            {
                lock (semaphore)
                {
                    var tokenCode = ThreadId();
                    if (openSessions.ContainsKey(tokenCode))
                    {
                        openSessions[tokenCode] = session;
                    }
                    else
                    {
                        openSessions.Add(tokenCode, session);
                    }
                }
            }
        }

        public void SessionContextSet(string emplacementCode, string applicationCode)
        {
            var session = new Session
            {
                Token =
                {
                    Emplacement = new Emplacement
                    {
                        Code = emplacementCode
                    },
                    Application = new Application
                    {
                        Code = applicationCode
                    }
                }
            };
            SessionContextSet(session);
        }

        public Session SessionCreate(bool isAuthorized)
        {
            Session session = null;
            switch (SessionContext.SessionContextType)
            {
                case SessionContextType.Wcf:
                {
                    if (ContextExists())
                    {
                        session = new Session();
                        if (isAuthorized)
                        {
                            session.Token.Id = Guid.NewGuid();
                        }
                        session.Token.Code = string.Format(Constants.SECURITY_SESSION_PATTERN, EmplacementCode(), ApplicationCode(), session.Token.Id);
                        var remoteEndpointMessageProperty = (RemoteEndpointMessageProperty) OperationContext.Current.IncomingMessageProperties[RemoteEndpointMessageProperty.Name];
                        session.Token.RequestHost = remoteEndpointMessageProperty.Address;
                        session.Token.RequestPort = remoteEndpointMessageProperty.Port;
                        var index = MessageHeaderIndex(CustomMessageHeader.TokenCode.Key);
                        if (index >= 0)
                        {
                            OperationContext.Current.IncomingMessageHeaders.RemoveAt(index);
                        }
                        if (OperationContext.Current.IncomingMessageHeaders.MessageVersion.Envelope != EnvelopeVersion.None)
                        {
                            OperationContext.Current.IncomingMessageHeaders.Add((new MessageHeader<string>(session.Token.Code)).GetUntypedHeader(CustomMessageHeader.TokenCode.Key, CustomMessageHeader.Namespace));
                        }
                    }
                    break;
                }
                case SessionContextType.Web:
                {
                    if (ContextExists())
                    {
                        session = new Session();
                        if (isAuthorized)
                        {
                            session.Token.Id = Guid.NewGuid();
                        }
                        session.Token.Code = string.Format(Constants.SECURITY_SESSION_PATTERN, EmplacementCode(), ApplicationCode(), session.Token.Id);
                        session.Token.RequestHost = HttpContext.Current.Request.ServerVariables[Constants.FORWARDED_IP_ADDRESS];
                        if (string.IsNullOrEmpty(session.Token.RequestHost))
                        {
                            session.Token.RequestHost = HttpContext.Current.Request.ServerVariables[Constants.REMOTE_IP_ADDRESS];
                        }
                        session.Token.RequestPort = int.Parse(HttpContext.Current.Request.ServerVariables[Constants.REMOTE_PORT]);
                        SessionObjects<string>.Object[Constants.SECURITY_SESSION_PATTERN] = session.Token.Code;
                    }
                    break;
                }
                case SessionContextType.Win:
                {
                    session = new Session();
                    if (isAuthorized)
                    {
                        session.Token.Id = Guid.NewGuid();
                    }
                    session.Token.Code = string.Format(Constants.SECURITY_SESSION_PATTERN, EmplacementCode(), ApplicationCode(), session.Token.Id);
                    SessionContext.TokenCode = session.Token.Code;
                    break;
                }
                case SessionContextType.Silverlight:
                {
                    session = new Session();
                    if (isAuthorized)
                    {
                        session.Token.Id = Guid.NewGuid();
                    }
                    session.Token.Code = string.Format(Constants.SECURITY_SESSION_PATTERN, EmplacementCode(), ApplicationCode(), session.Token.Id);
                    SessionContext.TokenCode = session.Token.Code;
                    break;
                }
                case SessionContextType.Core:
                {
                    if (ContextExists())
                    {
                        session = new Session();
                        if (isAuthorized)
                        {
                            session.Token.Id = Guid.NewGuid();
                        }
                        session.Token.Code = string.Format(Constants.SECURITY_SESSION_PATTERN, EmplacementCode(), ApplicationCode(), session.Token.Id);
                        HttpContextAccessor.HttpContext.Session.SetString(Constants.SECURITY_SESSION_PATTERN, EngineStatic.JsonSerialize(session.Token.Code));
                    }
                    break;
                }
            }
            if (!ContextExists())
            {
                session = new Session();
                if (isAuthorized)
                {
                    session.Token.Id = Guid.NewGuid();
                }
                session.Token.Code = ThreadId();
            }
            if (session != null)
            {
                session.Token.Culture = new Culture
                {
                    Code = KeyValue(CustomMessageHeader.CultureCode)
                };
                SessionContextSet(session);
            }
            return session;
        }

        public Session SessionRead()
        {
            var session = SessionContextGet();
            if (session == null)
            {
                var tokenCode = TokenCode();
                if (!string.IsNullOrEmpty(tokenCode) &&
                    openTokens.ContainsKey(tokenCode))
                {
                    session = new Session
                    {
                        Token = openTokens[tokenCode]
                    };
                    var dateTimeOffsetNow = DateTimeOffset.Now;
                    if (!session.Token.IsMaster() &&
                        session.Token.LastUsedOn.Add(SessionContext.InactivityTimeout) < dateTimeOffsetNow)
                    {
                        openTokens.Remove(tokenCode);
                        if (openSessions.ContainsKey(tokenCode))
                        {
                            openSessions.Remove(tokenCode);
                        }
                        throw FaultExceptionDetail.Create(new FaultExceptionDetail(FaultExceptionDetailType.Expired));
                    }
                    session.Token.LastUsedOn = dateTimeOffsetNow;
                    SessionContextSet(session);
                }
            }
            return session;
        }

        public Session SessionUpdate(Session session)
        {
            lock (semaphore)
            {
                session.Token.LastUsedOn = DateTimeOffset.Now;
                if (openTokens.ContainsKey(session.Token.Code))
                {
                    openTokens[session.Token.Code] = session.Token;
                }
                else
                {
                    openTokens.Add(session.Token.Code, session.Token);
                }
                return session;
            }
        }

        public bool SessionDelete()
        {
            lock (semaphore)
            {
                var deleted = false;
                var tokenCode = TokenCode();
                if (!string.IsNullOrEmpty(tokenCode) &&
                    openTokens.ContainsKey(tokenCode))
                {
                    deleted = TokenDelete(new List<string>
                    {
                        tokenCode
                    });
                }
                return deleted;
            }
        }

        public void SessionClear(Session session)
        {
            lock (semaphore)
            {
                var dateTimeOffsetNow = DateTimeOffset.Now;
                var codes = new List<string>();
                var sessions = 0;
                foreach (var token in openTokens.Values)
                {
                    if (token.LastUsedOn.Add(SessionContext.InactivityTimeout) < dateTimeOffsetNow)
                    {
                        codes.Add(token.Code);
                        continue;
                    }
                    if (string.CompareOrdinal(session.Token.Code, token.Code) == 0 ||
                        session.Token.Account == null ||
                        !session.Token.Account.Sessions.HasValue ||
                        !session.Token.Account.Equals(token.Account)) continue;
                    sessions++;
                    if (sessions <= session.Token.Account.Sessions) continue;
                    codes.Add(token.Code);
                }
                TokenDelete(codes);
            }
        }

        #endregion Session

        #region Token

        public bool TokenDelete(List<Token> items)
        {
            lock (semaphore)
            {
                var tokenCode = TokenCode();
                var codes = new List<string>();
                foreach (var item in items)
                {
                    if (string.CompareOrdinal(item.Code, tokenCode) == 0 ||
                        !openTokens.ContainsKey(item.Code)) continue;
                    codes.Add(item.Code);
                }
                return TokenDelete(codes);
            }
        }

        public List<Token> TokenSearch()
        {
            return openTokens.Values.Select(item => item).Where(item => item.Id.HasValue).ToList();
        }

        public bool TokenIsExpired()
        {
            SessionClear(new Session());
            var tokenCode = TokenCode();
            return string.IsNullOrEmpty(tokenCode) || !openTokens.ContainsKey(tokenCode);
        }

        #endregion Token

        #region Lock

        public bool LockCreate(Session session, string[] connectionStrings, List<LockType> lockTypes)
        {
            var saved = true;
            var tokenLocks = new List<string>();
            if (lockTypes != null)
            {
                foreach (var lockType in lockTypes)
                {
                    if (lockType == LockType.Undefined) continue;
                    tokenLocks.Add(lockType.ToString());
                }
                if (tokenLocks.Count == 0)
                {
                    tokenLocks.Add(session.Token.PermissionType.ToString());
                }
            }
            if (tokenLocks.Count > 0)
            {
                var dateTimeOffset = DateTimeOffset.Now.Add(SessionContext.LockTimeout);
                while (saved)
                {
                    lock (semaphore)
                    {
                        if (session.Token.Locks == null)
                        {
                            foreach (var item in lockTokens)
                            {
                                if (item.Value.Locks == null ||
                                    item.Value.Locks.Count == 0) continue;
                                foreach (var tokenLock in tokenLocks)
                                {
                                    if (!item.Value.Locks.Contains(tokenLock)) continue;
                                    saved = false;
                                    break;
                                }
                                if (!saved)
                                {
                                    break;
                                }
                            }
                        }
                        else
                        {
                            saved = false;
                        }
                        if (saved)
                        {
                            session.Token.Locks = tokenLocks;
                            lockTokens.Add(session.Token.Code, session.Token);
                            session.TransactionScope = new TransactionScope(TransactionScopeOption.RequiresNew, new TransactionOptions
                            {
                                Timeout = SessionContext.ScopeTimeout,
                                IsolationLevel = IsolationLevel.Snapshot
                            });
                            if (session.SqlConnections == null)
                            {
                                session.SqlConnections = new Dictionary<string, SqlConnection>();
                            }
                            foreach (var connectionString in connectionStrings)
                            {
                                if (!session.SqlConnections.ContainsKey(connectionString))
                                {
                                    session.SqlConnections.Add(connectionString, null);
                                }
                                session.SqlConnections[connectionString] = new SqlConnection(connectionString);
                                session.SqlConnections[connectionString].Open();
                            }
                            break;
                        }
                    }
                    Thread.Sleep(SessionContext.LockDelay);
                    saved = dateTimeOffset > DateTimeOffset.Now;
                }
            }
            return saved;
        }

        public bool LockDelete(Session session, bool isCompleted)
        {
            lock (semaphore)
            {
                if (session.TransactionScope != null)
                {
                    var sqlConnections = new List<SqlConnection>();
                    foreach (var sqlConnection in session.SqlConnections)
                    {
                        if (sqlConnection.Value == null) continue;
                        sqlConnections.Add(sqlConnection.Value);
                    }
                    for (var index = 0; index < sqlConnections.Count; index++)
                    {
                        sqlConnections[index].Close();
                        sqlConnections[index].Dispose();
                        sqlConnections[index] = null;
                    }
                    if (isCompleted)
                    {
                        session.TransactionScope.Complete();
                    }
                    session.TransactionScope.Dispose();
                    session.TransactionScope = null;
                }
                return LockDelete(session.Token.Code);
            }
        }

        public bool LockDelete(Token token)
        {
            lock (semaphore)
            {
                return LockDelete(token.Code);
            }
        }

        public List<Token> LockSearch()
        {
            return lockTokens.Values.Select(item => item).ToList();
        }

        #endregion Lock

        #endregion Methods

        #endregion Public Members
    }
}