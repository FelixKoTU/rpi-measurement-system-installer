#!/bin/sh
# installer.sh handles packages, dependencies, user permissions, system configurations for the rpi measurement system.
# ------
# Install packages
echo "System update and installing packages:"
PACKAGES="php sqlite3 php-sqlite3 apache2"
apt-get update
apt-get upgrade -y
apt-get install $PACKAGES -y

# ------
# Enable ssh
echo "Enable ssh:"
systemctl enable ssh
systemctl start ssh
if sudo systemctl is-active --quiet ssh; then
    echo "SSH has been enabled successfully."
else
    echo "SSH not enabled. Please check the configuration manually by typing 'sudo raspi-config'."
fi
echo "\n"

# ------
# Parse current user into variable 
USER=$(who am i | awk '{print $1}')
echo "\n"

## Alternatively query user input 
# prompt_input() {
#     read -p "Please enter your username (non root user): " USER
#     echo "You entered: $USER"
#     read -p "Is the username you entered correct? [Y/n] " CONFIRM
# }

# prompt_input

# while [ "$CONFIRM" != "Y" ] && [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "" ]; do
#     echo "Invalid input. Please try again."
#     prompt_input
# done

# echo "Username entered successfully!"
# echo "\n"

# ------
# Move files to correct directories
echo "Move files to correct directories:"

PYTHON_SOURCE_DIR="./Code/Python" 
PYTHON_DESTINATION_DIR="/home/$USER/code"

HTML_SOURCE_DIR="./Code/html"
HTML_DESTINATION_DIR="/var/www/html"

echo "Creating directories:"
mkdir -p "$PYTHON_DESTINATION_DIR"
mkdir -p "$HTML_DESTINATION_DIR"

echo "Moving files."
mv "$PYTHON_SOURCE_DIR"/* "$PYTHON_DESTINATION_DIR/"
mv "$HTML_SOURCE_DIR"/* "$HTML_DESTINATION_DIR/"
if [ "$(ls -A "$PYTHON_DESTINATION_DIR")" ]; then
    echo "Python files moved succesfully"
else
    echo "Error while moving files. Check destination directory: ${PYTHON_DESTINATION_DIR}."
fi
if [ "$(ls -A $HTML_DESTINATION_DIR)" ]; then
    echo "HTML files moved succesfully"
else
    echo "Error while moving files. Check destination directory: ${HTML_DESTINATION_DIR}."
fi
echo "\n"

# ------
# Set visudo permissions
echo "Set visudo permissions"
CUSTOM_CMDS_LINE="Cmnd_Alias CUSTOM_CMDS = /usr/bin/pkill, /usr/sbin/shutdown -h now, /usr/sbin/shutdown -r now"
WWW_DATA_LINE="www-data ALL = NOPASSWD: CUSTOM_CMDS"
# Check if the lines already exist in the sudoers file
if ! grep -Fxq "$CUSTOM_CMDS_LINE" /etc/sudoers && ! grep -Fxq "$WWW_DATA_LINE" /etc/sudoers; then
    echo "$CUSTOM_CMDS_LINE" | sudo tee -a /etc/sudoers > /dev/null 2>&1
    echo "$WWW_DATA_LINE" | sudo tee -a /etc/sudoers > /dev/null 2>&1
    echo "visudo lines appended to /etc/sudoers."
else
    echo "visudo lines already exist in /etc/sudoers."
fi
echo "\n"

# ------
# Apache2 webserver
# check if Apache2 user has been set up correctly and cofigure all necessary files
HTACCESS_FILE="/var/www/html/.htaccess"
HTPASSWD_FILE="/home/$USER/.htpasswd"

# create the .htpasswd file with user password
htpasswd -cB "$HTPASSWD_FILE" "$USER"

# rewrite .htaccess file
echo "AuthUserFile $HTPASSWD_FILE" >> "$HTACCESS_FILE"
echo "AuthType Basic" >> "$HTACCESS_FILE"
echo 'AuthName "My restricted Area"' >> "$HTACCESS_FILE"
echo "Require valid-user" >> "$HTACCESS_FILE"
echo "ErrorDocument 404 /404.html" >> "$HTACCESS_FILE"
# enable php in html
echo "AddHandler application/x-httpd-php .html" >> "$HTACCESS_FILE"
echo "\n"

# adjust '/etc/apache2/apache2.conf' file and restart web server
echo "Adjust '/etc/apache2/apache2.conf' file and restart web server."
sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' "/etc/apache2/apache2.conf"
a2enmod rewrite
service apache2 restart
echo "\n"

# check if apache2 web server is running
servstat=$(service apache2 status)
if echo "$servstat" | grep -q "active (running)"; then
    echo "Apache2 web server set up succesfully. Paste the local IP address into the web browser of the RPi."
    echo "Local IP adress: $(hostname -I)"
else
    echo "Apache2 is not running."
fi
echo "\n"

# ------
# Set USB permissions
usermod -a -G dialout www-data

# ------
# Initialize DB and chmod and group of IoT.db
echo "Create sqlite3 db in '/home/$USER/code/' and set various file and owner permissions."
usermod -aG pidb www-data
mkdir /home/$USER/code/logs
cd /home/$USER/code
python3 /home/$USER/code/initialize_DB_Tables.py
cd -
chown pidb:pidb /home/$USER/code/
chown pidb:pidb /home/$USER/code/*
chmod 774 /home/$USER/code/
chmod 774 /home/$USER/code/*
echo "\n"

# ------
# Reboot
reboot
