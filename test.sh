#!/bin/bash

echo "test data" | doas tee -a ./test.file

doas encore initialize

doas encore write ./test.file debug debug

doas encore debug json debug debug

doas encore destroy debug debug

doas rm -rfv /tmp/encryption-core 

cd /tmp 

doas git clone https://github.com/Dj-Codeman/encryption-core