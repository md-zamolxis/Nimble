#region Using

using System;
using Nimble.Business.Library.Attributes;

#endregion Using

namespace Nimble.Business.Library.Common
{
    public enum SessionContextType
    {
        None,
        Wcf,
        Web,
        Win,
        Silverlight,
        Core
    }
    
    public enum MessageBoxCaptionType
    {
        [FieldCategory(Name = "None")]
        None,
        [FieldCategory(Name = "Information")]
        Information,
        [FieldCategory(Name = "Warning")]
        Warning,
        [FieldCategory(Name = "Error")]
        Error
    }

    public enum MessageBoxActionType
    {
        None,
        Add,
        Edit,
        Remove
    }

    public enum MarkType
    {
        [FieldCategory(Name = "select")]
        Select,
        [FieldCategory(Name = "unselect")]
        Unselect,
        [FieldCategory(Name = "invert")]
        Invert
    }

    [Flags]
    public enum IisStateType : short
    {
        Session = 1,
        View = 2,
        Control = 4,
    }

    public enum ObjectNameType
    {
        None,
        WebPageName
    }

    public enum DatePart
    {
        [FieldCategory(Name = "None")]
        None,
        [FieldCategory(Name = "Year")]
        Year,
        [FieldCategory(Name = "Quarter")]
        Quarter,
        [FieldCategory(Name = "Month")]
        Month,
        [FieldCategory(Name = "DayOfYear")]
        DayOfYear,
        [FieldCategory(Name = "Day")]
        Day,
        [FieldCategory(Name = "Week")]
        Week,
        [FieldCategory(Name = "WeekDay")]
        WeekDay,
        [FieldCategory(Name = "Hour")]
        Hour,
        [FieldCategory(Name = "Minute")]
        Minute,
        [FieldCategory(Name = "Second")]
        Second
    }
}