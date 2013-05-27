Teams = new Meteor.Collection("teams")
Checkins = new Meteor.Collection("checkins")

if (Meteor.isClient) {
  Template.main.teams = function() {
    return Teams.find();
  };

  Template.main.checkins = function() {
    return Checkins.find();
  };

  Template.main.days = function() {
    return _.uniq(Checkins.find().map(function(checkin) {
      return checkin.created_day;
    })).map(function(formattedDate) {
      return new Date(formattedDate);
    });
  };

  Template.main.preview = function() {
    return Session.get('preview');
  };

  Template.main.events({
    'click #add-new-checkin': function() {
      var team = Teams.findOne($('#team').val());
      var description = $('#text').val();
      var created_date = new Date();
      var abc = Checkins.insert({
	team: team,
	description: description,
	created_date: created_date.toISOString(),
	created_day: getDay(created_date).toISOString()
      });
      $('#text').val('');
      Session.set('preview', '');
      console.log(Checkins.findOne(abc));
    },

    'keyup #text': function() {
      Session.set('preview', $('#text').val());
    }
  });

  Template.day.displayString = function() {
    return this.toLocaleDateString();
  };

  Template.day.team_days = function() {
    var day = this;
    return Teams.find().map(function(team) {
      return {team: team, day: day};
    });
  };

  Template.team_day.checkins = function() {
    return Checkins.find({team: this.team});
  };
}

if (Meteor.isServer) {
  Meteor.startup(function () {
    if (Teams.find().count() === 0) {
      Teams.insert({name: "Team 1"});
      Teams.insert({name: "Team 2"});
    }
  });
}

function getDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}
