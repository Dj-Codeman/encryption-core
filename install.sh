#!/bin/bash

#Who is running this 

person="$(whoami)"

if [[ "$person" != "root" ]]; then
    echo "This script must be run as root"
    exit 1
fi


# jr and jp are the only dependencies for json editing
# I only use ubuntu and arch btw
if [[ -f "/usr/bin/pacman" ]]; then 
pacman -Sy jr jp
elif [[ -f "/usr/bin/apt" ]]; then
apt-get -y install jr jp
fi

mkdir /opt/encore

mv -v ./* /opt/encore/

chmod +xv /opt/encore/scripts

ln -s /opt/encore/scripts/encore /usr/local/bin/encore

ln -s /opt/encore/scripts/encrypt /usr/local/bin/encrypt

encore initialize

chown -rfv $USER:$USER /opt/encore

exit 0