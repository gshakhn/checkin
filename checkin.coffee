Teams = new Meteor.Collection 'players'
Checkins = new Meteor.Collection('checkins')
GlobalSettings = new Meteor.Collection 'global_settings'

Checkins.addOrUpdate = (teamId, userId, description) ->
  latest = Checkins.latest teamId
  createdDate = new Date()
  day = new Date(createdDate.getFullYear(), createdDate.getMonth(), createdDate.getDate()).toISOString()
  if day isnt latest.day
    Checkins.insert
      teamId: teamId
      description: description
      day: day
      createdDate: createdDate.toISOString()
      user: userId
  else
    Checkins.update { _id: latest._id }, { $set: { description: description, user: userId }}

Checkins.latest = (teamId) -> Checkins.findOne(
  {teamId: teamId},
  {sort: [
    ['day', 'desc']
    ['createdDate', 'desc']]})

GlobalSettings.settingExists = (settingName) ->
  GlobalSettings.findOne({ name: settingName })?

GlobalSettings.getSetting = (settingName) ->
  setting = GlobalSettings.findOne { name: settingName }
  if setting? and setting.value? then setting.value else null

GlobalSettings.setSetting = (settingName, settingValue) ->
  setting = { name: settingName, value: settingValue }
  if GlobalSettings.settingExists settingName
    GlobalSettings.update { name: settingName }, setting
  else
    GlobalSettings.insert setting

if Meteor.isClient
  Time =
    occursToday: (date) ->
      todayStart = (new Date()).setHours(0,0,0,0)
      todayStart <= date
    occurredYesterday: (date) ->
      todayStart = (new Date()).setHours(0,0,0,0)
      yesterdayStart = todayStart - 86400000
      yesterdayStart <= date and todayStart > date
    occurredThisWeek: (date) ->
      todayStart = (new Date()).setHours(0,0,0,0)
      yesterdayStart = todayStart - 604800000
      yesterdayStart <= date and todayStart > date
    minsAgo: (date) ->
      (new Date() - date)/60000
    timeAgoString: (date) ->
      diffMins = Time.minsAgo(date)
      if diffMins < 0
        "Sometime in the future"
      else if diffMins < 1440
        "Today"
      else if diffMins < 44640
        dayNum = Math.floor(diffMins/1440)
        if dayNum > 1
          "#{dayNum} days ago"
        else
          "Yesterday"
      else
        monthNum = Math.floor(diffMins/44640)
        "#{monthNum} month#{if monthNum > 1 then 's' else ''} ago"


  class CurrentDate
    instance = null
    interval = null
    date = null
    dateDep = new Deps.Dependency()
    update = ->
      date = new Date()
      dateDep.changed()
    setInterval = -> interval = Meteor.setInterval(update, 60000)
    clearInterval = -> Meteor.clearInterval(interval)
    class PrivateDate
      constructor: ->
        update()
        setInterval()
      depend: -> dateDep.depend()
      getDate: -> date
    @get: ->
      instance ?= new PrivateDate()


  Router.configure
    layout: 'layout'
    renderTemplates: { nav: { to: 'nav' }}

  Router.map ->
    this.route 'main', { path: '/' }
    this.route 'enroll-account', {
      path: '/enroll-account/:token',
      controller: 'VerifyEmailController',
    }

  class @MainController extends RouteController
    template: 'main'

  class @VerifyEmailController extends MainController
    run: ->
      this.render()
      token = this.params.token
      Accounts.verifyEmail token
      Session.set 'token', token
      Meteor.defer -> $('#verify-email-modal').modal()
    hide: ->
      $('#verify-email-modal').modal('hide')


  Template.nav.usersEnabled = -> GlobalSettings.getSetting 'usersEnabled'
  Template.nav.events =
    'click #log-out-btn': ->
      Meteor.logout (error) -> console.log(error)


  Template.main.teams = -> Teams.find({}, {sort: [['name', 'asc']]})
  Template.main.usersEnabled = -> GlobalSettings.getSetting 'usersEnabled'
  Template.main.teamColumns = ->
    teams = Teams.find({}, {sort: [['name', 'asc']]}).fetch()
    numColumns = 4
    chunkSize = Math.ceil teams.length/numColumns
    teamColumns = []
    for i in [0...numColumns]
      teamColumns.push teams[chunkSize*i ... chunkSize*(i+1)]
    teamColumns
  Template.main.checkins = () -> Checkins.find()
  Template.main.showDays = -> Session.get('showDays')
  Template.main.restrictedDomain = -> GlobalSettings.getSetting 'restrictedDomain'
  Template.main.days = () ->
    days = Template.main.checkins().map (checkin) -> checkin.day
    _.uniq(days).sort().reverse().map (day) -> new Date(day)
  Template.main.columnWidth = -> 100 / (Template.main.teams().count())
  Template.main.events =
    'click #show-days-yes': ->
      Session.set('showDays', true)
    'click #show-days-no': ->
      Session.set('showDays', false)
    'click #create-user': ->
      emailAddress = $('#create-user-email').val().trim()
      Meteor.call('createUserWithEmail', emailAddress)
    'click #create-password': ->
      Accounts.resetPassword Session.get('token'), $('#password-input').val()
      Router.go 'main'
    'click #sign-in-button': ->
      emailAddress = $('#sign-in-email').val()
      password = $('#sign-in-password').val()
      if GlobalSettings.getSetting 'restrictedDomain'
        Meteor.loginWithPassword { username: emailAddress }, password
      else
        Meteor.loginWithPassword {email: emailAddress}, password


  Template.teamHeader.edit = -> Session.equals('adding', @_id)
  Template.teamHeader.alreadyCheckedIn = ->
    latest = Checkins.latest(@_id)
    latest? and Time.occursToday(new Date(latest.createdDate))
  Template.teamHeader.events =
    'click .add-checkin': ->
      Session.set('adding', @_id)
    'click .same-checkin': -> Checkins.addOrUpdate @_id, Meteor.userId(), Checkins.latest(@_id).description
  Template.teamHeader.timeLabel = ->
    CurrentDate.get().depend()
    checkin = Checkins.latest(@_id)
    Time.timeAgoString((new Date(checkin.day))) if checkin
  Template.teamHeader.timeLabelClass = ->
    CurrentDate.get().depend()
    checkin = Checkins.latest(@_id)
    if checkin
      if Time.occursToday((new Date(checkin.day)))
        "label-success"
      else if Time.occurredThisWeek((new Date(checkin.day)))
        "label-warning"


  Template.day.dateString = -> @toLocaleDateString()
  Template.day.teamDays = -> Template.main.teams()
      .map (team) =>
        team: team
        day: @


  Template.teamDay.checkins = -> Checkins.find(
    {
      teamId: @team._id
      day: @day.toISOString()
    },
    {
      sort: [['createdDate', 'desc']]
    })


  Template.teamLatest.checkin = -> Checkins.latest(@_id)
  Template.teamLatest.edit = -> Session.equals('adding', @_id)
  Template.teamLatest.preview = -> Session.get('preview')
  Template.teamLatest.events =
    'click #save-new-checkin': ->
      description = $('#text').val()
      Checkins.addOrUpdate @_id, Meteor.userId(), description
      $('#text').val('')
      Session.set('preview', '')
      Session.set('adding', null)
    'click #cancel-new-checkin': ->
      Session.set('preview', '')
      Session.set('adding', null)
    'keyup #text': -> Session.set('preview', $('#text').val())


