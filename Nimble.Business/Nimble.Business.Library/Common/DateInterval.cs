#region Using

using System;
using System.Runtime.Serialization;
using Nimble.Business.Library.Attributes;

#endregion Using

namespace Nimble.Business.Library.Common
{
    [DataContract]
    public enum DateIntervalType
    {
        [EnumMember]
        [FieldCategory(Name = "undefined")]
        Undefined,
        [EnumMember]
        [FieldCategory(Name = "today")]
        Today,
        [EnumMember]
        [FieldCategory(Name = "yesterday")]
        Yesterday,
        [EnumMember]
        [FieldCategory(Name = "current week")]
        CurrentWeek,
        [EnumMember]
        [FieldCategory(Name = "last week")]
        LastWeek,
        [EnumMember]
        [FieldCategory(Name = "current month")]
        CurrentMonth,
        [EnumMember]
        [FieldCategory(Name = "last month")]
        LastMonth,
        [EnumMember]
        [FieldCategory(Name = "current quarter")]
        CurrentQuarter,
        [EnumMember]
        [FieldCategory(Name = "last quarter")]
        LastQuarter,
        [EnumMember]
        [FieldCategory(Name = "current year")]
        CurrentYear,
        [EnumMember]
        [FieldCategory(Name = "last year")]
        LastYear
    }

    [DataContract]
    public class DateInterval
    {
        #region Private Members

        #region Properties

        private DateTimeOffset dateTimeOffsetNow = DateTimeOffset.Now;
        private DateTimeOffset? dateFrom;
        private DateTimeOffset? dateTo;

        #endregion Properties

        #endregion Private Members

        #region Public Members

        #region Properties

        [DataMember(EmitDefaultValue = false, Order = 0)]
        public DateTimeOffset DateTimeOffsetNow
        {
            get { return dateTimeOffsetNow; }
            set { dateTimeOffsetNow = value; }
        }

        [DataMember(EmitDefaultValue = false, Order = 1)]
        public bool IncludeTime { get; set; }

        [DataMember(EmitDefaultValue = false, Order = 2)]
        public DateIntervalType DateIntervalType { get; set; }

        [DataMember(EmitDefaultValue = false, Order = 3)]
        public DateTimeOffset? DateFrom
        {
            get
            {
                if (!dateFrom.HasValue ||
                    IncludeTime)
                {
                    return dateFrom;
                }
                return dateFrom.Value.DateOffset();
            }
            set
            {
                dateFrom = value;
            }
        }

        [DataMember(EmitDefaultValue = false, Order = 4)]
        public DateTimeOffset? DateTo
        {
            get
            {
                if (!dateTo.HasValue ||
                    IncludeTime)
                {
                    return dateTo;
                }
                return dateTo.Value.DateOffset().AddDays(1).AddMilliseconds(-3);
            }
            set
            {
                dateTo = value;
            }
        }

        #endregion Properties

        #region Methods

