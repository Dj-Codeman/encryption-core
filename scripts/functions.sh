#!/bin/bash
version="Vx.xx"

# reading config file config
source /opt/encore/config

# function for creating keys and json file pairs

function generate_keys {
    echo "Cleaning old keys and generating new ones"
    rm -rfv "$keydir/"
    rm -rfv "$plnjson/"
    rm -rfv "$encjson/"
    rm -rfv "$datadir/"
    mkdir -pv "$keydir/"
    mkdir -pv "$plnjson/"
    mkdir -pv "$datadir"

    #creating new system key
    encrypt -g >"$systemkey"

    # creating json file
    echo "[\"$version\",\"0\",\"$systemkey\",\"NULL\" ]" | jq -r '{ "version":.[0], "number":.[1], "location":.[2], "parent":.[3] }' >"$plnjson/master.json"

    #generating random keys
    for i in $(seq $key_max); do
        encrypt -g >"$keydir/$key_cur.dk"
        echo "[\"$version\",\"$key_cur\",\"$keydir/$key_cur.dk\",\"systemkey.dk\" ]" | jq -r '{ "version":.[0], "number":.[1], "location":.[2], "parent":.[3] }' >"$plnjson/$key_cur.json"
        # incrementing key_cur
        key_cur=$((key_cur + 1))
    done

    unset key_cur
}

function fetch_keys {
    # key number to find information from
    number="$1"

    if [ "$number" == "systemkey" ]; then
        key="$(cat "$plnjson/master.json" | jq '.location' | sed 's/"//g')"
        echo "$key"
    else
        key="$(cat "$plnjson/$number.json" | jq '.location' | sed 's/"//g')"
        echo "$key"
    fi
}

function check_keys {
    #verifying keys are in place and valid
    if [ -f "$(fetch_keys "systemkey")" ]; then
        echo "Systemkey exists" >>$logdir
        # add a section to veryfy key integrity
        # maybe md5 checksum ???
        # key test
        # if failed generate_keys
    else
        echo "Keys missing" >>$logdir
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

    key_max="$(($key_max - 1))"
    key="$(shuf -i "$key_cur"-"$key_max" -n 1)"
    # for the stored file name
    uid="$(fetch_keys $key | sed 's/[ -]//g' | base64 | head -c 10)"

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
        mv -v "$(realpath "$datapath")" "$input" >> $logdir
    else
        cp -v "$(realpath "$datapath")" "$input" >> $logdir
    fi

    if [ -f "$input" ]; then
        echo "File was moved successfully" >> $logdir

        name="$(echo "$shortname-$class" | base64)"
        output="$datadir/$name"
        encrypt -e -i "$input" -o "$output" -k "$(cat "$(fetch_keys $key)")" >> $logdir

        if [ -f "$output" ]; then
            echo -e "\nFile Successfully encrypted" >> $logdir
            # removing plaintext file
            rm $input >> /dev/null
            # shortname_test
            #json base file variable
            encjson="$encjson/$shortname-$class"

            ## If shortname already exists call a flush ... whatever that will be
            shortname=${shortname//$'\n'/}
            class=${class//$'\n'/}
            key=${key//$'\n'/} # if the variable isn't filtered multiple keys are copyed to the json file
            uid=${uid//$'\n'/}
            output=${output//$'\n'/}
            echo "[\"$version\",\"$shortname\",\"$class\",\"$key\",\"$uid\",\"$datapath\",\"$output\"]" | jq -r '{ "version":.[0], "name":.[1], "class":.[2], "key":.[3], "uid":.[4], "path":.[5], "dir":.[6] }' >"$encjson.jn"
            encrypt -e -i "$encjson.jn" -o "$encjson.json" -k "$(cat "$(fetch_keys "systemkey")")" >> $logdir
            if [ -f "$encjson.json" ]; then
                echo "index created succefully" >> $logdir

                rm -v "$encjson.jn" >> $logdir
                unset $uid

                # /opt/encore/function.sh: line 129: unset: 'key number' not a valid identifier ?
                # on ubuntu 16.04 lts
                unset $key
                echo -e "DONE"
                exit 0
            else
                clear
                echo "An error occoured creating index"
                exit 102
            fi
        else
            echo "An error occoured when encrypting file."
            exit 102
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


    index_long="$encjson/$shortname-$class.json"
    index_short="$plnjson/$shortname-$class.jn"

    #test if json exists
    if [ -f "$index_long" ]; then

        encrypt -d -i "$index_long" -o "$index_short" -k "$(cat "$(fetch_keys "systemkey")")" >> $logdir

        # getting variables from the json
        wversion="$(cat "$index_short" | jq ' .version' | sed 's/"//g')"

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

        if [[ "$version" != "$wversion" ]]; then
            echo -e "The version of encore that wrote this file is not the same one that is reading this file"
            echo -e "This might cause errors I recommend unencrypting and destroying this copy and the re-encrypting it"
        fi

        # dont want to leave un encrypted json files out
        rm "$index_short" >> $logdir

        encrypt -d -i "$path" -o "$olddir" -k "$(cat "$(fetch_keys "$key")")" >> $logdir

        echo -e "DONE"
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

    index_long="$encjson/$shortname-$class.json"
    index_short="$plnjson/$shortname-$class.jn"

    encrypt -d -i "$index_long" -o "$index_short" -k "$(cat "$(fetch_keys "systemkey")")" >> $logdir

    # current path to encrypted file
    path="$(cat "$index_short" | jq ' .dir' | sed 's/"//g')"

    #test if json exists
    if [ -f "$index_short" ]; then

        # dont want to leave un encrypted json files out

        rm -v "$index_long" "$index_short" "$path" >>"$logdir"
        echo "$shortname $class destroyed"
        exit 0

    else

        echo "$index_short does not exist" >>"$logdir"
        echo "The decryption failed check config file and index dir and try again"
        exit 1

    fi

}

function initialize {

    echo "Log start" > $logdir

    encrypt -t

    encrypt -b

    check_keys

    generate_keys
}

function relazy {
    echo "Hello out there" >/dev/null
}
