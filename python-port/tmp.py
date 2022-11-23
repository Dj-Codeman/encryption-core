from cnf import *
import json
import pyjq
import shutil
import sys
import os
import warnings
import random
import datetime
import base64
import hashlib

version = "V0.00"


def relazy():
    #! The do nothing function should not be this long
    old_stout = sys.stdout
    null = open('/dev/null', 'w')
    sys.stdout = null
    print("HELLOOOOOO OUTTTTTT THEREEEEEEEEEE")
    sys.stdout = old_stout


def write_log(data):
    now = datetime.datetime.now()
    timestamp = now.strftime("%Y-%m-%d %H:%M:%S")

    write = f"echo -e \"{data}: {timestamp} \n\" >> {logdir}"
    os.system(write)


def start_log():
    if os.path.exists(key_path) == True:
        os.remove(logdir)

    write_log("LOG START")


def b64string(data):
    # converting to base 64
    # for python to b64 encore the string has to be
    # converted to a bytelike object
    data_bytes = data.encode('ascii')
    # base 8 > 6
    data_base64 = base64.b64encode(data_bytes)
    # i read documentation IM BUILT DIFFRENT
    # now convert the encoded string back to ascii
    secret = data_base64.decode('ascii')
    return secret

# i = 65
# version = "V2.06"
# location = f"{keydir}/{i}.dk"
# index = f"{plnjson}/{i}.json"

# index1 = {
#     "version": version,
#     "number": i,
#     "location": location,
#     "parent": systemkey
# }

# result1 = pyjq.one('{version: .version , number: .number , location: .location , parent: .parent}', index1)
# # print(result1)

# # writing the index
# with open(index, "w") as write_file:
#     json.dump(result1, write_file, indent=2)
#     print("Key index pair:",i," Created\n")


def fetch_keys(key):
    if key == "systemkey":
        key_index_path = f"{plnjson}/master.json"
        with open(key_index_path) as j:
            # why tf is this called a dictionary instead of a md array
            data = json.load(j)
            key_version = str(data['version'])
            key_location = str(data['location'])
    else:
        key_index_path = f"{plnjson}/{key}.json"
        with open(key_index_path) as j:
            # why tf is this called a dictionary instead of a md array
            data = json.load(j)
            key_version = str(data['version'])
            key_location = str(data['location'])
    # TODO make the version filtering more complicated later like V1 V2
    if version != key_version:
        warnings.warn("Key / System version mismatch check log", Warning)
        write_log("The version tag stored with the key is not the same")
        write_log("As the version of encore running. I recommend")
        write_log("Extracting all of your data and running encore initialize")

    return key_location


# key_path = fetch_keys(key)

def check_keys():

    valid = 0
    rand = int(random.randint(1, 4))
    key_depth = int(key_max / rand)
    test_depth = int(random.randint(key_cur + 1, key_depth))

    i = key_depth
    while i >= test_depth:
        key_path = fetch_keys(i)

        if os.path.exists(key_path) == True:
            valid = valid
        else:
            valid += 1
            # TODO check the md5 sum
        i -= 1

    if valid == int(0):
        write_log("Keys verified")
    else:
        write_log("Keys missing or invalid re-keying")
        generate_keys()
        sys.exit("Keys were rotated please run again")


def fwrite(path, object_class, object_item):
    # picking random key
    key = int(random.randint(key_cur, key_max-1))
    key_path = fetch_keys(key)

    # taking the first 10 chars of the key to use as the file name
    with open(key_path, 'r') as text:
        # key data is now the entire key
        key_data = text.read()
        # proper file handeling
        text.close

    first_10 = str(key_data[0:10])
    uid = b64string(first_10)

    plain_path = f"{datadir}/{object_class}-{object_item}.dec"

    # checking for soft move in config file
    if soft_move == 0:
        shutil.move(path, plain_path)
        verb = "moved"
    else:
        shutil.copy(path, plain_path)
        verb = "copied"

    test = os.path.exists(plain_path)
    if test == True:

        tmp_log = f"File: {path} {verb} to {plain_path} sucessfully"
        write_log(tmp_log)

        _name = f"{object_class}-{object_item}"
        enc_name = b64string(_name)
        enc_path = f"{datadir}/{enc_name}"

        command = f"encrypt -e -i {plain_path} -o {enc_path} -k \"$(cat {key_path})\" >> /dev/null"
        write_log(command)
        os.system(command)

        test = os.path.exists(enc_path)
        if test == True:
            # deleting the plain copy of the encrypted file
            os.remove(plain_path)
            base_enc_json = f"{encjson}/{object_class}-{object_item}"
            # Making new map
            index1 = {
                "version": version,
                "name": object_item,
                "class": object_class,
                "key": key,
                "uid": uid,
                "path": path,
                "dir": enc_path
            }
            pln_json = f"{base_enc_json}.jn"
            enc_json = f"{base_enc_json}.json"
            result1 = pyjq.one('{version: .version , name: .name , class: .class , key: .key , uid: .uid , path: .path , dir: .dir}', index1)

            with open(pln_json, "w") as write_file:
                json.dump(result1, write_file, indent=2)

            if os.path.exists(pln_json) == True:
                tmp_log = f"Clear map {pln_json} created"
                write_log(tmp_log)
                # encrypting the map
                command = f"encrypt -e -i {pln_json} -o {enc_json} -k \"$(cat {systemkey})\" >> /dev/null"
                write_log(command)
                os.system(command)

            if os.path.exists(enc_json) == True:
                write_log("Sucessfully Encrypted")
                os.remove(pln_json)
                print("DONE")
                sys.exit(0)
            else:
                #TODO While we still have all the data
                #TODO Recover the newly encrypted file
                sys.exit("Failed to create map")

        else:
            sys.exit("File encryption failed check log and try again")

    else :

        exit_msg = f"File {path} was not {verb} sucessfully !"
        sys.exit(exit_msg)


