Teams = new Meteor.Collection 'players'
Checkins = new Meteor.Collection('checkins')

Checkins.latest = (teamId) -> Checkins.findOne(
  {teamId: teamId},
  {sort: [
    ['day', 'desc']
    ['createdDate', 'desc']]})

if Meteor.isClient
  Time =
    occursToday: (date) ->
      todayStart = (new Date()).setHours(0,0,0,0)
      todayStart <= date
    occurredYesterday: (date) ->
      todayStart = (new Date()).setHours(0,0,0,0)
      yesterdayStart = todayStart - 86400000
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
    setInterval = -> interval = Meteor.setInterval(update, 1000)
    clearInterval = -> Meteor.clearInterval(interval)

    class PrivateDate
      constructor: ->
        update()
        setInterval()
      depend: -> dateDep.depend()
      getDate: -> date
    @get: ->
      instance ?= new PrivateDate()


  Template.main.teams = -> Teams.find({}, {sort: [['name', 'asc']]})

  Template.main.checkins = () -> Checkins.find()

  Template.main.showDays = -> Session.get('showDays')

  Template.main.days = () ->
    days = Template.main.checkins().map (checkin) -> checkin.day
    _.uniq(days).sort().reverse().map (day) -> new Date(day)

  Template.main.columnWidth = -> 100 / (Template.main.teams().count())

  Template.main.events =
    'click #show-days-yes': ->
      Session.set('showDays', true)

    'click #show-days-no': ->
      Session.set('showDays', false)

  Template.teamHeader.edit = -> Session.equals('adding', @_id)

  Template.teamHeader.events =
    'click .add-checkin': ->
      Session.set('adding', @_id)

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
      else if Time.occurredYesterday((new Date(checkin.day)))
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
      createdDate = new Date()
      Checkins.insert
        teamId: @_id
        description: description
        day: new Date(createdDate.getFullYear(), createdDate.getMonth(), createdDate.getDate()).toISOString()
        createdDate: createdDate.toISOString()
      $('#text').val('')
      Session.set('preview', '')
      Session.set('adding', null)

    'click #cancel-new-checkin': ->
      Session.set('preview', '')
      Session.set('adding', null)

    'keyup #text': -> Session.set('preview', $('#text').val())

if Meteor.isServer
  Meteor.startup ->
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
