#!/bin/bash

function relazy {
    echo "Hello out there" >/dev/null
}

#Who is running this

person="$(whoami)"

if [[ "$person" != "root" ]]; then
    echo "This script must be run as root"
    exit 1
fi

if [ -f "/opt/encore/scripts/encore" ]; then

    if [ -f "/opt/encore/config" ]; then

        source "/opt/encore/scripts/functions.sh"

        if [ "$1" == "update" ]; then

            relazy

            # test_file="$jsondir/$shortname-$class.json"

            key_max=10
            key_cur=0

            test_key_num="$(shuf -i $key_cur-$key_max -n 1)"

            # where the file originally came from
            test_key="$jsondir/$test_key_num.json"

            test_path="$(cat "$test_key" | jq ' .location' | sed 's/"//g')"

            if [[ -f "$test_path" ]]; then

                echo -e "Key presents verified - checking if its valid \n"

                echo -e "Creating some random data \n"

                test_data="$(fetch_keys $test_key_number | base64)"

                # ? doas tee -a /tmp/encore is doas a dependency
                echo "$test_data" | tee -a /tmp/encore.tmp

                encore write /tmp/encore.tmp system test

                old_val_lip="$(grep -c "leave_in_peace=1" /opt/encore/config)"

                if [[ "$old_val_lip" -gt "0" ]]; then
                    sed -i 's/leave_in_peace=1/leave_in_peace=0/g' /opt/encore/config
                fi

                old_val_verb="$(grep -c "leave_in_peace=1" /opt/encore/config)"

                if [[ "$old_val_verb" -eq "0" ]]; then
                    echo -e "The config file has been modified \n"
                    # echo -e "The config file has been modified \n"
                fi

                encore destroy system test

                sed -i 's/leave_in_peace=0/'"'$old_val_lip'"'/g' /opt/encore/config

                echo -e "Damn it looks like you installed encore already thank you \n"
                echo -e "Also from my small test it looks like your installation is fine \n"
                echo -e "Phew. well then what can i do for you"

                read -r -p "Update or Delete" options

                # TODO add option to update the script
                # TODO add option to update and keep existing keys and secrets
                # TODO add uninstall option

                echo -e "damn $options thats a great choice but uuhhhh actually theres isnt enough code for that \n"
                echo -e "Sorry"
                exit 0

            fi

            # check if the keys and jsons are valid
            # read json for key path
            # test if the file exists
            # write a random file
            # set leave_in_peace=0
            # destroy file
            # echo something like " you already have a working encore install would you like to "
            # 1.) rotate keys
            # 2.) redownload or update
            # 3.) update while keeping the same keys and data
            # 4.) update while rotating keys but keeping files EXPERIMENTAL
            # 5.) see a magic trick make and delete a folder called system32

            # rotating keys while keeping data
            # decrypt all data to like a random tmp dir or ram drive ???
            # re_generate all keys
            # temporary set leave in peace to 0
            # write like 10 test files
            # destroy them
            # unset leave in peace
            # re write the privious file

            #### WHAT ABOUT THE OLD DIRECTORIES???
        else

            relazy

            # proceed to regular install
            # jr and jp are the only dependencies for json editing
            # I only use ubuntu and arch btw

            if [[ -f "/usr/bin/pacman" ]]; then
                pacman -Sy jr jp vim
            elif [[ -f "/usr/bin/apt" ]]; then
                apt-get -y install jr jp
            elif [[ -f "/usr/bin/yum" ]]; then
                # ! NOT TESTED
                yum install jr jp xxd vim-common -y
            else
                echo -e "small problem I dont know how to install dependencies for you"
                echo -e "all you need is jq for json manipulation xxd and vim-commons"
                exit 1
            fi

            if [[ -f /tmp/encryption-core/scripts/encrypt ]]; then
                relazy
                echo -e "encrypt scripts found"
            else
                wget -i https://raw.githubusercontent.com/fastsitephp/fastsitephp/master/scripts/shell/bash/encrypt.sh >/tmp/encore/scripts/encrypt
            fi

            rm -rfv /opt/encore

            mkdir /opt/encore

            mv -v ./* /opt/encore/

            # mv -v /opt/encore/test.sh ./test.sh

            chmod +x /opt/encore/*
            chmod +x /opt/encore/scripts/*

            ln -s /opt/encore/scripts/encore /usr/local/bin/encore

            ln -s /opt/encore/scripts/encrypt /usr/local/bin/encrypt

            encore initialize

            chown -Rfv $USER:$USER /opt/encore

            if [[ -f /opt/encore/logs/log ]]; then
                source /opt/encore/config
                echo "HELLO ZA WORLDO" >>"$logdir"
            else
                echo "Encore successfully installed but logdir is misconfigured"
            fi

            clear

            echo "encore installed / updated sucessfully"

            exit 0

        fi

    else
        echo -e "I know whats wrong with it \n"
        echo -e "It aint got no config int \n"

        exit 1

    fi

else

    # proceed to regular install
    # jr and jp are the only dependencies for json editing
    # I only use ubuntu and arch btw
    if [[ -f "/usr/bin/pacman" ]]; then
        pacman -Sy jr jp vim
    elif [[ -f "/usr/bin/apt" ]]; then
        apt-get -y install jr jp
    elif [[ -f "/usr/bin/yum" ]]; then
        # ! NOT TESTED
        yum install jr jp xxd vim-common -y
    else
        echo -e "small problem I dont know how to install dependencies for you"
        echo -e "all you need is jq and jr for json manipulation xxd and vim-commons"
        exit 1
    fi

    if [[ -f /tmp/encryption-core/scripts/encrypt ]]; then
        relazy
        echo -e "encrypt scripts found"
    else
        wget -i https://raw.githubusercontent.com/fastsitephp/fastsitephp/master/scripts/shell/bash/encrypt.sh >/tmp/encore/scripts/encrypt
    fi

    rm -rfv /opt/encore

    mkdir /opt/encore

    mv -v ./* /opt/encore/

    # mv -v /opt/encore/test.sh ./test.sh

    chmod +x /opt/encore/*
    chmod +x /opt/encore/scripts/*

    ln -s /opt/encore/scripts/encore /usr/local/bin/encore

    ln -s /opt/encore/scripts/encrypt /usr/local/bin/encrypt

    encore initialize

    chown -Rfv $USER:$USER /opt/encore

    if [[ -f /opt/encore/logs/log ]]; then
        source /opt/encore/config
        echo "HELLO ZA WORLDO" >>"$logdir"
    else
        echo "Encore successfully installed but logdir is misconfigured"
    fi

    clear

    echo "encore installed / updated sucessfully"

    exit 0

fi
