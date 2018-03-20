#region Using

using System;
using System.Diagnostics;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Engine.Common
{
    public class Logging
    {
        #region Private Members

        #region Properties

        private EventLog eventLog;

        #endregion Properties

        #region Methods

        private string Format(string message)
        {
            if (message != null &&
                message.Length > Constants.EVENT_LOG_MESSAGE_LENGTH)
            {
                message = message.Substring(0, Constants.EVENT_LOG_MESSAGE_LENGTH);
            }
            return message;
        }

        #endregion Methods

        #endregion Private Members

        #region Public Members

        #region Events

        public event EventLogEventHandler EventLogWriting;

        #endregion Events

        #region Methods

        public Logging(string source, OverflowAction? overflowAction = null, int? retentionDays = null)
        {
            if (!string.IsNullOrEmpty(source))
            {
                eventLog = new EventLog
                {
                    Source = source
                };
                if (overflowAction.HasValue &&
                    retentionDays.HasValue)
                {
                    eventLog.ModifyOverflowPolicy(overflowAction.Value, retentionDays.Value);
                }
            }
        }

        public void OnEventLogWriting(EventLogEventArgs e)
        {
            if (EventLogWriting != null)
            {
                EventLogWriting(this, e);
            }
        }

        public void Error(string message, bool rethrow)
        {
            OnEventLogWriting(new EventLogEventArgs
            {
                Message = message,
                EventLogEntryType = EventLogEntryType.Error
            });
            if (eventLog == null ||
                string.IsNullOrEmpty(message)) return;
            eventLog.WriteEntry(Format(message), EventLogEntryType.Error);
            if (rethrow)
            {
                throw FaultExceptionDetail.Create(new FaultExceptionDetail(message));
            }
        }

        public void Error(Exception exception, bool rethrow)
        {
            if (exception == null) return;
            Error(string.Format(Constants.EXCEPTION_LOG_FORMAT, exception.Source, exception.Message, exception.StackTrace), false);
            if (rethrow)
            {
                throw FaultExceptionDetail.Create(new FaultExceptionDetail(exception.Message));
            }
        }

        public void Error(Exception exception, string message)
        {
            if (exception == null) return;
            Error(string.Format(Constants.EXCEPTION_LOG_FORMAT, exception.Source, exception.Message, exception.StackTrace), false);
            if (!string.IsNullOrEmpty(message))
            {
                throw FaultExceptionDetail.Create(new FaultExceptionDetail(message));
            }
        }

        public void Information(string message, params object[] parameters)
        {
            OnEventLogWriting(new EventLogEventArgs
            {
                Message = message,
                EventLogEntryType = EventLogEntryType.Information
            });
            if (eventLog != null &&
                !string.IsNullOrEmpty(message))
            {
                eventLog.WriteEntry(Format(string.Format(message, parameters)), EventLogEntryType.Information);
            }
        }

        public void Warning(string message, params object[] parameters)
        {
            OnEventLogWriting(new EventLogEventArgs
            {
                Message = message,
                EventLogEntryType = EventLogEntryType.Warning
            });
            if (eventLog != null &&
                !string.IsNullOrEmpty(message))
            {
                eventLog.WriteEntry(Format(string.Format(message, parameters)), EventLogEntryType.Warning);
            }
        }

        #endregion Methods

        #endregion Public Members
    }
}