        public DateInterval(DateTimeOffset dateTimeOffsetNow, DateIntervalType dateIntervalType)
        {
            this.dateTimeOffsetNow = dateTimeOffsetNow;
            DateIntervalType = dateIntervalType;
            var quarterMonths = dateTimeOffsetNow.Month % 3;
            switch (DateIntervalType)
            {
                case DateIntervalType.Undefined:
                    {
                        dateFrom = dateTo = null;
                        break;
                    }
                case DateIntervalType.Today:
                    {
                        dateFrom = dateTo = dateTimeOffsetNow;
                        break;
                    }
                case DateIntervalType.Yesterday:
                    {
                        dateFrom = dateTo = dateTimeOffsetNow.AddDays(-1);
                        break;
                    }
                case DateIntervalType.CurrentWeek:
                    {
                        dateFrom = dateTo = dateTimeOffsetNow;
                        if (dateTimeOffsetNow.DayOfWeek == DayOfWeek.Sunday)
                        {
                            dateFrom = dateFrom.Value.AddDays(-6);
                        }
                        else
                        {
                            dateFrom = dateFrom.Value.AddDays(1 - (int)dateFrom.Value.DayOfWeek);
                            dateTo = dateTo.Value.AddDays(7 - (int)dateTo.Value.DayOfWeek);
                        }
                        break;
                    }
                case DateIntervalType.LastWeek:
                    {
                        dateFrom = dateTo = dateTimeOffsetNow.AddDays(-7);
                        if (dateTimeOffsetNow.DayOfWeek == DayOfWeek.Sunday)
                        {
                            dateFrom = dateFrom.Value.AddDays(-6);
                        }
                        else
                        {
                            dateFrom = dateFrom.Value.AddDays(1 - (int)dateFrom.Value.DayOfWeek);
                            dateTo = dateTo.Value.AddDays(7 - (int)dateTo.Value.DayOfWeek);
                        }
                        break;
                    }
                case DateIntervalType.CurrentMonth:
                    {
                        dateFrom = dateTo = dateTimeOffsetNow;
                        dateFrom = new DateTimeOffset(
                            dateFrom.Value.Year, 
                            dateFrom.Value.Month, 
                            1,
                            dateFrom.Value.Hour,
                            dateFrom.Value.Minute,
                            dateFrom.Value.Second,
                            dateFrom.Value.Millisecond,
                            dateTimeOffsetNow.Offset);
                        dateTo = new DateTimeOffset(
                            dateTo.Value.Year,
                            dateTo.Value.Month,
                            1,
                            dateTo.Value.Hour,
                            dateTo.Value.Minute,
                            dateTo.Value.Second,
                            dateTo.Value.Millisecond,
                            dateTimeOffsetNow.Offset);
                        dateTo = dateTo.Value.AddMonths(1).AddDays(-1);
                        break;
                    }
                case DateIntervalType.LastMonth:
                    {
                        dateFrom = dateTo = dateTimeOffsetNow.AddMonths(-1);
                        dateFrom = new DateTimeOffset(
                            dateFrom.Value.Year, 
                            dateFrom.Value.Month,
                            1,
                            dateFrom.Value.Hour,
                            dateFrom.Value.Minute,
                            dateFrom.Value.Second,
                            dateFrom.Value.Millisecond,
                            dateTimeOffsetNow.Offset);
                        dateTo = new DateTimeOffset(
                            dateTo.Value.Year, 
                            dateTo.Value.Month,
                            1,
                            dateTo.Value.Hour,
                            dateTo.Value.Minute,
                            dateTo.Value.Second,
                            dateTo.Value.Millisecond,
                            dateTimeOffsetNow.Offset);
                        dateTo = dateTo.Value.AddMonths(1).AddDays(-1);
                        break;
                    }
                case DateIntervalType.CurrentQuarter:
                    {
                        dateFrom = dateTo = dateTimeOffsetNow;
                        if (quarterMonths == 0)
                        {
                            dateFrom = dateFrom.Value.AddMonths(-2);
                        }
                        else
                        {
                            dateFrom = dateFrom.Value.AddMonths(1 - quarterMonths);
                            dateTo = dateTo.Value.AddMonths(3 - quarterMonths);
                        }
                        dateFrom = new DateTimeOffset(
                            dateFrom.Value.Year, 
                            dateFrom.Value.Month,
                            1,
                            dateFrom.Value.Hour,
                            dateFrom.Value.Minute,
                            dateFrom.Value.Second,
                            dateFrom.Value.Millisecond,
                            dateTimeOffsetNow.Offset);
                        dateTo = new DateTimeOffset(
                            dateTo.Value.Year, 
                            dateTo.Value.Month,
                            1,
                            dateTo.Value.Hour,
                            dateTo.Value.Minute,
                            dateTo.Value.Second,
                            dateTo.Value.Millisecond,
                            dateTimeOffsetNow.Offset);
                        dateTo = dateTo.Value.AddMonths(1).AddDays(-1);
                        break;
                    }
                case DateIntervalType.LastQuarter:
                    {
                        dateFrom = dateTo = dateTimeOffsetNow.AddMonths(-3);
                        if (quarterMonths == 0)
                        {
                            dateFrom = dateFrom.Value.AddMonths(-2);
                        }
                        else
                        {
                            dateFrom = dateFrom.Value.AddMonths(1 - quarterMonths);
                            dateTo = dateTo.Value.AddMonths(3 - quarterMonths);
                        }
                        dateFrom = new DateTimeOffset(
                            dateFrom.Value.Year, 
                            dateFrom.Value.Month,
                            1,
                            dateFrom.Value.Hour,
                            dateFrom.Value.Minute,
                            dateFrom.Value.Second,
                            dateFrom.Value.Millisecond,
                            dateTimeOffsetNow.Offset);
                        dateTo = new DateTimeOffset(
                            dateTo.Value.Year, 
                            dateTo.Value.Month,
                            1,
                            dateTo.Value.Hour,
                            dateTo.Value.Minute,
                            dateTo.Value.Second,
                            dateTo.Value.Millisecond,
                            dateTimeOffsetNow.Offset);
                        dateTo = dateTo.Value.AddMonths(1).AddDays(-1);
                        break;
                    }
                case DateIntervalType.CurrentYear:
                    {
                        dateFrom = dateTo = dateTimeOffsetNow;
                        dateFrom = new DateTimeOffset(
                            dateFrom.Value.Year, 
                            1,
                            1,
                            dateFrom.Value.Hour,
                            dateFrom.Value.Minute,
                            dateFrom.Value.Second,
                            dateFrom.Value.Millisecond,
                            dateTimeOffsetNow.Offset);
                        dateTo = new DateTimeOffset(
                            dateTo.Value.Year, 
                            12,
                            31,
                            dateTo.Value.Hour,
                            dateTo.Value.Minute,
                            dateTo.Value.Second,
                            dateTo.Value.Millisecond,
                            dateTimeOffsetNow.Offset);
                        break;
                    }
                case DateIntervalType.LastYear:
                    {
                        dateFrom = dateTo = dateTimeOffsetNow.AddYears(-1);
                        dateFrom = new DateTimeOffset(
                            dateFrom.Value.Year, 
                            1,
                            1,
                            dateFrom.Value.Hour,
                            dateFrom.Value.Minute,
                            dateFrom.Value.Second,
                            dateFrom.Value.Millisecond,
                            dateTimeOffsetNow.Offset);
                        dateTo = new DateTimeOffset(
                            dateTo.Value.Year, 
                            12,
                            31,
                            dateTo.Value.Hour,
                            dateTo.Value.Minute,
                            dateTo.Value.Second,
                            dateTo.Value.Millisecond,
                            dateTimeOffsetNow.Offset);
                        break;
                    }
            }
        }

        public DateInterval(DateIntervalType dateIntervalType) : this(DateTimeOffset.Now, dateIntervalType)
        {
        }

        public DateInterval() : this(DateIntervalType.Undefined)
        {
        }

        #endregion Methods

        #endregion Public Members
    }
}