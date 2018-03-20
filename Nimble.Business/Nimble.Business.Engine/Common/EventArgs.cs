#region Using

using System;
using System.Diagnostics;
using System.Windows.Forms;
using Nimble.Business.Library.Common;
using Nimble.Business.Library.Model.Framework.Security;

#endregion Using

namespace Nimble.Business.Engine.Common
{
    public class RoleEventArgs : EventArgs
    {
        public Role Role { get; set; }
        public int RowIndex { get; set; }
    }

    public delegate void RoleEventHandler(object sender, RoleEventArgs e);

    public class DialogResultArgs : EventArgs
    {
        public string Text { get; set; }
        public string Caption { get; set; }
        public MessageBoxCaptionType MessageBoxCaptionType { get; set; }
        public MessageBoxButtons MessageBoxButtons { get; set; }
        public DialogResult DialogResult { get; set; }
        public object Tag { get; set; }
        public MessageBoxActionType MessageBoxActionType { get; set; }
        public object Entity { get; set; }
    }

    public delegate void DialogResultEventHandler(object sender, DialogResultArgs e);

    public class EventLogEventArgs : EventArgs
    {
        public string Message { get; set; }
        public EventLogEntryType EventLogEntryType { get; set; }
    }

    public delegate void EventLogEventHandler(object sender, EventLogEventArgs e);
}
