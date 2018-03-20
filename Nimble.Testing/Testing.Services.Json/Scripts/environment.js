function setAjaxUrl(method) {
    return $("#serviceEndpoint")[0].value + method;
}

function setRequestHeader(xhr) {
    xhr.setRequestHeader("EmplacementCode", $("#emplacementCode")[0].value);
    xhr.setRequestHeader("ApplicationCode", $("#applicationCode")[0].value);
    xhr.setRequestHeader("CultureCode", $("#cultureCode")[0].value);
    xhr.setRequestHeader("TokenCode", $("#tokenCode")[0].value);
}

function setRequestStatus(message, fault) {
    $("#requestStatus")[0].value = message;
    if (fault) {
        $("#requestStatus").css("color", "red");
    } else {
        $("#requestStatus").css("color", "green");
    }
}

function clearRequestStatus() {
    setRequestStatus("", false);
}

function setSuccessRequestStatus() {
    setRequestStatus("Success!", false);
}

function processError(response) {
    try {
        setRequestStatus(JSON.parse(response.responseText).Message, true);
    } catch (e) {
        setRequestStatus(response.statusText, true);
    }
}

Date.prototype.isValid = function () {
    return this.getTime() === this.getTime();
};

String.prototype.getWcfJsonDate = function () {
    return new Date(parseInt(this.match(/\/Date\(([0-9]+)(?:.*)\)\//)[1]));
};

Object.prototype.getWcfJsonDateOffset = function () {
    var dateOffset = null;
    if (this.hasOwnProperty("DateTime")) {
        dateOffset = this.DateTime.getWcfJsonDate();
    }
    return dateOffset;
};

Date.prototype.setWcfJsonDate = function () {
    var date = null;
    if (this.isValid()) {
        date = "/Date(" + this.getTime() + ")/";
    }
    return date;
};

Date.prototype.setWcfJsonDateOffset = function () {
    var dateOffset = null;
    var date = this.setWcfJsonDate();
    if (date != null) {
        dateOffset = {
            DateTime: date,
            OffsetMinutes: -this.getTimezoneOffset()
        };
    }
    return dateOffset;
};

function NewGuid() {
    return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
}

function login() {
    clearRequestStatus();
    var tokenCode = $("#tokenCode")[0];
    var userCode = $("#userCode")[0];
    var userPassword = $("#userPassword")[0];
    $.ajax({
        url: setAjaxUrl("Framework/Common.svc/Web/Login"),
        type: "POST",
        cache: false,
        data: JSON.stringify({ userCode: userCode.value }) + JSON.stringify({ userPassword: userPassword.value }),
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        processData: true,
        success: function (response) {
            setSuccessRequestStatus();
            tokenCode.value = response.Code;
        },
        error: function (response) {
            processError(response);
        },
        beforeSend: function (xhr) {
            setRequestHeader(xhr);
        }
    });
}

function logout() {
    clearRequestStatus();
    var tokenCode = $("#tokenCode")[0];
    $.ajax({
        url: setAjaxUrl("Framework/Common.svc/Web/Logout"),
        type: "POST",
        cache: false,
        data: "{}",
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        processData: true,
        success: function (response) {
            setSuccessRequestStatus();
            if (response) {
                tokenCode.value = "";
            }
        },
        error: function (response) {
            processError(response);
        },
        beforeSend: function (xhr) {
            setRequestHeader(xhr);
        }
    });
}

function signIn() {
    clearRequestStatus();
    var tokenCode = $("#tokenCode")[0];
    var referenceId = $("#referenceId")[0];
    $.ajax({
        url: setAjaxUrl("Framework/Common.svc/Web/SignIn"),
        type: "POST",
        cache: false,
        data: JSON.stringify({ referenceId: referenceId.value }),
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        processData: true,
        success: function (response) {
            setSuccessRequestStatus();
            tokenCode.value = response.Code;
        },
        error: function (response) {
            processError(response);
        },
        beforeSend: function (xhr) {
            setRequestHeader(xhr);
        }
    });
}

function dateIntervalType() {
    var txtDateNow = $("#txtDateNow")[0];
    var chkIncludeTime = $("#chkIncludeTime")[0];
    var ddlFirstDayOfWeek = $("#ddlFirstDayOfWeek");
    var ddlDateIntervalType = $("#ddlDateIntervalType");
    var lblDateNow = $("#lblDateNow")[0];
    var lblDateFrom = $("#lblDateFrom")[0];
    var lblDateTo = $("#lblDateTo")[0];
    txtDateNow.valueAsDate = new Date();
    chkIncludeTime.checked = false;
    ddlFirstDayOfWeek.empty();
    for (var day in DayOfWeek.days) {
        ddlFirstDayOfWeek.append(
            "<option value=\"" +
                 DayOfWeek.days[day].value +
            "\">" +
             DayOfWeek.days[day].value + "</option>"
        );
    }
    ddlDateIntervalType.empty();
    for (var dateIntervalType in DateIntervalType) {
        ddlDateIntervalType.append(
            "<option value=\"" +
                DateIntervalType[dateIntervalType].value +
            "\">" +
            DateIntervalType[dateIntervalType].description + "</option>"
        );
    }
    lblDateNow.value = lblDateFrom.value = lblDateTo.value = "";
}

function dateInterval() {
    var txtDateNow = $("#txtDateNow")[0];
    var chkIncludeTime = $("#chkIncludeTime")[0];
    var ddlFirstDayOfWeek = $("#ddlFirstDayOfWeek")[0];
    var ddlDateIntervalType = $("#ddlDateIntervalType")[0];
    var lblDateNow = $("#lblDateNow")[0];
    var lblDateFrom = $("#lblDateFrom")[0];
    var lblDateTo = $("#lblDateTo")[0];
    var dateInterval = new DateInterval();
    for (var item in DateIntervalType) {
        if (DateIntervalType[item].value == ddlDateIntervalType.value) {
            if (txtDateNow.value != "") {
                var date = new Date(txtDateNow.value);
                date.setHours(dateInterval.dateNow.getHours());
                date.setMinutes(dateInterval.dateNow.getMinutes());
                date.setSeconds(dateInterval.dateNow.getSeconds());
                date.setMilliseconds(dateInterval.dateNow.getMilliseconds());
                dateInterval.dateNow = date;
            }
            dateInterval.includeTime = chkIncludeTime.checked;
            dateInterval.dateIntervalType = DateIntervalType[item];
            DayOfWeek.setFirst(ddlFirstDayOfWeek.value);
            dateInterval.setDateInterval();
            lblDateNow.value = dateInterval.getDateNow();
            lblDateFrom.value = dateInterval.getDateFrom();
            lblDateTo.value = dateInterval.getDateTo();
            break;
        }
    }
}

function multilanguage() {
    clearRequestStatus();
    var hdfMultilanguage = $("#hdfMultilanguage")[0];
    var hdfToken = $("#hdfToken")[0];
    var ddlCulture = $("#ddlCulture");
    hdfMultilanguage.value = "";
    hdfToken.value = "";
    ddlCulture.empty();
    var token = null;
    var multilanguage = {
        Cultures: null,
        Resources: null,
        Translations: null
    };
    $.ajax({
        url: setAjaxUrl("Framework/Common.svc/Web/Multilanguage"),
        type: "POST",
        cache: false,
        data: JSON.stringify({ culturePredicate: {} }) + JSON.stringify({ resourcePredicate: {} }) + JSON.stringify({ translationPredicate: { Translated: true } }),
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        processData: true,
        async: false,
        success: function (response) {
            setSuccessRequestStatus();
            multilanguage.Cultures = response.m_Item1;
            multilanguage.Resources = response.m_Item2;
            multilanguage.Translations = response.m_Item3;
            token = response.m_Item4;
            hdfMultilanguage.value = JSON.stringify(multilanguage);
            hdfToken.value = JSON.stringify(token);
            for (var index = 0; index < multilanguage.Cultures.length; index++) {
                ddlCulture.append(
                    "<option value=\"" +
                    multilanguage.Cultures[index].Id +
                    "\">" +
                    multilanguage.Cultures[index].Code + "</option>"
                );
            }
        },
        error: function (response) {
            processError(response);
        },
        beforeSend: function (xhr) {
            setRequestHeader(xhr);
        }
    });
}

function translation() {
    clearRequestStatus();
    var hdfMultilanguage = $("#hdfMultilanguage")[0];
    var hdfToken = $("#hdfToken")[0];
    var lblTranslation = $("#lblTranslation")[0];
    var resourceCode = $("#txtResourceCode")[0];
    var resourceCategory = $("#txtResourceCategory")[0];
    var requests = parseInt(($("#txtRequests")[0]).value);
    var resourceLatencyDays = $("#resourceLatencyDays")[0];
    var cultureId = $("#ddlCulture")[0];
    if (hdfMultilanguage.value == "" ||
        hdfToken.value == "") {
        for (var index = 0; index < requests; index++) {
            $.ajax({
                url: setAjaxUrl("Framework/Common.svc/Web/Translate"),
                type: "POST",
                cache: false,
                data: JSON.stringify({ code: resourceCode.value }) + JSON.stringify({ category: resourceCategory.value }) + JSON.stringify({ parameters: null }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                processData: true,
                async: false,
                success: function(response) {
                    setSuccessRequestStatus();
                    lblTranslation.value = response;
                },
                error: function(response) {
                    processError(response);
                },
                beforeSend: function(xhr) {
                    setRequestHeader(xhr);
                }
            });
        }
    } else {
        var multilanguage = JSON.parse(hdfMultilanguage.value);
        var token = JSON.parse(hdfToken.value);
        var resource = {
            Emplacement: token.Emplacement,
            Application: token.Application,
            Code: resourceCode.value,
            Category: resourceCategory.value
        };
        var resourceIndex = 0;
        var resourceEntity = null;
        jQuery.each(multilanguage.Resources, function (index, item) {
            if (item.Emplacement.Id == resource.Emplacement.Id &&
                item.Application.Id == resource.Application.Id &&
                item.Code == resource.Code &&
                item.Category == resource.Category) {
                resourceIndex = index;
                resourceEntity = item;
                return false;
            }
            return true;
        });
        var lastUsedOn = null;
        if (resourceEntity == null ||
            (resourceEntity.LastUsedOn != null)) {
            lastUsedOn = resourceEntity.LastUsedOn.getWcfJsonDate();
            lastUsedOn.setDate(lastUsedOn.getDate() + parseInt(resourceLatencyDays.value));
        }
        if (lastUsedOn == null ||
            lastUsedOn.getTime() < new Date().getTime()) {
            $.ajax({
                url: setAjaxUrl("Framework/Multilanguage.svc/Web/ResourceRead"),
                type: "POST",
                cache: false,
                data: JSON.stringify({
                    resource: resource
                }),
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                processData: true,
                async: false,
                success: function (response) {
                    setSuccessRequestStatus();
                    resource = response;
                },
                error: function (response) {
                    processError(response);
                },
                beforeSend: function (xhr) {
                    setRequestHeader(xhr);
                }
            });
            if (resource.Id == undefined) {
                return;
            }
            if (resourceEntity == null) {
                multilanguage.Resources.push(resource);
            } else {
                multilanguage.Resources[resourceIndex] = resource;
            }
            hdfMultilanguage.value = JSON.stringify(multilanguage);
        } else {
            resource = resourceEntity;
        }
        var translation = {
            Resource: resource,
            Culture: {
                Id: cultureId.value
            }
        };
        var translationEntity = null;
        jQuery.each(multilanguage.Translations, function (index, item) {
            if (item.Resource.Id == translation.Resource.Id &&
                item.Culture.Id == translation.Culture.Id) {
                translationEntity = item;
                return false;
            }
            return true;
        });
        if (translationEntity == null) {
            lblTranslation.value = resource.Code;
        } else {
            lblTranslation.value = translationEntity.Sense;
        }
    }
}

function tokenRead() {
    clearRequestStatus();
    var tokenId = $("#lblTokenId")[0];
    $.ajax({
        url: setAjaxUrl("Framework/Common.svc/Web/TokenRead"),
        type: "POST",
        cache: false,
        data: "{}",
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        processData: true,
        success: function (response) {
            setSuccessRequestStatus();
            if (response.Id != undefined) {
                tokenId.value = response.Id;
            } else {
                tokenId.value = "Not logged yet!";
            }
        },
        error: function (response) {
            processError(response);
            tokenId.value = "";
        },
        beforeSend: function (xhr) {
            setRequestHeader(xhr);
        }
    });
    $(document).ajaxStop(function () {
    });
}

function userSearch() {
    clearRequestStatus();
    var userCount = $("#lblUserCount")[0];
    $.ajax({
        url: setAjaxUrl("Framework/Security.svc/Web/UserSearch"),
        type: "POST",
        cache: false,
        data: JSON.stringify({
            userPredicate: {
            }
        }),
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        processData: true,
        success: function (response) {
            setSuccessRequestStatus();
            userCount.value = response.Entities.length;
        },
        error: function (response) {
            processError(response);
            userCount.value = "";
        },
        beforeSend: function (xhr) {
            setRequestHeader(xhr);
        }
    });
}

function userCreate() {
    clearRequestStatus();
    var emplacementCode = $("#emplacementCode")[0];
    var userCode = $("#txtUserCode")[0];
    var userCreatedOn = $("#txtUserCreatedOn")[0];
    var userLockedOn = $("#txtUserLockedOn")[0];
    var user = {
        Emplacement: {
            Code: emplacementCode.value
        },
        Code: NewGuid(),
        Password: "1",
        LockedOn: new Date().setWcfJsonDateOffset()
    };
    $.ajax({
        url: setAjaxUrl("Framework/Security.svc/Web/UserCreate"),
        type: "POST",
        cache: false,
        data: JSON.stringify({
            user: user
        }),
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        processData: true,
        success: function (response) {
            setSuccessRequestStatus();
            userCode.value = response.Code;
            userCreatedOn.value = response.CreatedOn.getWcfJsonDateOffset();
            userLockedOn.value = response.LockedOn.getWcfJsonDateOffset();
        },
        error: function (response) {
            processError(response);
            userCode.value = userCreatedOn.value = userLockedOn.value = "";
        },
        beforeSend: function (xhr) {
            setRequestHeader(xhr);
        }
    });
}

function branchSearch() {
    clearRequestStatus();
    var branchCount = $("#lblBranchCount")[0];
    $.ajax({
        url: setAjaxUrl("Framework/Owner.svc/Web/BranchSearch"),
        type: "POST",
        cache: false,
        data: JSON.stringify({
            branchPredicate: {
                LoadData: true
            }
        }),
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        processData: true,
        success: function (response) {
            setSuccessRequestStatus();
            branchCount.value = response.Entities.length;
        },
        error: function (response) {
            processError(response);
            branchCount.value = "";
        },
        beforeSend: function (xhr) {
            setRequestHeader(xhr);
        }
    });
}
