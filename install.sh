#!/bin/bash

# The version variable along with the major flag will be used to determine if the
# current version of encore installed is compatible with this version
# major 1 will throw an error if current version is * PATCHED or more then .25 diff from
# the installed version

# V is version number
# P is a patched version in development because I dont get how branches work on git yet
#currents V2.05 P2.05


# Whole number updates aren't compatible with each other and require re-initialization
# ie V1.74 Cant update to V2.25 all data will need to be decrypted before the update
# PVersion will update with a keyword "force" in the update call ie encore update force
#  V1.25 !-> V2.00 P1.50 -> VX.xx Patched versions can update for debugging but will require 
# re initilazaation

installer_version="P2.15"

function update() {
    source /opt/encore/scripts/functions.sh
    

    old_ver=$version
    ## verson verification
    key_max="$(($key_max -1))"
    #stupid fix for a stupid mistake i dont want to fix ^

    ### VERSION INFO
    need1="2."
    need2="P"
    keyword="$1"

    if [[ "$old_ver" != "$installer_version" && "$keyword" != "force" ]]; then 
    
        if [[ "$installer_version" == *"$need2"* ]]; then
            #This is a patched version for development
            echo -e "These version are compatible but may need to be initialized"
            echo -e "These version are compatible but may need to be initialized" >> $logdir
            major=0
        elif [[ "$installer_version" == *"$need1"* ]]; then
            echo -e "Copatibility check passed"
            major=0
        else
            echo -e "These versions are not garunteed to be compatible with eachother"
            echo -e "To continue decrypt all file and run \" encore update force\""
            exit 1
        fi

    elif [[ "$old_ver" != "$installer_version" && "$keyword" == "force" ]]; then
    
        echo -e "YOUR RUNNING THE UPDATE WITH FORCE THIS WILL DELETE ALL KEYS MAPS AND DATA"
        echo -e "TO CONTINUE TYPE: DO AS I SAY AND DELETE EVERYTHING"
        read dais

        if [[ "$dais" == "DO AS I SAY AND DELETE EVERYTHING" ]]; then 
            major=1
        else
            echo "Your misspelled the key word or had a change of heart ?"
            exit 1
        fi
    
    else
        echo -e "Versions are the same ? Sorry I fucked up somewhere..."
        exit 2
    fi

    # verifying the install works correctly

    # functionallity test
    test_key_num="$(shuf -i $key_cur-$key_max -n 1)"
    
    # where the file originally came from
    test_key="$plnjson/$test_key_num.json"

    # test_path="$(cat "$test_key" | jq ' .location' | sed 's/"//g')"
    test_path="$(cat "$test_key" | jq ' .location' | sed 's/"//g' )"
    if [[ -f "$test_path" ]]; then

        echo -e "Keys present checking validity \n"
        echo -e "Creating some random data \n"
        test_data="$(fetch_keys $test_key_num | base64)"

        echo "$test_data" | tee -a /tmp/encore.tmp
        encore write /tmp/encore.tmp system te-st >> $logdir
        old_val_lip="$(grep -c "leave_in_peace=1" /opt/encore/config)"

        if [[ "$old_val_lip" -gt "0" ]]; then
            sed -i 's/leave_in_peace=1/leave_in_peace=0/g' /opt/encore/config
        else
            relazy
        fi

        old_val_verb="$(grep -c "leave_in_peace=1" /opt/encore/config)"

        if [[ "$old_val_verb" -eq "0" ]]; then
            echo -e "The config file has been modified \n"
            # echo -e "The config file has been modified \n"
        fi

        encore destroy system te-st >> $logdir

        if [[ "$old_val_lip" -gt "0" ]]; then
            sed -i 's/leave_in_peace=1/leave_in_peace=0/g' /opt/encore/config
        else
            relazy
        fi
        echo "Your current install is valid we'll update and run this test again"

        if [[ -d /tmp/encryption-core ]]; then 
            rm -rfv /tmp/encryption-core >> $logdir
        else 
            relazy
        fi

        git -C /tmp clone https://github.com/Dj-Codeman/encryption-core

        sed -i "s/Vx.xx/$installer_version/g" /tmp/encryption-core/scripts/functions.sh

        cp -v /tmp/encryption-core/install.sh /opt/encore/install.sh
        cp -v /tmp/encryption-core/scripts/debug.sh /opt/encore/scripts/debug.sh
        cp -v /tmp/encryption-core/scripts/encore /opt/encore/scripts/encore
        cp -v /tmp/encryption-core/scripts/encrypt /opt/encore/scripts/encrypt
        cp -v /tmp/encryption-core/scripts/functions.sh /opt/encore/scripts/functions.sh
        if [[ "$major" == "1" ]]; then
            cp -v /tmp/encryption-core/config /opt/encore/config
            encore initialize
        fi

        #############
        # SECOND TEST
        # functionallity test
        unset test_key_num
        test_key_num="$(shuf -i $key_cur-$key_max -n 1)"
    
        # where the file originally came from
        test_key="$plnjson/$test_key_num.json"
        test_path="$(cat "$test_key" | jq ' .location' | sed 's/"//g')"

        if [[ -f "$test_path" ]]; then
            echo -e "Keys present checking validity \n"
            echo -e "Creating some random data \n"
            test_data="$(fetch_keys $test_key_num | base64)"

            echo "$test_data" | tee -a /tmp/encore.tmp
            encore write /tmp/encore.tmp system te-st >> $logdir
            old_val_lip="$(grep -c "leave_in_peace=1" /opt/encore/config)"

            if [[ "$old_val_lip" -gt "0" ]]; then
                sed -i 's/leave_in_peace=1/leave_in_peace=0/g' /opt/encore/config
            fi

            old_val_verb="$(grep -c "leave_in_peace=1" /opt/encore/config)"

            if [[ "$old_val_verb" -eq "0" ]]; then
                echo -e "The config file has been modified \n"
                # echo -e "The config file has been modified \n"
            fi

            encore destroy system te-st >> $logdir

            # sed -i 's/leave_in_peace=0/'"'$old_val_lip'"'/g' /opt/encore/config

            echo "The update was sucessful im just cleaning up a few things"
            # Restore from the backups 

            if [[ "$old_val_lip" -gt "0" ]]; then
                sed -i 's/leave_in_peace=1/leave_in_peace=0/g' /opt/encore/config
            else
                relazy
            fi
            #add section for restoring from the backups
            #zip the backup 
            
            rversion="$(encore version)"

            if [[ "$rversion" != "$installer_version" ]]; then
                sed -i "s/$rversion/$new_ver/g" /opt/encore/scripts/functions.sh
            else
                relazy
            fi
            
            rversion="$(encore version)"
            echo "Congrats encore has been updated your new version is $rversion"
            if [[ "$major" == "1" ]]; then 
                echo -e "Just in case something went wrong you have backups of all your data in /tmp/encore"
            fi
            exit 0
        fi

    else
        echo -e "Your install is broken ? you have backups in /tmp/encore_bkp you should reinstall"

    fi
}

