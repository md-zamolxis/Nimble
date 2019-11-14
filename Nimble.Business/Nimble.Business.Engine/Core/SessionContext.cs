#region Using

using System;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Engine.Core
{
    public class SessionContext
    {
        #region Public Members

        #region Properties

        public string TokenCode { get; set; }

        public Session Session { get; set; }

        public SessionContextType SessionContextType { get; set; }

        public bool UseProcessToken { get; set; }

        public TimeSpan InactivityTimeout { get; set; }

        public TimeSpan SaveTimeout { get; set; }

        public TimeSpan ScopeTimeout { get; set; }

        public TimeSpan LockTimeout { get; set; }

        public int LockDelay { get; set; }

        public TimeSpan SqlCommandDelay { get; set; }

        public string OpenTokensPath { get; set; }

        #endregion Properties

        #endregion Public Members
    }
}