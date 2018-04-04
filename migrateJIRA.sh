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
# - zip up app dir
# - copy zip to destination server
# - copy n xml backups to destination server
# - prompt to start JIRA server or not

# global VARs
export JIRAAPPDIR="/var/atlassian/application-data/jira"
export SOURCEJIRAPATH="/var/atlassian/application-data/jira/export"
export JIRADESTUSER="ubuntu"
export JIRADESTSERVER="diatapp00.uswest2.cloudapp.azure.com"
export XMLDAYSTOCOPY=3
export ZIPARCHIVENAME=`date "+%Y%m%d-%H%M%S"`

# code
#
# be in your home dir
cd ~ || exit

# stop JIRA
if [[ -x /opt/atlassian/jira/bin/stop-jira.sh ]] ;then
  sudo /opt/atlassian/jira/bin/stop-jira.sh
  # zip up app dir
  sudo tar -cvzf ./jira-application-$ZIPARCHIVENAME.tar.gz $JIRAAPPDIR
  # copy the home dir to the destination server.
  scp ./jira-application-$ZIPARCHIVENAME.tar.gz $JIRADESTUSER@$JIRADESTSERVER:~/
  # copy the latest n days of xml backups to the destination server.
  sudo find $SOURCEJIRAPATH -type f -ctime -$XMLDAYSTOCOPY -exec "scp {} $JIRADESTUSER@$JIRADESTSERVER:/home/$DESTUSERNAME/ \;"
  echo rm ./jira-application-$ZIPARCHIVENAME.tar.gz
else
  echo "/opt/atlassian/jira/bin/stop-jira.sh not found."
  exit 1
fi
