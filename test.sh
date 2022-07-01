#!/bin/bash

echo "test data" | doas tee -a ./test.file


echo " initializing " 
doas encore initialize

echo "Writing test"
doas encore write ./test.file debug debug

echo "Showing vars from json"
doas encore debug json debug debug

echo "destroying test"
doas encore destroy debug debug

echo "redownloading"
doas rm -rfv /tmp/encryption-core 

cd /tmp 

doas git clone https://github.com/Dj-Codeman/encryption-core

cd /tmp/encryption-core 

doas bash install.sh