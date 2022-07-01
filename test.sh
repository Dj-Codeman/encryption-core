#!/bin/bash

doas bash install.sh

echo " initializing " 
doas encore initialize

echo "Showing vars from json"
doas encore debug json test tmp

echo "destroying test"
doas encore destroy test tmp

echo "redownloading"
doas rm -rfv /tmp/encryption-core 

cd /tmp

doas git clone https://github.com/Dj-Codeman/encryption-core 
