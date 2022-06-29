#!/bin/bash
# This is proper config file with the variables for the store call
#
#
#LOCATIONS
# Data this is where the finished and encrypted files live
# When keys are regenerated this folder will be emptyied 
datadir="/mnt/Backups"
# JSON This is where plan text key indexs will live
# these are generated along side the keys
jsondir="/code/encryption/indexs"
# KEY These are the random encryption keys 
# 128 bit strings for use with the encrypt script
# https://www.fastsitephp.com/fr/documents/file-encryption-bash
keydir="/code/encryption/keys"
# SYSTEM KEY JSON file that contain location and key information 
# are encrypted using this key
# if this key is missing on script call all file in:
# $datadir
systemkey="/code/encryption/keys/systemkey.dk"

# key_max the limit of keys to generate
key_max=100