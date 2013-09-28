checkin
=======

A webapp that allows teams to share their status updates.

Setup
=====

This app runs with [meteor](http://meteor.com/). Install via:

    curl https://install.meteor.com | sh

Most packages are managed with meteor, but at least one is managed 
with [meteorite](http://oortcloud.github.io/meteorite/). Once meteorite 
is installed, install meteorite-managed packages with the following command:

    mrt install

Configure the teams you need by copying `data.json.template` to `data.json` and modifying the teams array appropriately.

Once the teams are setup, you can run the app by doing:

    meteor run --settings data.json
    
You can connect to the app at localhost:3000.

License
=======

This plugin is licensed under [Apache License, V2.0].

Feel free to fork and submit pull requests. I'll try to get them into the mainline ASAP.

[Apache License, V2.0]: http://www.apache.org/licenses/LICENSE-2.0
