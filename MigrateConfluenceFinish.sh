#!/bin/bash

# A quick script which will gather the necessary data from a source CONFLUENCE
# server and copy it to a new CONFLUENCE server.
#
# Requirements
# - must be run as a user. NOT ROOT.
# - you will need sufficient privileges locally to access the source data.
# - you will need to put this script on the new CONFLUENCE server.

# pseudo code
# prompt for input tarball filename
# extract the tarballs
# move the backup data to the correct restore location

# global VARs
export CONFLUENCEAPPDIR="/var/atlassian/application-data/confluence"
export CONFLUENCESTART=""
export CONFLUENCETARBALL=""

# code
#
# input the name of the tarball we're working with.
echo "Ensure that your source tarball is in the same location as this script."
read -p "Enter the name of the source tarball file thats in the current directory." CONFLUENCETARBALL
# check that the file exists.
if [[ ! -f $CONFLUENCETARBALL ]] ; then
  echo "Couldnt find $CONFLUENCETARBALL in the current directory. Exiting."
  exit 1
fi
# extract the tarball.
tar zxvf ./$CONFLUENCETARBALL
# copy our latest backup file into place
sudo find ./var/atlassian/application-data/confluence/backups/ -mtime 1 -exec cp {} /var/atlassian/application-data/confluence \;
