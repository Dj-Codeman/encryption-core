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
    echo "[\"0\",\"$systemkey\",\"NULL\" ]" | jq -r '{ "number":.[0], "location":.[1], "parent":.[2] }' > "$jsondir/master.json"

    #generating random keys 
    for i in $(seq $key_max); do
        encrypt -g > "$keydir/$key_cur.dk"
        echo "[\"$key_cur\",\"$keydir/$key_cur.dk\",\"systemkey.dk\" ]" | jq -r '{ "number":.[0], "location":.[1], "parent":.[2] }' > "$jsondir/$key_cur.json"
        # incrementing key_cur
        key_cur=$((key_cur+1))
    done

    unset key_cur
}

function fetch_keys {   
    # key number to find information from
    number="$1"

    if [ "$number" == "systemkey" ]; then
        key="$(cat "$jsondir/master.json" | jq '.location' | sed 's/"//g')"
        echo "$key"
    else
        key="$(cat "$jsondir/$number.json" | jq '.location' | sed 's/"//g')"
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

function fwrite {   
    # positional variables for write command
    # 1. path of the file realpath
    # 2. class for the json file
    # 3. shorhand name
    # example write ./myfile backup 9-05

    # picking a random key

    key_max="$(($key_max-1))"
    key="$(shuf -i "$key_cur"-"$key_max" -n 1)"
    # for the stored file name
    uid="$(fetch_keys $key | sed 's/[ -]//g' | base64 | head -c 10; )"

    # assiging pos vars 
    datapath=$1
    class=$2
    shortname=$3

    if [[ -z $class ]]; then
        echo "No class given"
        exit 1
    fi

    input="$datadir/$shortname-$class.dec"
    
    # checking for soft move
    if [ "$soft_move" == "0" ]; then
        mv -v "$(realpath "$datapath")" "$input"
    else
        cp -v "$(realpath "$datapath")" "$input"
    fi

    if [ -f "$input" ]; then
        echo "File was moved successfully"

        name="$( echo "$shortname-$class" | base64 )"
        output="$datadir/$name"
        encrypt -e -i "$input" -o "$output" -k "$( cat "$(fetch_keys $key)" )"
        
        if [ -f "$output" ]; then
          echo -e "\nFile Successfully encrypted"
          # removing plaintext file
          rm -v "$input"
          # shortname_test
          #json base file variable
          jsonbase="$jsondir/$shortname-$class"

          ## If shortname already exists call a flush ... whatever that will be
          shortname=${shortname//$'\n'/} 
          class=${class//$'\n'/} 
          key=${key//$'\n'/} # if the variable isn't filtered multiple keys are copyed to the json file
          uid=${uid//$'\n'/} 
          output=${output//$'\n'/} 
          echo "[\"$shortname\",\"$class\",\"$key\",\"$uid\",\"$datapath\",\"$output\"]" | jq -r '{ "name":.[0], "class":.[1], "key":.[2], "uid":.[3], "path":.[4], "dir":.[5] }' > "$jsonbase.jn"
          encrypt -e -i "$jsonbase.jn" -o "$jsonbase.json" -k "$( cat "$(fetch_keys "systemkey")" )"
          if [ -f "$jsonbase.json" ]; then
            echo "index created succefully"
            
            rm -v "$jsonbase.jn"
	        unset $uid

            # /opt/encore/function.sh: line 129: unset: 'key number' not a valid identifier ?
            # on ubuntu 16.04 lts 
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

    unset datapath
    unset class
    unset shorhand

}

function fread {
    # positional variables for write command
    # 1. path of the file realpath
    # 2. class for the json file
    # 3. shorhand name
    # example write ./myfile backup 9-05

    # assiging pos vars 
    class="$1"
    shortname="$2"

    base="$jsondir/$shortname-$class"
    index_long="$base.json"

    #test if json exists
    if [ -f "$index_long" ]; then


        index_short="$base.jn"

        encrypt -d -i "$index_long" -o "$index_short" -k "$(cat "$(fetch_keys "systemkey")" )"
    
        # getting variables from the json 

        # current path to encrypted file
        path="$(cat "$index_short" | jq ' .dir' | sed 's/"//g')"

        # key used for the encryption
        key="$(cat "$index_short" | jq ' .key' | sed 's/"//g')"

        #uid is the base64 encoding file name
        uid="$(cat "$index_short" | jq ' .uid' | sed 's/"//g')"
    
        # where the file originally came from
        olddir="$(cat "$index_short" | jq ' .path' | sed 's/"//g')"

        if [[ $re_place == "0" ]]; then 
            olddir="$datadir/$shortname-$class"
        fi

        # dont want to leave un encrypted json files out
        rm -v "$index_short"    

        encrypt -d -i "$path" -o "$olddir" -k "$(cat "$(fetch_keys "$key")" )"

    else

        echo "$index_long does not exist"
        exit 1

    fi


}
 
function destroy {  
    
    class=$1
    shortname=$2

    if [[ $leave_in_peace == "1" ]]; then
     fread "$class" "$shortname"
    fi

    index_long="$jsondir/$shortname-$class.json"
    index_short="$jsondir/$shortname-$class.jn"

    encrypt -d -i "$index_long" -o "$index_short" -k "$(cat "$(fetch_keys "systemkey")" )"

    #test if json exists
    if [ -f "$index_short" ]; then    

        # dont want to leave un encrypted json files out
        rm "$index_short"    
        rm -v "$index_long" "$index_short" "$path" >> "$logdir" 
        echo "$shortname $class destroyed"
        exit 0

    else

        echo "$index_long does not exist"
        exit 1

    fi

}

function initialize {

    encrypt -t

    encrypt -b
    
    check_keys

    generate_keys
}

function relazy {
    echo "Hello out there" > /dev/null
}