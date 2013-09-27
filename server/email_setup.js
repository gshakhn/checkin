Accounts.emailTemplates.siteName = "Checkin";
Accounts.emailTemplates.from = "Noreply Checkin <checkin@example.com>";
Accounts.emailTemplates.enrollAccount.subject = function () {
    return "Account setup for Checkin";
};
Accounts.emailTemplates.enrollAccount.text = function (user, url) {
    return "Thanks for signing up for Checkin!"
        + " To activate your account, simply click the link below:\n\n"
        + url;
};

(function () {
    "use strict";

    Accounts.urls.resetPassword = function (token) {
        return Meteor.absoluteUrl('reset-password/' + token);
    };

    Accounts.urls.verifyEmail = function (token) {
        return Meteor.absoluteUrl('verify-email/' + token);
    };

    Accounts.urls.enrollAccount = function (token) {
        return Meteor.absoluteUrl('enroll-account/' + token);
    };

})();
