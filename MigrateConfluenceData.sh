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
# Assumptions
# - That the backup data file retrieved from the source server contains the data
#   that is to be restored. If your Confluence server is busy this may not
#   contain the most up to date data.
#
# Requirements
# - must be run as a user. NOT ROOT.
# - SSH access to the source server.
# - sudo access on the source server.
# - sudo access on the local server.

# global VARs
export SOURCESERVER="diapapp02.australiasoutheast.cloudapp.azure.com"
export CONFLUENCEAPPDIR="/var/atlassian/application-data/confluence"
export CONFLUENCEBACKUPSDIR="$CONFLUENCEAPPDIR/backups"
export CONFLUENCERESTOREDIR="$CONFLUENCEAPPDIR/restore"
export CONFLUENCESTART=""
export SSHOK=0 # by default we assume ssh isnt enabled.
export SSHTIMEOUT=5 # number of seconds the ssh client will wait for a connection.
export SSHUSER="ubuntu"
export SSHID="$HOME/.ssh/id_rsa"
export SSHOPTIONS="-i $SSHID -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=$SSHTIMEOUT -o BatchMode=yes -q"

#############################################################
# code starts here
#

# check that we ARENT root.
if [[ $EUID = 0 || $UID = 0 ]] ; then
  echo "Detected script being run as root. Dont do this. Exiting."
  exit 1
fi

# test that we have a local SSH rsa_id.
if [[ ! -e $SSHID ]] ; then
  echo "No ssh id file found at $SSHID. Exiting."
  exit 1
fi

# test SSH access to source server.
ssh -n $SSHOPTIONS $SSHUSER@$SOURCESERVER "echo 2>&1" && SSHOK=1 || SSHOK=0
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
  echo "Couldnt find local $CONFLUENCEAPPDIR. Exiting."
  exit 1
fi

# if our restore directory doesnt exist then create it and fix perms
# we have to use a `sudo test` here because root privs are needed to see
# if the direectory exists.
if sudo test ! -d $CONFLUENCERESTOREDIR ; then
  echo "Confluence restore destination path not found."
  echo "Creating it."
  sudo mkdir $CONFLUENCERESTOREDIR || exit 1
  sudo chown confluence:confluence $CONFLUENCERESTOREDIR || exit 1
  sudo chmod 755 confluence:confluence $CONFLUENCERESTOREDIR || exit 1
  echo "Creation complete."
fi

# Grab the full path and name of our most recent backup file on our source
# server
echo -n "Determining path and name of most recent backup file on source server..."
LATESTCONFLUENCEBACKUPFILE=$(ssh -n $SSHOPTIONS $SSHUSER@$SOURCESERVER "sudo find $CONFLUENCEBACKUPSDIR -ctime 1 -type f" 2>&1)
LATESTCONFLUENCEBACKUPFILENAME=$(basename -- "$LATESTCONFLUENCEBACKUPFILE")
echo "Done."

# Now we need to copy the backup file on the source server to a location on the
# source server we can get to it with our scp.
echo -n "Copy backup file from Confluence backup dir to temporary location..."
ssh -n $SSHOPTIONS $SSHUSER@$SOURCESERVER "sudo cp $LATESTCONFLUENCEBACKUPFILE ~/$LATESTCONFLUENCEBACKUPFILENAME"
echo "Done."

# copy our latest backup file from the source server into a temporary local dir
echo -n "Copy backup file from temporary location on source server to temporary location here..."
scp $SSHOPTIONS $SSHUSER@$SOURCESERVER:~/$LATESTCONFLUENCEBACKUPFILENAME $HOME/
echo "Done."

# Now sudo copy the local temp copy to the restore dir
echo -n "Copy temporary local backup file to local Confluence restore directory..."
sudo cp $HOME/$LATESTCONFLUENCEBACKUPFILENAME $CONFLUENCERESTOREDIR/
echo "Done."

# clean ups
echo -n "Commencing clean ups"
# clean up copy on source server
ssh -n $SSHOPTIONS $SSHUSER@$SOURCESERVER "sudo rm -f ~/$LATESTCONFLUENCEBACKUPFILENAME"

# clean up local copy in $HOME
rm -f $HOME/$LATESTCONFLUENCEBACKUPFILENAME
echo "Done."
