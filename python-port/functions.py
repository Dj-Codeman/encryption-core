import hashlib
import base64
import datetime
import random
import warnings
import os
import sys
import shutil
import pyjq
import json
from conf import *

version = "Vx.03"

#! rebuild jq queries with the native json module


def relazy():
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
    delete_file(logdir)
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

def delete_file(path):
    if os.path.exists(path) == True:
        os.remove(path)
    if os.path.exists(path) == False:
        var = f"success"
    else:
        var = f"failed"
    
    if var == "failed":
        warning_msg = f"File {path} exists but was unable to be deleted"
        write_log(warning_msg)
        warnings.warn(warning_msg, Warning)
        
    relazy()

def delete_folder(path):
    if os.path.exists(path) == True:
        shutil.rmtree(path)

    if os.path.exists(path) == False:
        var = f"success"
    else:
        var = f"failed"
    
    if var == "failed":
        warning_msg = f"Path {path} exists but was unable to be deleted"
        write_log(warning_msg)
        warnings.warn(warning_msg, Warning)
        
    relazy()

def make_folder(path):
    if os.path.exists(path) == False:
        os.mkdir(path)
        if os.path.exists(path) == True:
            var = f"success"
        else:
            var = f"failed"
        
        if var == "failed":
            warning_msg = f"Path {path} was unable to be created"
            write_log(warning_msg)
            warnings.warn(warning_msg, Warning)

    else :
        warning_msg = f"Path {dir} already exists"
        write_log(warning_msg)
        warnings.warn(warning_msg, Warning)

def copy_file(src, dst):
    
    if os.path.exists(src) == True:
        flag = 0
    else:
        flag =1

    if os.path.exists(dst) == False:
        relazy()
    else :
        flag += 1

    if flag == 0:

        try: 
            shutil.copyfile(src, dst)
        except:
            warning_msg = f"File {path} exists but was unable to be deleted"
            write_log(warning_msg)
            warnings.warn(warning_msg, Warning)

    else:

        exit_msg = f"Errors occured while copying {src} to {dst}"
        write_log(exit_msg)
        sys.exit(exit_msg)

def generate_keys():

    hit_list = [keydir, plnjson, encjson, datadir]
    
    print("Regenerating keys \n")
    
    for path in hit_list:
        delete_folder(path)
        # exec time buffer
        relazy()
        make_folder(path)
        relazy()

    write_log("Directories tree re-created")

    print("Creating indexs for new keys \n")

    # creating new system key
    command = f"encrypt -g > {systemkey}"
    os.system(command)

    #! learn how this really works
    #! https://www.quickprogrammingtips.com/python/how-to-calculate-md5-hash-of-a-file-in-python.html

    md5_hash = hashlib.md5()
    with open(systemkey, "rb") as f:
        # Read and update hash in chunks of 4K
        for byte_block in iter(lambda: f.read(4096), b""):
            md5_hash.update(byte_block)
    md5_sum = str(md5_hash.hexdigest())

    index = f"{plnjson}/master.json"

    index1 = {
        "version": version,
        "number": '0',
        "location": systemkey,
        "hash": md5_sum
    }

    result1 = pyjq.one(
        '{version: .version , number: .number , location: .location , parent: .parent , hash: .hash}', index1)
    # print(result1)

    # writing the index
    with open(index, "w") as write_file:
        json.dump(result1, write_file, indent=2)
        tmp_log = f"Key index pair: Master Created\n"
        write_log(tmp_log)

