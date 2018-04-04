#!/bin/bash

# A quick script which will gather the necessary data from a source JIRA
# server and copy it to a new JIRA server.
#
# Requirements
# - must be run as a user. NOT ROOT.
# - you will need ssh keyed access to the destination JIRA server.
# - you will need sufficient privileges locally to access the source data.
# - you will need to put this script on the source JIRA server.

# pseudo code
# - stop JIRA
# - tar up app dir (also includes the xml backups)
# - prompt to start local JIRA server or not
# - copy tar to destination server
# - clean up local tarball

# global VARs
export JIRAAPPDIR="/var/atlassian/application-data/jira"
export JIRADESTUSER="ubuntu"
export JIRADESTSERVER="diatapp00.westus2.cloudapp.azure.com"
export JIRASTART=""
export ZIPARCHIVENAME=`date "+%Y%m%d-%H%M%S"`

# code
#
# be in your home dir
cd ~ || exit

# stop JIRA
if [[ -x /opt/atlassian/jira/bin/stop-jira.sh ]] ;then
  sudo /opt/atlassian/jira/bin/stop-jira.sh
  # are we going to start JIRA after weve grabbed our tar ball?
  echo "Do you wish to start JIRA again after weve prep'd our tarball?"
  select yn in "Yes" "No"; do
    case $yn in
      Yes ) JIRASTART=1 ; echo "JIRA will be started"; break ;;
      No ) JIRASTART=0 ; echo "JIRA WONT be started. You will need to start it manually."; exit ;;
    esac
  done
  # zip up app dir
  sudo tar -cvzf ./jira-application-$ZIPARCHIVENAME.tar.gz $JIRAAPPDIR
  # we have our tar ball now, lets start JIRA if we said we want to.
  if [[ $JIRASTART ]] ; then
    echo "restarting JIRA."
    sudo /opt/atlassian/jira/bin/start-jira.sh
  else
    echo "JIRA not running."
  fi
  # copy the home dir to the destination server.
  scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ./jira-application-$ZIPARCHIVENAME.tar.gz $JIRADESTUSER@$JIRADESTSERVER:~/
  rm -f ./jira-application-$ZIPARCHIVENAME.tar.gz
else
  echo "/opt/atlassian/jira/bin/stop-jira.sh not found."
  exit 1
fi
