#!/bin/bash

# A quick script which will gather the necessary data from a source CONFLUENCE
# server and copy it to a new CONFLUENCE server.
#
# Requirements
# - must be run as a user. NOT ROOT.
# - you will need ssh keyed access to the destination CONFLUENCE server.
# - you will need sufficient privileges locally to access the source data.
# - you will need to put this script on the source CONFLUENCE server.

# pseudo code


# global VARs
export CONFLUENCEAPPDIR="/var/atlassian/application-data/confluence"
export CONFLUENCEBACKUPSDIR="$CONFLUENCEAPPDIR/backups"
export CONFLUENCERESTOREDIR="$CONFLUENCEAPPDIR/restore"
export CONFLUENCEDESTUSER="ubuntu"
export CONFLUENCEDESTSERVER="diatapp01.westus2.cloudapp.azure.com"
export CONFLUENCESTART=""
#export ZIPARCHIVENAME=`date "+%Y%m%d-%H%M%S"`
export SSHOPTIONS="-i ~$CONFLUENCEDESTUSER/.ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# code
#
# be in your home dir
cd ~ || exit

################################################################################
# new code.
# scp latest backup file to destination.
# ssh to destination host and move backup file to correct location.
################################################################################
# put our latest backup file name into a VAR
#LATESTCONFLUENCEBACKUPFILE=$(sudo find $CONFLUENCEBACKUPSDIR/ -type f -printf '%p\n' | sort | head -n 1)
LATESTCONFLUENCEBACKUPFILE=$(sudo find $CONFLUENCEBACKUPSDIR/ -ctime 1 -type f)
LATESTCONFLUENCEBACKUPFILENAME=$(basename -- "$LATESTCONFLUENCEBACKUPFILE")

# scp latest backup file to destination.
sudo scp $SSHOPTIONS $LATESTCONFLUENCEBACKUPFILE $CONFLUENCEDESTUSER@$CONFLUENCEDESTSERVER:~/

# check that are restore dir exists on the new target server
ssh $SSHOPTIONS $CONFLUENCEDESTUSER@$CONFLUENCEDESTSERVER sudo mkdir -p $CONFLUENCERESTOREDIR && sudo chown confluence:confluence $CONFLUENCERESTOREDIR

# ssh to destination host and move backup file to correct location.
ssh $SSHOPTIONS $CONFLUENCEDESTUSER@$CONFLUENCEDESTSERVER sudo cp ./$LATESTCONFLUENCEBACKUPFILENAME $CONFLUENCERESTOREDIR
#sudo cp `sudo find ./var/atlassian/application-data/confluence/backups/ -type f -printf '%p\n' | sort | head -n 1` $CONFLUENCERESTOREDIR
#scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ./confluence-application-$ZIPARCHIVENAME.tar.gz $CONFLUENCEDESTUSER@$CONFLUENCEDESTSERVER:~/

################################################################################
# original code.
# - stop CONFLUENCE
# - tar up app dir (also includes the xml backups)
# - prompt to start local CONFLUENCE server or not
# - copy tar to destination server
# - clean up local tarball
################################################################################
# # stop CONFLUENCE
# if [[ -x /opt/atlassian/confluence/bin/stop-confluence.sh ]] ;then
#   sudo /opt/atlassian/confluence/bin/stop-confluence.sh
#   # are we going to start CONFLUENCE after weve grabbed our tar ball?
#   echo "Do you wish to start CONFLUENCE again after weve prep'd our tarball?"
#   select yn in "Yes" "No"; do
#     case $yn in
#       Yes ) CONFLUENCESTART=1 ; echo "CONFLUENCE will be started"; break ;;
#       No ) CONFLUENCESTART=0 ; echo "CONFLUENCE WONT be started. You will need to start it manually."; exit ;;
#     esac
#   done
#   # zip up app dir
#   sudo tar -cvzf ./confluence-application-$ZIPARCHIVENAME.tar.gz $CONFLUENCEAPPDIR
#   # we have our tar ball now, lets start CONFLUENCE if we said we want to.
#   if [[ $CONFLUENCESTART ]] ; then
#     echo "restarting CONFLUENCE."
#     sudo /opt/atlassian/confluence/bin/start-confluence.sh
#   else
#     echo "CONFLUENCE not running."
#   fi
#   # copy the home dir to the destination server.
#   echo "Copying tarball to $CONFLUENCEDESTSERVER"
#   scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ./confluence-application-$ZIPARCHIVENAME.tar.gz $CONFLUENCEDESTUSER@$CONFLUENCEDESTSERVER:~/
#   rm -f ./confluence-application-$ZIPARCHIVENAME.tar.gz
# else
#   echo "/opt/atlassian/confluence/bin/stop-confluence.sh not found."
#   exit 1
# fi
