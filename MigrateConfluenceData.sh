#!/bin/bash

# A quick script which will gather the latest backup data file from a source
# Confluence server and copy it to a new CONFLUENCE server.
#
# The "source" server is the server which has the currently running Confluence
# on it.
# The "local" server is the server you are migrating on.
#
# This script MUST be run on the local server.
#
# Requirements
# - must be run as a user. NOT ROOT.
# - SSH access to the source server.
# - sudo access on the source server.
# - sudo access on the local server

# pseudo code
# - that we're NOT root.
# - test SSH access to source server and optionally set it up.
# - test that Confluence is installed on the local server.

# global VARs
export SOURCESERVER=""
export CONFLUENCEAPPDIR="/var/atlassian/application-data/confluence"
export CONFLUENCEBACKUPSDIR="$CONFLUENCEAPPDIR/backups"
export CONFLUENCERESTOREDIR="$CONFLUENCEAPPDIR/restore"
export CONFLUENCESTART=""
export CONFLUENCETARBALL=""
export CONFLUENCERESTOREDIR=$CONFLUENCEAPPDIR/restore/
export SSHOK=0 # by default we assume ssh isnt enabled.
export SSHTIMEOUT=5 # number of seconds the ssh client will wait for a connection.
export SSHUSER="ubuntu"
export SSHOPTIONS="-i ~$SSHUSER/.ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=$SSHTIMEOUT -o BatchMode=yes"



#############################################################
# code starts here
#

# check that we ARENT root.
if [[ $EUID = 0 || $UID = 0 ]] ; then
  echo "Detected script being run as root. Dont do this. Exiting."
  exit 1
fi

# test SSH access to source server.
ssh -n $SSHOPTIONS "echo 2>&1" && SSHOK=1 || SSHOK=0
if [ $SSHOK = 1 ]; then
  # SSH access to target works okay
  echo "SSH access to source server $SOURCESERVER tested okay."
else
  # SSH access to target does not work.
  echo "SSH access to source server $SOURCESERVER failed. Exiting."
  exit 1
fi

# check that base confluence is installed
if [[ ! -d $CONFLUENCEAPPDIR ]] ; then
  echo "Couldnt find $CONFLUENCEAPPDIR. Exiting."
  exit 1
fi

# if our restore directory doesnt exist then create it and fix perms
if [[ ! -d $CONFLUENCERESTOREDIR ]] ; then
  echo "Confluence restore destination path not found."
  echo "Creating it."
  sudo mkdir $CONFLUENCERESTOREDIR || exit 1
  sudo chown confluence:confluence $CONFLUENCERESTOREDIR || exit 1
  sudo chmod 755 confluence:confluence $CONFLUENCERESTOREDIR || exit 1
  echo "Creation complete."
fi


# copy our latest backup file into the restore dir


# clean up
