var DateIntervalType = {
    Undefined:      { value: "Undefined",       code: 00,   description: "undefined"        },
    Today:          { value: "Today",           code: 01,   description: "today"            },
    Yesterday:      { value: "Yesterday",       code: 02,   description: "yesterday"        },
    CurrentWeek:    { value: "CurrentWeek",     code: 03,   description: "current week"     },
    LastWeek:       { value: "LastWeek",        code: 04,   description: "last week"        },
    CurrentMonth:   { value: "CurrentMonth",    code: 05,   description: "current month"    },
    LastMonth:      { value: "LastMonth",       code: 06,   description: "last month"       },
    CurrentQuarter: { value: "CurrentQuarter",  code: 07,   description: "current quarter"  },
    LastQuarter:    { value: "LastQuarter",     code: 08,   description: "last quarter"     },
    CurrentYear:    { value: "CurrentYear",     code: 09,   description: "current year"     },
    LastYear:       { value: "LastYear",        code: 10,   description: "last year"        }
};

var DayOfWeek = function () {
    var days = {
        Sunday:     { value: "Sunday",      code: 0 },
        Monday:     { value: "Monday",      code: 1 },
        Tuesday:    { value: "Tuesday",     code: 2 },
        Wednesday:  { value: "Wednesday",   code: 3 },
        Thursday:   { value: "Thursday",    code: 4 },
        Friday:     { value: "Friday",      code: 5 },
        Saturday:   { value: "Saturday",    code: 6 }
    };
    var first = days.Monday;
    var getFirst = function () {
        return first;
    };
    var setFirst = function (value) {
        for (var day in days) {
            if (value === days[day].value) {
                first = days[day];
                break;
            }
        }
    };
    var getWeekdays = function () {
        var weekdays = [];
        for (var day in days) {
            weekdays.push(days[day]);
        }
        return [].concat(weekdays.slice(first.code, weekdays.length)).concat(weekdays.slice(0, first.code));
    };
    var timeSpanDigits = function (value) {
        var digits = "";
        if (value > 9) {
            digits += value;
        } else {
            digits += "0" + value;
        }
        return digits;
    };
    var timeSpanPhrase = function (value, plural, singular) {
        var phrase = "";
        if (value > 0) {
            if (value > 1) {
                phrase += value + plural;
            } else {
                phrase += value + singular;
            }
        }
        return phrase;
    };
    var timeSpanRound = function (value) {
        if (value.seconds >= 30) {
            if (value.minutes === 59) {
                if (value.hours === 23) {
                    value.hours = 0;
                } else {
                    value.hours++;
                }
                value.minutes = 0;
            } else {
                value.minutes++;
            }
            value.seconds = 0;
        }
    };
    var getTimeSpan = function (seconds, format) {
        var timeSpan = {
            format: format,
            isPozitive: true,
            seconds: seconds,
            toString: ""
        };
        if (timeSpan.seconds != null) {
            if (timeSpan.seconds < 0) {
                timeSpan.isPozitive = false;
                timeSpan.seconds = Math.abs(timeSpan.seconds);
                timeSpan.toString += "-";
            }
            timeSpan.hours = Math.floor(timeSpan.seconds / 3600);
            timeSpan.seconds -= timeSpan.hours * 3600;
            timeSpan.minutes = Math.floor(timeSpan.seconds / 60);
            timeSpan.seconds -= timeSpan.minutes * 60;
            switch (timeSpan.format) {
                case 0:
                    {
                        timeSpan.toString +=
                            timeSpanDigits(timeSpan.hours) + ":" +
                            timeSpanDigits(timeSpan.minutes) + ":" +
                            timeSpanDigits(timeSpan.seconds);
                        break;
                    }
                case 1:
                    {
                        timeSpan.toString +=
                            timeSpanPhrase(timeSpan.hours, " hours ", " hour ") +
                            timeSpanPhrase(timeSpan.minutes, " minutes ", " minute ") +
                            timeSpanPhrase(timeSpan.seconds, " seconds ", " second ");
                        break;
                    }
                case 2:
                    {
                        timeSpanRound(timeSpan);
                        timeSpan.toString +=
                            timeSpanDigits(timeSpan.hours) + ":" +
                            timeSpanDigits(timeSpan.minutes);
                        break;
                    }
                case 3:
                    {
                        timeSpanRound(timeSpan);
                        timeSpan.toString +=
                            timeSpanPhrase(timeSpan.hours, " hours ", " hour ") +
                            timeSpanPhrase(timeSpan.minutes, " minutes ", " minute ");
                        break;
                    }
            }
        }
        return timeSpan;
    };
    return {
        days: days,
        getFirst: getFirst,
        setFirst: setFirst,
        getWeekdays: getWeekdays,
        getTimeSpan: getTimeSpan
    };
}();

