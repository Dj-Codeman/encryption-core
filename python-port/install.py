#!/usr/bin/env python3
import wget
import sys
import os
import wget
import warnings
import shutil

from functions import *

installer_version="P1.00"


arguments = int(len(sys.argv))

if arguments == 1: 
    keyword = str(sys.argv[1])
else :
    keyword = "magic"


def install(keyword):

    if action !="force":
        # checking ubuntu
        apt = "/usr/bin/apt"
        if os.path.exists(apt) == True:
            os_install = "ubuntu"
        
        cent = "/usr/bin/yum"
        if os.path.exists(cent) == True:
            os_install = "centos"

        arch = "/usr/bin/pacman"
        if os.path.exists(arch) == True:
            os_install = "arch"

    pkg_list = "make jq bison libtool automake autoconf flex unzip python3 xxd"

    if os_install == "ubuntu":
        command = f"apt-get install {pkg_list} -y"
        os.system(command)

    elif os_install == "arch":
        command = f"pacman -Sy {pkg_list} --confirm"
        os.system(command)

    elif os_install == "centos":
        command = f"yum install {pkg_list} -y"
        os.system(command)

    else :

        if keyword != "force":
            sys.exit("I Don't support the distro that you use. If you do run this command with --force")
        else :
            warning_msg = f"This tool wasn't build for the distro that your running. Shit might be weird. Good luck"
            warnings.warn(warning_msg, Warning)

    print("Downloading additional dependencies")

    command = "mkdir -pv /tmp/encore/pkgs"
    os.system(command)

    
    # Downloading wget
    command = f"wget -i https://files.pythonhosted.org/packages/47/6a/62e288da7bcda82b935ff0c6cfe542970f04e29c756b0e147251b2fb251f/wget-3.2.zip > /tmp/encore/pkgs/wget-3.2.zip"
    os.system(command)

    # Unpacking and installing wget
    command = f"unzip /tmp/encore/pkgs/wget-3.2.zip"
    os.system(command)

    command = f"python3 /tmp/encore/pkgs/wget-3.2/setup.py install"
    os.system(command)


    # Downloding pyjq
    url = str("https://files.pythonhosted.org/packages/14/c8/03bc4f41abe4b1e900d9bc1f1cebdb79f998a5563364e6ea1533f7b228f8/pyjq-1.0.tar.gz")
    filename = wget.download(url, out="/tmp/encore/pkgs/pyjq.tar.gz")    
    
    command = f"tar -xvf {filename}"
    try :
        os.system(command)
    except:
        sys.exit("Could not install pyjq. Please try again")
    
    # file settings
    mode  = 400

    hit_list ["/opt/encore", "/etc/encore", "/var/encore", "/var/log/encore" ]

    for path in hit_list:
        
        make_folder(path)
    

    base = "/opt/encore"
    dst = f"{base}/{files}"
    hit_list = ["conf", "encore", "functions.py", "install.py"]

    for files in hit_list:
        # copy files into the opt director
        exists = os.path.exists("/usr/local/bin/encrypt")

        if exists == True:
            relazy()
        else :
            print("Falling back to the unpatched encrypt script")
            url = str("https://raw.githubusercontent.com/fastsitephp/fastsitephp/master/scripts/shell/bash/encrypt.sh")
            filename = wget.download(url, out="/opt/encore/scripts/encrypt")

        if os.path.exists(filename) == False:
            sys.exit("Encrypt file was not downloaded oor imported")

    #Done checking and installing dependencies from pkg anagers
    # installing pip stuff 
        



#!https://raw.githubusercontent.com/fastsitephp/fastsitephp/master/scripts/shell/bash/encrypt.sh    