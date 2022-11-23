#!/usr/bin/env python3
#### ENCORE CONFIG FILE

#LOCATIONS
# Data this is where the finished and encrypted files live
# When keys are regenerated this folder will be emptyied 
# default /var/encore/data

datadir="/var/encore/data"

# JSON This is where plan text maps will live
# these are generated along side the keys
# default /var/encore/indexs

plnjson="/var/encore/indexs"

# This is where the encrypted jsons for written file 
# will live. The json debug tool should be used to decrypt 
# and modify these files

encjson="/var/encore/maps"

# KEY These are the random encryption keys 
# 128 bit strings for use with the encrypt script
# https://www.fastsitephp.com/fr/documents/file-encryption-bash
# default /opt/encore/keys

keydir="/var/encore/keys"

# SYSTEM KEY JSON file that contain location and key information 
# are encrypted using this key
# if this key is missing on script call all file in:
# $datadir will be illegible 
# IF THIS KEY IS DELETED ALL DATA IS CONSIDERED LOST
# default /opt/encore/keys/systemkey.dk

systemkey="/etc/systemkey.dk"

#log dir

logdir="/var/log/encore/general"

# key_max the limit of keys to generate
# default=100

key_max=3

# Works like a key min value
# by key_cur and key_max the range from which keys are picked
# can be changed

key_cur=0

# soft moving
# set 1 to use cp instead of mv when gatheing files to encrypt
# default = 0

soft_move=1

# re-place file
# the original path of files are stored when encrypted
# if set files will be re placed back in there original
# directory
# default=1

re_place=1

# save on destroy
# if you want the destroy function to recover the file before deleting
# the encrypted copy set this to 1
# default=1

leave_in_peace=1