function install() {

    if [ "$1" != "force" ]; then
        if [[ -f "/usr/bin/pacman" ]]; then
            pacman -Sy jq vim xxd
        elif [[ -f "/usr/bin/apt" ]]; then
            apt-get install jq vim xxd -y
        elif [[ -f "/usr/bin/yum" ]]; then
            yum install jr jp xxd vim-common -y
        else
            echo -e "Small problem. I dont know how to install the dependencies on your distro \n"
            echo -e "All I need is jq and xxd and vim"
            echo -e "I Don't recommend it but if you want to skip this call this script with force after it i.e install force"
            exit 1
        fi
    fi

    if [[ -f ./scripts/encrypt ]]; then
        relazy
        echo -e "encrypt scripts found"
    else
        wget -i https://raw.githubusercontent.com/fastsitephp/fastsitephp/master/scripts/shell/bash/encrypt.sh >/tmp/encore/scripts/encrypt
    fi

    mkdir -pv /opt/encore/logs
    mkdir -pv /etc/encore
    mkdir -pv /var/encore
    mkdir -pv /var/log/encore

    cp -Rv ./* /opt/encore/

    chmod +x /opt/encore/*
    chmod +x /opt/encore/scripts/*

    ln -s /opt/encore/scripts/encore /usr/local/bin/encore
    ln -s /opt/encore/config /etc/encore/config
    ln -s /opt/encore/scripts/encrypt /usr/local/bin/encrypt
    source /opt/encore/config


    encore initialize

    chown -Rfv $USER:$USER /opt/encore/* >> $logdir
    chown -Rfv $USER:$USER /var/encore/* >> $logdir
    chown -Rfv $USER:$USER /var/log/encore >> $logdir
    chown -Rfv $USER:$USER /etc/encore >> $logdir

    chmod -Rv 400 /etc/systemkey.dk >> $logdir
    chmod -Rv 500 /var/encore >> $logdir
    chmod -Rv 400 /opt/encore/config >> $logdir

    touch "$logdir"

    if [[ -f "$logdir" ]]; then
        echo -e "Hello ZA WORLDO \n" >>"$logdir"
    else
        echo "Error Creating log file. This optional-ish but aside from that encore has been installed"
        exit 1
    fi

    echo "encore installed sucessfully !"
    exit 0

}

function relazy() {
    echo "hello out thereeeeee" >/dev/null
}

function backup() {
    source /opt/encore/config


    if [ "$1" == "data" ]; then
        cur_dir=$datadir
        tmp_dir="/tmp/encore_bkp/data"
    elif [ "$1" == "indexs" ]; then
        cur_dir=$plnjson
        tmp_dir="/tmp/encore_bkp/indexs"
    elif [ "$1" == "maps" ]; then 
        cur_dir=$encjson
        tmp_dir="/tmp/encore_bkp/maps"
    elif [ "$1" == "keys" ]; then
        cur_dir=$keydir
        tmp_dir="/tmp/encore_bkp/keys"
        last=1
    fi

    if [ -d "$cur_dir" ]; then
        relazy
    else
        echo -e "The folder $cur_dir is in a non normal directory, I can't handle that right now \n"
        echo -e "You can change the cur_dir variable in this script if you need too"
        exit 1
    fi

    #  created tmp folder
    mkdir -pv "$tmp_dir"

    # testing if the folder was created
    if [ -d "$tmp_dir" ]; then
        relazy
    else
        echo -e "Shit.. I couldn't create $tmp_dir it might be a permission issue. \n"
        echo -e " Or I might be broke. If your confident its me send me an email at dwhitfield@ramfield.net"
        exit 1
    fi

    cp -rfv "$cur_dir/" "$tmp_dir"
}

# check that this script is running as root
person="$(whoami)"
if [[ "$person" != "root" ]]; then
    echo -e "YOU SHALL NOT PROCEED!! \n you need to be root !"
    exit 1
fi

if [ -f "/usr/local/bin/encore" ]; then
    # encore is already installed migrate keys and jsons

    if [ -f "/opt/encore/config" ]; then
        # make backup of the keys and the jsons

        # backing up files
        backup "indexs"
        backup "keys"
        backup "maps"
        backup "data"

    else
        echo -e "The config file isn't in the normal direcrory /opt/encore/config \n"
        echo -e "This script will close to keep unintentional effects from occouring \n"
        exit 1
    fi


    # after backups are done
    update "$1"

else

    install "$1"

fi