if Meteor.isServer
  Meteor.startup ->
    Meteor.methods
      createUserWithEmail: (emailAddress) ->
        user = { email: emailAddress }
        domain = GlobalSettings.getSetting 'restrictedDomain'
        if domain
          user.email = "#{emailAddress}@#{domain}"
          user.username = emailAddress
        userId = Accounts.createUser(user)
        Accounts.sendEnrollmentEmail(userId)

    if Meteor.settings.teams?
      Meteor.settings.teams.forEach (team) ->
        unless Teams.findOne(name: team.name)?
          console.log("Adding team #{team.name}")
          Teams.insert(name: team.name)

    if Meteor.settings.checkins?
      Meteor.settings.checkins.forEach (checkinData) ->
        team = Teams.findOne(name: checkinData.teamName)
        unless Checkins.findOne(day: checkinData.day, teamId: team._id, description: checkinData.description)?
          console.log("Adding checkin for team #{team.name} on #{new Date(checkinData.day).toLocaleDateString()}")
          Checkins.insert
            teamId: team._id
            description: checkinData.description
            day: checkinData.day
            createdDate: (new Date()).toISOString()

    if Meteor.settings.globalSettings?
      domain = Meteor.settings.globalSettings.restrictedDomain
      if domain?
        console.log("Adding global setting: restrictedDomain = #{domain}")
        if domain
          domain = domain.trim()
        GlobalSettings.setSetting 'restrictedDomain', domain

      usersEnabled = Meteor.settings.globalSettings.usersEnabled and domain and process.env.MAIL_URL
      console.log("Adding global setting: usersEnabled = #{usersEnabled}")
      GlobalSettings.setSetting 'usersEnabled', usersEnabled