#########################################################################################

    # Generating random keys
    i = key_max
    while i >= key_cur:
        # creating key
        command = f"encrypt -g > \"{keydir}/{i}.dk\""
        os.system(command)

        # creating index for the key
        location = f"{keydir}/{i}.dk"
        index = f"{plnjson}/{i}.json"

        # creating md5 hash
        md5_hash = hashlib.md5()
        with open(location, "rb") as f:
            # Read and update hash in chunks of 4K
            for byte_block in iter(lambda: f.read(4096), b""):
                md5_hash.update(byte_block)
        md5_sum = str(md5_hash.hexdigest())

        index1 = {
            "version": version,
            "number": i,
            "location": location,
            "parent": systemkey,
            "hash": md5_sum
        }

        result1 = pyjq.one(
            '{version: .version , number: .number , location: .location , parent: .parent , hash: .hash}', index1)

        # writing the index
        with open(index, "w") as write_file:
            json.dump(result1, write_file, indent=2)
            tmp_log = f"Key index pair: {i} Created\n"
            write_log(tmp_log)

        # adding an exit condition just to be safe
        if i == 0:
            break
        i -= 1


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

    if version != key_version:
        warnings.warn("Key / System version mismatch", Warning)
        write_log("The version tag stored with the key is not the same")
        write_log("As the version of encore running. I recommend")
        write_log("Extracting all of your data and running encore initialize")

    return key_location


def check_keys():

    # print("Checking key integrity \n")
    write_log("Checking key integrity")

    valid = 0
    rand = int(random.randint(key_cur+1, key_max))
    key_depth = int(key_max / rand)
    test_depth = int(random.randint(key_cur + 1, key_depth))

    i = key_depth
    while i >= test_depth:
        key_path = fetch_keys(i)

        if os.path.exists(key_path) == True:
            # if the key exists check the md5 sum
            md5_hash = hashlib.md5()
            with open(key_path, "rb") as f:
                # Read and update hash in chunks of 4K
                for byte_block in iter(lambda: f.read(4096), b""):
                    md5_hash.update(byte_block)

                new_key_hash = str(md5_hash.hexdigest())
                # Got the new md5 sum
                # compare it with the old one
                key_index_path = f"{plnjson}/{i}.json"

                with open(key_index_path) as j:
                    # why tf is this called a dictionary instead of a md array
                    data = json.load(j)
                    old_key_hash = str(data['hash'])

            if new_key_hash != old_key_hash:
                warning_msg = f"Key {i} failed the hash check. Please read back all of your files and re-initialize encore"
                write_log(warning_msg)
                warnings.warn(warning_msg, Warning)

            valid = valid

        else:
            valid += 1
            # failed the test
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
            delete_file(plain_path)
            base_enc_json = f"{encjson}/{object_class}-{object_item}"
            # ? implement a key shift and store it some how
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
            result1 = pyjq.one(
                '{version: .version , name: .name , class: .class , key: .key , uid: .uid , path: .path , dir: .dir}', index1)

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
                delete_file(pln_json)
                print("DONE")
                sys.exit(0)
            else:

                command = f"encrypt -d -i {enc_path} -o {plain_path} -k \"$(cat {key_path})\" >> /dev/null"
                write_log(command)
                os.system(command)

                shutil.copy(plain_path, path)
                if os.path.exists(path) == True:
                    try :
                        delete_file(pln_json)
                        delete_file(enc_path)
                        delete_file(plain_path)
                    except Warning:
                        exit_msg = f"Not all files were deleted. Please save data and re initialize"
                        write_log(exit_msg)
                        sys.exit(exit_msg)
                else :
                    exit_msg = f"Something went really wrong read your logs and pray"
                    write_log(exit_msg)
                    sys.exit(exit_msg)

                sys.exit("Failed to create map")

        else:
            sys.exit("File encryption failed check log and try again")

    else:

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

            delete_file(map_short)

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


def write_test():
    plain_test_path = "/tmp/encore-test.dec"
    enc_test_path = "/tmp/encore-test.enc"
    command = f"echo \"This is some data\" > {plain_test_path}"
    write_log(command)
    os.system(command)
    if os.path.exists(plain_test_path) == True:
        print("Test data written to:", plain_test_path, "\n")
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
                        delete_file(enc_test_path)
                        delete_file(plain_test_path)
                        print("SUCCESS \n")
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


def initialize():

    print('Initializing \n')

    start_log()

    write_log("Started initialization process")

    command = "encrypt -b >> /dev/null"
    os.system(command)

    generate_keys()

    check_keys()

    write_test()

    write_log("Initialization complete")
    print("DONE")
