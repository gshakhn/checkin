Teams = new Meteor.Collection 'players'
Checkins = new Meteor.Collection('checkins')

if Meteor.isClient
  Template.main.teams = -> Teams.find({}, {sort: [['name', 'asc']]})

  Template.main.checkins = () -> Checkins.find()

  Template.main.days = () ->
    days = Template.main.checkins().map (checkin) -> checkin.day
    _.uniq(days).sort().reverse().map (day) -> new Date(day)

  Template.main.columnWidth = -> 100 / (Template.main.teams().count())

  Template.teamHeader.edit = -> Session.equals('adding', @_id)

  Template.teamHeader.events =
    'click .add-checkin': ->
      Session.set('adding', @_id)

  Template.day.displayString = -> @toLocaleDateString()

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

  Template.teamLatest.checkin = -> Checkins.findOne(
    {teamId: @_id},
    {sort: [
      ['day', 'desc']
      ['createdDate', 'desc']]})

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
