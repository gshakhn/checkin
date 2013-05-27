if (Meteor.isClient) {
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
    return Checkins.find(
	{teamId: this.team._id, day: this.day.toISOString()},
	{sort: [["createdDate", "desc"]]});
  };

  Template.teamLatest.checkin = function() {
    return Checkins.findOne(
	{teamId: this._id},
	{sort: [["day", "desc"], ["createdDate", "desc"]]});
  }
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
