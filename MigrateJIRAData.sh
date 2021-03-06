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
## Assumptions
# - Your new JIRA and Confluence servers are up and running per the rest of this repo.
# - Your existing JIRA and Confluence servers are running the built in backups.
# - your running JIRA and Confluence on Linux.
# - you have keyed ssh access to the source and destination servers.
# - your non-root user has the same username on all servers.
# - The non-root user has sudo access on all the servers.
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
export SOURCESERVER="{FQDN of source Jira server.}" #fqdn of source server goes here.
export SSHUSER="{local non-root user}" # username that is used by the script for ssh. Must be the same on source and destination servers.
export JIRAAPPDIR="/var/atlassian/application-data/jira"
export JIRABACKUPSDIR="$JIRAAPPDIR/export"
export JIRARESTOREDIR="$JIRAAPPDIR/import"
export JIRASTART=""
export SSHOK=0 # by default we assume ssh isnt enabled.
export SSHTIMEOUT=5 # number of seconds the ssh client will wait for a connection.
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
echo -n "Extracting JIRA home dir tarball from source server to a local temp directory..."
tar zxvf $HOME/jira-application-$ZIPARCHIVENAME.tar.gz
echo "Done."

# - move the extracted jira directory into the correct place
echo -n "Moving the extracted JIRA dir to the correct local location..."
sudo mv $HOME/var/atlassian/application-data/jira /var/atlassian/application-data/
echo "Done."

# - fix permissions
echo -n "Fixing the permissions on the app dir..."
sudo chown root:root /var/atlassian/
sudo chown root:root /var/atlassian/application-data/
sudo chown jira:root /var/atlassian/application-data/jira
sudo chmod 700 /var/atlassian/application-data/jira
sudo chown -R jira:jira $JIRAAPPDIR
echo "Done."

# - rename dbconfig.xml
echo -n "Renaming existing dbconfig.xml to dbconfig-$ZIPARCHIVENAME.xml..."
sudo mv $JIRAAPPDIR/dbconfig.xml $JIRAAPPDIR/dbconfig-$ZIPARCHIVENAME.xml
echo "Done."

# - start local JIRA on new server.
echo -n "Starting local JIRA..."
sudo systemctl start jira
echo "Done."

# - copy last backup in the tarball to the import directory
echo -n "Getting latest backup file ready for import..."
LATESTJIRABACKUPFILE=$(sudo ls -Art $JIRABACKUPSDIR | tail -n 1)
sudo cp $JIRABACKUPSDIR/$LATESTJIRABACKUPFILE $JIRARESTOREDIR/
echo "Done."

# - clean ups
echo -n "Cleaning up some files..."
rm -f $HOME/jira-application-$ZIPARCHIVENAME.tar.gz
rm -rf "${HOME:?}/var"
ssh -n $SSHOPTIONS $SSHUSER@$SOURCESERVER "rm -f $HOME/jira-application-$ZIPARCHIVENAME.tar.gz"
echo "Done."
echo " "
echo "NOTE: When you are restoring the backup to your new empty JIRA instance you will be asked for the name of the backup file to restore from."
echo "      The name you should enter is $LATESTJIRABACKUPFILE."
