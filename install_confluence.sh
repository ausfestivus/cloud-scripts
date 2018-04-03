#!/bin/bash

# install Confluence

# variables
# Currently all static here, will be overidable by CLI in the future.
echo "Reading global variables...." >&2

# local variables
export RESPONSEFILE="response.varfile"
export ATLASSIANROOT=/opt
#export ATLASSIANVAR=$ATLASSIANROOT/var/atlassian

# preflights
# check that /opt is mounted/exists.
if [ ! -e $ATLASSIANROOT ] # if /opt doesnt exist
then
  echo "$ATLASSIANROOT was not found. Dying."; exit
else
  echo "$ATLASSIANROOT was found. Continuing."
fi

# check that /opt/var/atlassian exists.
# if [ ! -e $ATLASSIANVAR ] # if /opt/var/atlassian doesnt exist
# then
#   echo "$ATLASSIANVAR was not found. Creating it."
#   sudo mkdir -p $ATLASSIANVAR || exit # create our symlink in /var/atlassian to /opt/var/atlassian
#   # ln [OPTION]... [-T] TARGET LINK_NAME
#   sudo ln -s /opt/var/atlassian /var/atlassian || exit
# else
#   echo "$ATLASSIANVAR already exists. Continuing."
# fi

# check that our DB server is available
# TODO

# be in the users homedir
cd ~ || exit

# download the binary
#wget -q https://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-6.7.0-x64.bin
# 20180403 updated to 6.8.0
wget -q https://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-6.8.0-x64.bin

# fix its perms
sudo chmod 755 ./atlassian-confluence-6.8.0-x64.bin

# create our varfile contents for the install
cat > ~/$RESPONSEFILE <<EOL
executeLauncherAction$Boolean=true
app.install.service$Boolean=true
sys.confirmedUpdateInstallationString=false
existingInstallationDir=/opt/Confluence
sys.languageId=en
sys.installationDir=/opt/atlassian/confluence
EOL

# run it as root with the answer file
sudo ./atlassian-confluence-6.7.0-x64.bin -q -varfile response.varfile

# drop our DB config into place
# CLI to retrieve the connection string for a DB?