function DateInterval() {
    this.dateNow = new Date();
    this.includeTime = false;
    this.dateIntervalType = DateIntervalType.Undefined;
    this.dateFrom = null;
    this.dateTo = null;
    this.getDateNow = function () {
        return this.dateNow;
    };
    this.getDateFrom = function () {
        var value = null;
        if (this.dateFrom != null) {
            if (this.includeTime) {
                value = new Date(this.dateFrom.getTime());
            } else {
                value = new Date(this.dateFrom.getFullYear(), this.dateFrom.getMonth(), this.dateFrom.getDate());
            }
        }
        return value;
    };
    this.getDateTo = function () {
        var value = null;
        if (this.dateTo != null) {
            if (this.includeTime) {
                value = new Date(this.dateTo.getTime());
            } else {
                value = new Date(this.dateTo.getFullYear(), this.dateTo.getMonth(), this.dateTo.getDate());
                value.setDate(value.getDate() + 1);
                value.setMilliseconds(value.getMilliseconds() - 3);
            }
        }
        return value;
    };
    this.setDate = function (date) {
        if (date == null) {
            this.dateFrom = null;
            this.dateTo = null;
        } else {
            date = date.getTime();
            this.dateFrom = new Date(date);
            this.dateTo = new Date(date);
        }
    };
    this.setWeek = function () {
        var days = DayOfWeek.getFirst().code - this.dateNow.getDay();
        this.dateFrom.setDate(this.dateFrom.getDate() + days);
        if (days > 0) {
            this.dateFrom.setDate(this.dateFrom.getDate() - 7);
        }
        this.dateTo.setDate(this.dateFrom.getDate() + 6);
    };
    this.setMonth = function () {
        this.dateTo.setMonth(this.dateTo.getMonth() + 1);
        this.dateTo.setDate(0);
    };
    this.setQuarter = function () {
        var months = (this.dateNow.getMonth() + 1) % 3;
        if (months === 0) {
            this.dateFrom.setMonth(this.dateFrom.getMonth() - 2);
        }
        else {
            this.dateFrom.setMonth(this.dateFrom.getMonth() + 1 - months);
            this.dateTo.setMonth(this.dateTo.getMonth() + 3 - months);
        }
        this.setMonth();
    };
    this.setYear = function () {
        this.dateFrom.setMonth(0);
        this.dateTo.setMonth(11);
        this.setMonth();
    };
    this.setDateInterval = function () {
        var date = new Date(this.dateNow.getTime());
        switch (this.dateIntervalType) {
            case DateIntervalType.Undefined:
                {
                    this.setDate(null);
                    break;
                }
            case DateIntervalType.Today:
                {
                    this.setDate(date);
                    break;
                }
            case DateIntervalType.Yesterday:
                {
                    date.setDate(date.getDate() - 1);
                    this.setDate(date);
                    break;
                }
            case DateIntervalType.CurrentWeek:
                {
                    this.setDate(date);
                    this.setWeek();
                    break;
                }
            case DateIntervalType.LastWeek:
                {
                    date.setDate(date.getDate() - 7);
                    this.setDate(date);
                    this.setWeek();
                    break;
                }
            case DateIntervalType.CurrentMonth:
                {
                    date.setDate(1);
                    this.setDate(date);
                    this.setMonth();
                    break;
                }
            case DateIntervalType.LastMonth:
                {
                    date.setDate(1);
                    date.setMonth(date.getMonth() - 1);
                    this.setDate(date);
                    this.setMonth();
                    break;
                }
            case DateIntervalType.CurrentQuarter:
                {
                    date.setDate(1);
                    this.setDate(date);
                    this.setQuarter();
                    break;
                }
            case DateIntervalType.LastQuarter:
                {
                    date.setDate(1);
                    date.setMonth(date.getMonth() - 3);
                    this.setDate(date);
                    this.setQuarter();
                    break;
                }
            case DateIntervalType.CurrentYear:
                {
                    date.setDate(1);
                    this.setDate(date);
                    this.setYear();
                    break;
                }
            case DateIntervalType.LastYear:
                {
                    date.setDate(1);
                    date.setYear(date.getFullYear() - 1);
                    this.setDate(date);
                    this.setYear();
                    break;
                }
        }
    };
}
