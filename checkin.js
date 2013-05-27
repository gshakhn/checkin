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
