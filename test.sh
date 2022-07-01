#!/bin/bash

echo "test data" | doas tee -a ./test.file

doas encore write ./test.file debug debug

doas encore debug json debug debug

doas encore destroy debug debug