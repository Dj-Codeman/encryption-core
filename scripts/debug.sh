#!/bin/bash

source /opt/encore/config

function debug_json {
    
    # assiging pos vars 
    class=$1
    shortname=$2

    base="$encjson/$shortname-$class"
    index_long="$base.json"
    index_short="$base.jn"

    #test if json exists
    if [ -f "$index_long" ]; then    
        echo "encrypted index exists"
        encrypt -d -i "$index_long" -o "$index_short" -k "$( cat "$(fetch_keys "systemkey")" )"
        if [ -f "$index_short" ]; then
            echo "decrypted index existes"

                
            # Version of encore used to write
            version="$(cat "$index_short" | jq ' .version' | sed 's/"//g')"
            
            # current path to encrypted file
            path="$(cat "$index_short" | jq ' .path' | sed 's/"//g')"


            # key used for the encryption
            key="$(cat "$index_short" | jq ' .key' | sed 's/"//g')"

            #uid is the base64 encoding file name
            uid="$(cat "$index_short" | jq ' .uid' | sed 's/"//g')"
    
            # where the file originally came from
            olddir="$(cat "$index_short" | jq ' .dir' | sed 's/"//g')"

            echo -e "variables pulled from json file\n"

            echo -e "Original path: $path\n"
            echo -e "Key used for enc: $key\n"
            echo -e "Unique id: $uid\n"
            echo -e "Location of the enc file: $olddir\n"
            if [[ -f "$olddir" ]];  then
                echo "Encrypted file exists" >> $logdir
            else
                echo "The file: $olddir does not exist"
            fi
        fi
        echo "Variables from json\n"
        rm -v "$index_short"
    fi
}