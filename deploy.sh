#!/bin/bash

rm -rf bundle
tar -xzf checkin.tgz
cd bundle/server/node_modules
rm -rf fibers
npm install fibers@1.0.0
