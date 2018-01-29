#!/bin/bash

# NOTE - This script is for use to build a basic Ubuntu cloud host.

# ideally there is a single command here that will add the machine to config management.
# thats a future state problem.

# Update the package indexes
/usr/bin/sudo apt-get update -y

#
export DEBIAN_FRONTEND=noninteractive

# Install all the packages
/usr/bin/sudo /usr/bin/apt-get -y -o DPkg::Options::="--force-confnew" install pwgen htop sysstat dstat iotop vim molly-guard unattended-upgrades screen git

# update all the things
/usr/bin/sudo /usr/bin/apt-get -y -o Dpkg::Options::="--force-confnew" dist-upgrade

# now we clean up left over packages
/usr/bin/sudo /usr/bin/apt-get -y auto-remove

# and then restart
/bin/echo "restarting"
/usr/bin/sudo init 6
