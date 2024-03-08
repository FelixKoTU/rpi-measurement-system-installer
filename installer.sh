#!/bin/sh
# installer.sh installs the necessary packages and dependencies for the measurement system
# ------
# Install packages
PACKAGES="php sqlite3 php-sqlite3 apache2"
apt-get update
apt-get upgrade -y
#apt-get install $PACKAGES -y
# ------
# Enable ssh
systemctl enable ssh
systemctl start ssh
if sudo systemctl is-active --quiet ssh; then
    echo "SSH has been enabled successfully."
else
    echo "SSH not enabled. Please check the configuration manually by typing 'sudo raspi-config'."
fi
# ------
# Move files to correct directories
USER="pidb"

PYTHON_SOURCE_DIR="/home/$USER/Documents/rpi-installer/Code" 
PYTHON_DESTINATION_DIR="/home/$USER/code"

HTML_SOURCE_DIR="/home/$USER/Documents/rpi-installer/html"
HTML_DESTINATION_DIR="/var/www/html"
 
echo "Moving files."
mv "$PYTHON_SOURCE_DIR"/* "$PYTHON_DESTINATION_DIR/"

mv "$HTML_SOURCE_DIR"/* "$HTML_DESTINATION_DIR/"
echo "Files moved succesfully"
# ------
# Set visudo option (root)
CUSTOM_CMDS_LINE="Cmnd_Alias CUSTOM_CMDS = /usr/bin/pkill, /usr/sbin/shutdown -h now, /usr/sbin/shutdown -r now"
WWW_DATA_LINE="www-data ALL = NOPASSWD: CUSTOM_CMDS"
# Check if the lines already exist in the sudoers file
if ! grep -Fxq "$CUSTOM_CMDS_LINE" /etc/sudoers && ! grep -Fxq "$WWW_DATA_LINE" /etc/sudoers; then
    echo "$CUSTOM_CMDS_LINE" | sudo tee -a /etc/sudoers
    echo "$WWW_DATA_LINE" | sudo tee -a /etc/sudoers
    echo "visudo lines appended to /etc/sudoers."
else
    echo "visudo lines already exist in /etc/sudoers."
fi
# ------
# Enable php
# check if Apache2 user has been set up correctly
# set .htpasswd password and adjust '/etc/apache2/apache2.conf' file
HTACCESS_FILE="/var/www/html/.htaccess"
USER_HOME="/home/$USER/Documents"
HTAPASSWD_FILE="$USER_HOME/.htpasswd"

echo "AuthUserFile $HTAPASSWD_FILE" > "$HTACCESS_FILE"
echo "AuthType Basic" > "$HTACCESS_FILE"
echo 'AuthName "My restricted Area"' > "$HTACCESS_FILE"
echo "Require valid-user" > "$HTACCESS_FILE"
echo "ErrorDocument 404 /404.html" > "$HTACCESS_FILE"
echo "AddHandler application/x-httpd-php.html" > "$HTACCESS_FILE"
