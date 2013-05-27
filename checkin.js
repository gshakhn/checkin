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
      return checkin.day;
    })).sort().reverse().map(function(formattedDate) {
      return new Date(formattedDate);
    });
  };

  Template.main.preview = function() {
    return Session.get('preview');
  };

  Template.main.events({
    'click #add-new-checkin': function() {
      var teamId = $('#team').val();
      var description = $('#text').val();
      var createdDate = new Date();
      var abc = Checkins.insert({
	teamId: teamId,
	description: description,
	day: getDay(createdDate).toISOString(),
	createdDate: createdDate.toISOString()
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

  Template.day.teamDays = function() {
    var day = this;
    return Teams.find().map(function(team) {
      return {team: team, day: day};
    });
  };

  Template.teamDay.checkins = function() {
    return Checkins.find({teamId: this.team._id, day: this.day.toISOString()});
  };
}

if (Meteor.isServer) {
  Meteor.startup(function () {
    Meteor.settings.teams.forEach(function(team) {
      if (Teams.findOne({name: team.name}) === undefined) {
	console.log("Adding team " + team.name);
	Teams.insert({name: team.name});
      }
    });

    if (Meteor.settings.checkins !== undefined) {
      Meteor.settings.checkins.forEach(function(checkinData) {
        var team = Teams.findOne({name: checkinData.teamName});
        if (Checkins.findOne({day: checkinData.day, teamId: team._id, description: checkinData.description}) === undefined) {
	  console.log("Adding checkin for team " + team.name + " on " + (new Date(checkinData.day)).toLocaleDateString());
          Checkins.insert({
            teamId: team._id,
	    description: checkinData.description,
	    day: checkinData.day,
	    createdDate: (new Date()).toISOString()
	  });
        }
      });
    }
  });
}

function getDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}
