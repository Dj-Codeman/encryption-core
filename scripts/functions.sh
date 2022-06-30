#!/bin/bash

# reading config file config
source /opt/encore/config

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
}

function fetch_keys {
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

function check_keys {
    #verifying keys are in place and valid
    if [ -f "$(fetch_keys "systemkey")" ]; then
        echo "Systemkey exists" >> ../logs/encore.log
        # add a section to veryfy key integrity
        # maybe md5 checksum ???
        # key test 
        # if failed generate_keys
    else
        echo "Keys missing" >> ../logs/encore.log
        generate_keys
        # refactor for individual json files instead of master index
        echo "Keys were rotated please run again"
        exit 1
    fi
}

function write {
    # positional variables for write command
    # 1. path of the file realpath
    # 2. class for the json file
    # 3. shorhand name
    # example write ./myfile backup 9-05

    # picking a random key
    key="$(shuf -i 1-"$key_max")"
    # for the stored file name
    uid="$(fetch_keys | sed 's/[ -]//g' | base64 | head -c 10; )"

    # assiging pos vars 
    datapath=$1
    class=$2
    shorhand=$3

    if [[ -z $class ]]; then
        echo "No class given"
        exit 1
    fi

    input="$datadir/$shortname-$class.dec"
    path="$(realpath "$datapath")"
    
    # checking for soft move
    if [ "$soft_move" == "0" ]; then
        mv -v "$(realpath "$datapath")" "$input"
    else
        cp -v "$(realpath "$datapath")" "$input"
    fi

    if [ -f "$input" ]; then
        echo "File was moved successfully"

        name="$( echo $shortname-$class | base64 )"
        output="$datadir/$name"
        	encrypt -e -i "$input" -o "$output" -k "$( cat "$(fetch_key $key)" )"
        if [ -f "$output" ]; then
          echo -e "\nFile Successfully encrypted"
          # removing plaintext file
          rm -v "$input"
          # shortname_test
          #json base file variable
          jsonbase="$jsondir/$shortname-$class"
          ## If shortname already exists call a flush ... whatever that will be
          echo "[\"$shortname\",\"$class\",\"$key\",\"$uid\",\"$output\",\"$dir\"]" \
          | jq -r '{ "name":.[0], "class":.[1], "key":.[2], "uid":.[3], "path":.[4], "dir":.[5] }' \
          > "$jsonbase.jn"
          encrypt -e -i "$jsonbase.jn" -o "$jsonbase.json" -k "$( cat "$(fetch_keys "systemkey")" )"
          if [ -f "$jsonbase.json" ]; then
            echo "index created succefully"
            rm "$jsonbase.jn"
	    unset $uid
            unset $key
          else
            clear
            echo "An error occoured creating index"
            exit 102
          fi
        else
          echo "An error occoured when encrypting file."
        fi
    else
      echo "File was not copyed check freespace and try again"
      exit 102
    fi



}

function read {
echo ""
}

function destroy {
echo ""
}

fetch_key 100