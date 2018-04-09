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
# move the backup data to the correct restore location

# global VARs
export CONFLUENCEAPPDIR="/var/atlassian/application-data/confluence"
export CONFLUENCESTART=""
export CONFLUENCETARBALL=""
export CONFLUENCERESTOREDIR=$CONFLUENCEAPPDIR/restore/

# code
#
# check that base confluence is installed
if [[ ! -d $CONFLUENCEAPPDIR ]] ; then
  echo "Couldnt find $CONFLUENCEAPPDIR. Exiting."
  exit 1
fi

# input the name of the tarball we're working with.
echo "Ensure that your source tarball is in the same location as this script."
read -p "Enter the name of the source tarball file thats in the current directory." CONFLUENCETARBALL

# check that the tarball file exists.
if [[ ! -f $CONFLUENCETARBALL ]] ; then
  echo "Couldnt find $CONFLUENCETARBALL in the current directory. Exiting."
  exit 1
fi

# if our restore directory doesnt exist then create it and fix perms
if [[ ! -d $CONFLUENCERESTOREDIR ]] ; then
  sudo mkdir $CONFLUENCERESTOREDIR || exit 1
  sudo chown confluence:confluence $CONFLUENCERESTOREDIR || exit 1
  sudo chmod 755 confluence:confluence $CONFLUENCERESTOREDIR || exit 1
fi

# extract the tar tarball
cd || exit 1
tar -zxvf $CONFLUENCETARBALL

# copy our latest backup file into the restore dir
sudo cp `sudo find ./var/atlassian/application-data/confluence/backups/ -type f -printf '%p\n' | sort | head -n 1` $CONFLUENCERESTOREDIR

# clean up
# sudo rm -rf ./var
# sudo rm -f $CONFLUENCETARBALL
