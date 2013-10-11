Accounts.emailTemplates.siteName = "Checkin";
Accounts.emailTemplates.from = "Noreply Checkin <checkin@example.com>";
Accounts.emailTemplates.enrollAccount.subject = -> "Account setup for Checkin"
Accounts.emailTemplates.enrollAccount.text = (user, url) -> "Thanks for signing up for Checkin! To activate your account, simply click the link below:\n\n #{url}"

do ->
  "use strict";
  Accounts.urls.resetPassword = (token) ->
    Meteor.absoluteUrl('reset-password/' + token)
  Accounts.urls.verifyEmail = (token) ->
    Meteor.absoluteUrl('verify-email/' + token)
  Accounts.urls.enrollAccount = (token) ->
    Meteor.absoluteUrl('enroll-account/' + token)
