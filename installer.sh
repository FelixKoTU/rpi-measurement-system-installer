#!/bin/sh
# installer.sh installs the necessary packages and dependencies for the measurement system

# Install packages
#PACKAGES="php sqlite3 php-sqlite3"
apt-get update
apt-get upgrade -y
#apt-get install $PACKAGES -y

# Enable ssh

# Move files to correct directories
USER="pidb"

python_source_dir="/home/$USER/Documents/rpi-installer/Code" 
python_destination_dir="/home/$USER/code"

html_source_dir="/home/$USER/Documents/rpi-installer/html"
html_destination_dir="/var/www/html"

echo "Moving files."
mv "$python_source_dir"/* "$python_destination_dir/"

# check if Apache2 user has been set up correctly
# check if html_dest_dir exists

mv "$html_source_dir"/* "$html_destination_dir/"
echo "Files moved succesfully"

# Set visudo option

# Enable php
