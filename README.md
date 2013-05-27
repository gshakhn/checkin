checkin
=======

A webapp that allows teams to share their status updates.

Setup
=====

This app runs with [meteor](http://meteor.com/). Install via:

    curl https://install.meteor.com | sh

Configure the teams you need by copying `data.json.template` to `data.json` and modifying the teams array appropriately.

Once the teams are setup, you can run the app by doing:

    meteor run --settings data.json.template
    
You can connect to the app at localhost:3000.
