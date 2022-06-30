#!/bin/bash

# reading config file config
source ./config

# function for creating keys and json file pairs

function generate_keys {
    echo "Cleaning old keys and generating new ones"
    rm -rfv "$keydir/"
    rm -rfv "$jsondir/"
    rm -rfv "$datadir/"
    mkdir -pv "$keydir/"
    mkdir -pv "$jsondir/"
    mkdir -pv "$datadir"
    
    #creating new system key
    encrypt -g > "$systemkey"
    
    # creating json file
    echo "[\"0\",\"$systemkey\",\"NULL\" ]" |
    jq -r '{ "number":.[0], "location":.[1], "parent":.[2] }' \
    > "$jsondir/master.json"

    #generating random keys 
    for i in $(seq $key_max); do
        encrypt -g > "$keydir/$key_cur.dk"
        echo "[\"$k\",\"$keydir/$k.dk\",\"systemkey.dk\" ]" |
        jq -r '{ "number":.[0], "location":.[1], "parent":.[2] }' \
        > "$jsondir/$k.json"
        
        # incrementing key_cur
        key_cur=$((key_cur+1))
    done

    unset key_cur
    unset key_max
}

function fetch_key {
    # key number to find information from
    number="$1"

    if [ "$number" == "systemkey" ]; then
        key="$(cat "$jsondir/master.json" | jq '.location' | \
        sed 's/"//g')"
        echo "$key"
    else
        key="$(cat "$jsondir/$number.json" | jq '.location' | \
        sed 's/"//g')"
        echo "$key"
    fi
}

fetch_key 100