def fread(object_class, object_item):
    map_long = f"{encjson}/{object_class}-{object_item}.json"
    map_short = f"{encjson}/{object_class}-{object_item}.jn"

    if os.path.exists(map_long) == True:
        command = f"encrypt -d -i {map_long} -o {map_short} -k \"$(cat {systemkey})\" >> /dev/null"
        write_log(command)
        os.system(command)
        if os.path.exists(map_short) == True:
            write_log("Decrypted map sucessfully")

            with open(map_short) as j:
                # why tf is this called a dictionary instead of a md array
                data = json.load(j)

                object_version = str(data['version'])
                object_item = str(data['name'])
                object_class = str(data['class'])
                object_key = str(data['key'])
                object_uid = str(data['uid'])
                object_path = str(data['path'])
                object_dir = str(data['dir'])

            if version != object_version:

                warning_msg = "The object and encore are not using to same version."
                write_log(warning_msg)
                warnings.warn(warning_msg, Warning)

            if re_place == 0:
                object_path = f"{datadir}/{object_class}-{object_item}"

            os.remove(map_short)

            key = fetch_keys(object_key)

            command = f"encrypt -d -i {object_dir} -o {object_path} -k \"$(cat {key})\" >> /dev/null"
            write_log(command)
            os.system(command)

            tmp_log = f"{object_class}-{object_item} Has been decrypted"
            write_log(tmp_log)
            print("DONE")

    else:
        exit_msg = f"{map_long} Does not exist"
        write_log(exit_msg)
        sys.exit(exit_msg)

def write_test():
    plain_test_path = "/tmp/encore-test.dec"
    enc_test_path = "/tmp/encore-test.enc"
    command = f"echo \"This is some data\" > {plain_test_path}"
    write_log(command)
    os.system(command)
    if os.path.exists(plain_test_path) == True:
        print("Test data written to:", plain_test_path)
        check_keys()
        command = f"encrypt -e -i {plain_test_path} -o {enc_test_path}  -k \"$(cat {systemkey})\" >> /dev/null"
        write_log(command)
        os.system(command)
        if os.path.exists(enc_test_path) == True:
            os.remove(plain_test_path)
            if os.path.exists(plain_test_path) == False:
                command = f"encrypt -d -i {enc_test_path} -o {plain_test_path} -k \"$(cat {systemkey})\" >> /dev/null"
                write_log(command)
                os.system(command)
                if os.path.exists(plain_test_path) == True:
                    with open(plain_test_path, 'r') as text:
                        # key data is now the entire key
                        Data = text.read()
                        # proper file handeling
                        text.close
                    if Data == "This is some data\n":
                        os.remove(enc_test_path)
                        os.remove(plain_test_path)
                        print("SUCCESS")
                    else:
                        relazy()
            else:
                exit_msg = f"The writing part worked but the deleting didnt ?"
                write_log(exit_msg)
                sys.exit(exit_msg)
        else:
            exit_msg = f"Writing test fail check permissions and try again"
            write_log(exit_msg)
            sys.exit(exit_msg)
    else:
        exit_msg = f"Writing test fail check permissions and try again"
        write_log(exit_msg)
        sys.exit(exit_msg)

def destroy(object_class, object_item):
    if leave_in_peace == 1:
        print("READING")
        fread(object_class,object_item)

    map_long = f"{encjson}/{object_class}-{object_item}.json"
    map_short = f"{encjson}/{object_class}-{object_item}.jn"

    if os.path.exists(map_long) == True:
        command = f"encrypt -d -i {map_long} -o {map_short} -k \"$(cat {systemkey})\" >> /dev/null"
        write_log(command)
        os.system(command)
        if os.path.exists(map_short) == True:
            write_log("Decrypted map sucessfully")

            with open(map_short) as j:
                # why tf is this called a dictionary instead of a md array
                data = json.load(j)

                object_version = str(data['version'])
                object_item = str(data['name'])
                object_class = str(data['class'])
                object_key = str(data['key'])
                object_uid = str(data['uid'])
                object_path = str(data['path'])
                object_dir = str(data['dir'])

    # Deleting junk and making sure its gone
        try:
            delete_file(object_dir)
            delete_file(map_long)
            delete_file(map_short)
        except Warning:
            sys.exit("Not all files were deleted ")

    tmp_log = f"{object_class}-{object_item} Destroyed successfully"
    write_log(tmp_log)
    print("DONE")


action = str(sys.argv[1])
#
if action == "read":
#
    object_class = str(sys.argv[2])
    object_item = str(sys.argv[3])
#
    fread(object_class, object_item)
#
elif action == "write":

    path = str(sys.argv[2])
    real_path = os.path.realpath(path)
    object_class = str(sys.argv[3])
    object_item = str(sys.argv[4])

    exists = os.path.exists(real_path)
    if exists == True:
        check_keys()
        fwrite(real_path, object_class, object_item)
    else:
        sys.exit("File name given does not exists")
else:
    relazy()