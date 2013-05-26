Teams = new Meteor.Collection("teams")
Checkins = new Meteor.Collection("checkins")

if (Meteor.isClient) {
  Template.main.teams = function() {
    return Teams.find();
  };

  Template.main.checkins = function() {
    return Checkins.find();
  };

  Template.main.events({
    'click #addNewCheckin': function() {
      var team = Teams.findOne($('#team').val());
      var description = $('#text').val();
      Checkins.insert({
	team: team,
	description: description,
	created: new Date().getTime()
      });
    }
  });
}

if (Meteor.isServer) {
  Meteor.startup(function () {
    if (Teams.find().count() === 0) {
      Teams.insert({name: "Team 1"});
      Teams.insert({name: "Team 2"});
    }
  });
}
