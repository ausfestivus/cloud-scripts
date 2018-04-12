#!/bin/bash

# A quick script which will gather the latest JIRA home directory from a source
# JIRA server and copy it to a new JIRA server.
#
# The "source" server is the server which has the currently running JIRA
# on it.
# The "local" server is the server you are migrating on.
#
# This script MUST be run on the local server.
#
# Assumptions
# - That the backup data file retrieved from the source server contains the data
#   that is to be restored. If your JIRA server is busy this may not
#   contain the most up to date data.
#
# Requirements
# - must be run as a user. NOT ROOT.
# - SSH access to the source server.
# - sudo access on the source server.
# - sudo access on the local server.

# pseudo code
# - various pre flight tests
# - stop JIRA on source server
# - create jira home dir backupfile. Create in ~ubuntu user homedir
# - start JIRA on source server
# - copy file to new server
# - shutdown local JIRA on new server
# - rename default local JIRA home dir.
# - extract JIRA tarball to correct local location
# - fix permissions
# - rename dbconfig.xml
# - start JIRA.

# global VARs
export SOURCESERVER="diapapp01.australiasoutheast.cloudapp.azure.com"
export JIRAAPPDIR="/var/atlassian/application-data/jira"
export JIRABACKUPSDIR="$JIRAAPPDIR/export"
export JIRARESTOREDIR="$JIRAAPPDIR/import"
export JIRASTART=""
export SSHOK=0 # by default we assume ssh isnt enabled.
export SSHTIMEOUT=5 # number of seconds the ssh client will wait for a connection.
export SSHUSER="ubuntu"
export SSHID="$HOME/.ssh/id_rsa"
export SSHOPTIONS="-i $SSHID -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=$SSHTIMEOUT -o BatchMode=yes -q"
export ZIPARCHIVENAME=$(date "+%Y%m%d-%H%M%S")

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

# check that base jira is installed
if sudo test ! -d $JIRAAPPDIR ; then
  echo "Couldnt find local $JIRAAPPDIR. Exiting."
  exit 1
fi

# - stop JIRA on source server
echo -n "Stopping JIRA on $SOURCESERVER..."
ssh -n $SSHOPTIONS $SSHUSER@$SOURCESERVER "sudo /etc/init.d/jira stop"
echo "Done."

# - create jira home dir backupfile. Create in ~ubuntu user homedir
echo -n "Creating tarball of JIRA homedir on $SOURCESERVER..."
ssh -n $SSHOPTIONS $SSHUSER@$SOURCESERVER "sudo tar -cvzf $HOME/jira-application-$ZIPARCHIVENAME.tar.gz $JIRAAPPDIR"
echo "Done."

# - start JIRA on source server
echo -n "Starting JIRA on $SOURCESERVER..."
ssh -n $SSHOPTIONS $SSHUSER@$SOURCESERVER "sudo /etc/init.d/jira start"
echo "Done."

# - copy file to new server
echo -n "Copy tarball from source server to temporary location here..."
scp $SSHOPTIONS $SSHUSER@$SOURCESERVER:$HOME/jira-application-$ZIPARCHIVENAME.tar.gz $HOME/
echo "Done."

# - shutdown local JIRA on new server
echo -n "Stopping local JIRA..."
sudo systemctl stop jira
echo "Done."

# - rename default local JIRA home dir.
echo -n "Renaming existing local JIRA home dir..."
sudo mv $JIRAAPPDIR/ $JIRAAPPDIR-$ZIPARCHIVENAME/
echo "Done."

# - extract JIRA tarball to correct local location
echo -n "Extracting JIRA home dir tarball from source server..."
tar zxvf $HOME/jira-application-$ZIPARCHIVENAME.tar.gz
echo "Done."

# - move the directory into place
sudo mv $HOME/var/atlassian/application-data/jira $JIRAAPPDIR

# - fix permissions
sudo chown root:root /var/atlassian/
sudo chown root:root /var/atlassian/application-data/
sudo chown jira:root /var/atlassian/application-data/jira
sudo chmod 700 /var/atlassian/application-data/jira
sudo chown -R jira:jira $JIRAAPPDIR

# - rename dbconfig.xml
sudo mv $JIRAAPPDIR/dbconfig.xml $JIRAAPPDIR/dbconfig-$ZIPARCHIVENAME.xml

# - start local JIRA on new server.
echo -n "Starting local JIRA..."
sudo systemctl start jira
echo "Done."

# - clean ups

# ORIGINAL CODE BELOW HERE
# # Grab the full path and name of our most recent backup file on our source
# # server
# echo -n "Determining path and name of most recent backup file on source server..."
# LATESTJIRABACKUPFILE=$(ssh -n $SSHOPTIONS $SSHUSER@$SOURCESERVER "sudo find $JIRABACKUPSDIR -ctime 1 -type f | sort | head -n 1" 2>&1)
# LATESTJIRABACKUPFILENAME=$(basename -- "$LATESTJIRABACKUPFILE")
# echo "Done."
#
# # Now we need to copy the backup file on the source server to a location on the
# # source server we can get to it with our scp.
# echo -n "Copy backup file from JIRA backup dir to temporary location..."
# ssh -n $SSHOPTIONS $SSHUSER@$SOURCESERVER "sudo cp $LATESTJIRABACKUPFILE ~/$LATESTJIRABACKUPFILENAME"
# echo "Done."
#
# # copy our latest backup file from the source server into a temporary local dir
# echo -n "Copy backup file from temporary location on source server to temporary location here..."
# scp $SSHOPTIONS $SSHUSER@$SOURCESERVER:~/$LATESTJIRABACKUPFILENAME $HOME/
# echo "Done."
#
# # Now sudo copy the local temp copy to the restore dir
# echo -n "Copy temporary local backup file to local JIRA restore directory..."
# sudo cp $HOME/$LATESTJIRABACKUPFILENAME $JIRARESTOREDIR/
# echo "Done."
#
# # clean ups
# echo -n "Commencing clean ups..."
# # clean up copy on source server
# ssh -n $SSHOPTIONS $SSHUSER@$SOURCESERVER "sudo rm -f ~/$LATESTJIRABACKUPFILENAME"
#
# # clean up local copy in $HOME
# rm -f $HOME/$LATESTJIRABACKUPFILENAME
# echo "Done."
