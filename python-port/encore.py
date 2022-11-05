# rewritten encore.sh
import sys
import os
import wget

from functions import *

if not os.geteuid() == 0:
    sys.exit("\nYOU SHALL NOT PASS. you have to be rootn")


def show_help():
    print("encore [write] [read] [destroy] [initialize]")
    print("[update] [version] \n")
    print("encore write FILE name owner \n")
    print("encore read name owner \n")
    print("encore destroy name owner \n")
    print("encore initialize **WARNING THIS WILL DELETE ANY STORED DATA AND KEYS** \n")
    # print("encore  backup *Not implemented yet*")
    if version == "V1.50":
        print("encore update just performs a wellness test \n")
    else:
        print("encore update performs system wellness test then downloads the lates version of encore \n")


action = str(sys.argv[1])

if action == "write":

    path = str(sys.argv[2])
    real_path = os.path.realpath(path)
    class_name = str(sys.argv[3])
    class_item = str(sys.argv[4])

    exists = os.path.exists(real_path)
    if exists == True:
        print("fwrite", real_path, class_item, class_name)
    else:
        sys.exit("File name given does not exists")

elif action == "read":

    class_name = str(sys.argv[2])
    class_item = str(sys.argv[3])

    print("fread", class_item, class_name)

elif action == "destroy":

    class_name = str(sys.argv[2])
    class_item = str(sys.argv[3])

    print("fread", class_item, class_name)

elif action == "initialize":

    initialize()

elif action == "debug":

    action_2 = str(sys.argv[2])

    if action_2 == "json":

        print("debug_json", class_item, class_name)

    else:

        print("echo neither of us know where start here")


elif action == "update":

    if os.path.exists("/opt/encore/install.sh"):
        os.remove("/opt/encore/install.sh")
    else:
        relazy()

    url = str("https://raw.githubusercontent.com/Dj-Codeman/encryption-core/master/install.py")
    filename = wget.download(url, out="/tmp/install.py")

    # count the variables set
    arguments = int(len(sys.argv))

    if arguments == 3:
        option = str(sys.argv[2])

        if option == "force":
            os.system('bash',filename,option)
        else :
            sys.exit("\nInvalid keyword for update ",option,"\n")

    else:
        os.system('bash',filename)

elif action == "version":
    print("Version:", version)

elif action == "help":

    print("Version:", version, "\n")
    show_help()

else:

    show_help()

exit()
