#!/bin/bash

function debug_json {
    
    # assiging pos vars 
    class=$1
    shortname=$2

    base="$jsondir/$shortname-$class"
    index_long="$base.json"
    index_short="$base.jn"

    #test if json exists
    if [ -f "$index_long" ]; then    
        echo "encrypted index exists"
        encrypt -d -i "$index_long" -o "$index_short" -k "$( cat "$(fetch_keys "systemkey")" )"
        if [ -f "$index_short" ]; then
            echo "decrypted index existes"

            # current path to encrypted file
            path="$(cat "$index_short" | jq ' .path' | sed 's/"//g')"

            # key used for the encryption
            key="$(cat "$index_short" | jq ' .key' | sed 's/"//g')"

            #uid is the base64 encoding file name
            uid="$(cat "$index_short" | jq ' .uid' | sed 's/"//g')"
    
            # where the file originally came from
            olddir="$(cat "$index_short" | jq ' .dir' | sed 's/"//g')"

            echo -e "variables pulled from json file\n"

            echo -e "$path\n"
            echo -e "$key\n"
            echo -e "$uid\n"
            echo -e "$olddir\n"
        fi
        echo "Variables from json\n"
        rm -v "$index_short"
    fi
}