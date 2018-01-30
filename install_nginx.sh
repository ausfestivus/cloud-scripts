#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx

echo $(hostname) | sudo tee /var/www/html/index.html
sudo mkdir -p /var/www/html/images
echo "Images: " $(hostname) | sudo tee /var/www/html/images/test.html
sudo mkdir -p /var/www/html/video
echo "Video: " $(hostname) | sudo tee /var/www/html/video/test.html

# ht to https://raw.githubusercontent.com/davidmu1/samplescripts/master/install_nginx.sh
