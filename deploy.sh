#!/bin/bash

rm -rf bundle
tar -xzf checkin.tgz
cd bundle/programs/server/node_modules
rm -rf fibers
npm install fibers@1.0.1
