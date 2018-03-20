#region Using

using System;

#endregion Using

namespace Nimble.Business.Library.Common
{
    public static class Extensions
    {
        public static DateTimeOffset DateOffset(this DateTimeOffset dateTimeOffset)
        {
            return new DateTimeOffset(dateTimeOffset.Year, dateTimeOffset.Month, dateTimeOffset.Day, 0, 0, 0, 0, dateTimeOffset.Offset);
        }
    }
}
