#!/bin/sh
# installer.sh handles packages, dependencies, user permissions, system configurations for the rpi measurement system.
echo "This shell script installer is used to set up a Raspberry Pi 2 Model B for a low power wireless measurement system."
echo

# ------
# Install packages
echo "System update and installing packages"
PACKAGES="php sqlite3 php-sqlite3 apache2"
apt update
apt upgrade -y
apt install $PACKAGES -y
echo

# ------
# Enable ssh (if not already activated)
echo "Enable SSH"
systemctl enable ssh
systemctl start ssh
if systemctl is-active --quiet ssh; then
    echo "SSH has been enabled successfully or has already been enabled."
else
    echo "SSH not enabled. Please check the configuration manually by typing 'sudo raspi-config'."
fi
echo

# ------
# Parse current user into variable 
USER=$SUDO_USER
echo

# ------
# Move files to correct directories
PYTHON_SOURCE_DIR="./Code/Python"
PYTHON_DESTINATION_DIR="/home/$USER/code"
HTML_SOURCE_DIR="./Code/html"
HTML_DESTINATION_DIR="/var/www/html"
echo "Creating directories."
mkdir -p "$PYTHON_DESTINATION_DIR"
mkdir -p "$HTML_DESTINATION_DIR"
echo "Moving files..."
mv "$PYTHON_SOURCE_DIR"/* "$PYTHON_DESTINATION_DIR/"
mv "$HTML_SOURCE_DIR"/* "$HTML_DESTINATION_DIR/"
if [ "$(ls -A "$PYTHON_DESTINATION_DIR")" ]; then
    echo "Python files moved succesfully."
else
    echo "Error while moving files. Check destination directory: ${PYTHON_DESTINATION_DIR}."
fi
if [ "$(ls -A $HTML_DESTINATION_DIR)" ]; then
    echo "HTML files moved succesfully."
else
    echo "Error while moving files. Check destination directory: ${HTML_DESTINATION_DIR}."
fi
echo

# ------
# Set visudo permissions
echo "Set visudo permissions."
CUSTOM_CMDS_LINE="Cmnd_Alias CUSTOM_CMDS = /usr/bin/pkill, /usr/sbin/shutdown -h now, /usr/sbin/shutdown -r now"
WWW_DATA_LINE="www-data ALL = NOPASSWD: CUSTOM_CMDS"
if ! grep -Fxq "$CUSTOM_CMDS_LINE" /etc/sudoers && ! grep -Fxq "$WWW_DATA_LINE" /etc/sudoers; then
    echo "$CUSTOM_CMDS_LINE" | tee -a /etc/sudoers > /dev/null 2>&1
    echo "$WWW_DATA_LINE" | tee -a /etc/sudoers > /dev/null 2>&1
    echo "visudo lines appended to /etc/sudoers successfully."
else
    echo "visudo lines already exist in /etc/sudoers."
fi
echo

# ------
# Apache2 web server
HTACCESS_FILE="/var/www/html/.htaccess"
HTPASSWD_FILE="/home/$USER/.htpasswd"
# Create the .htpasswd file with user password
echo "Choose Apache2 website password."
htpasswd -cB "$HTPASSWD_FILE" "$USER"
# Rewrite .htaccess file
echo "AuthUserFile $HTPASSWD_FILE" >> "$HTACCESS_FILE"
echo "AuthType Basic" >> "$HTACCESS_FILE"
echo 'AuthName "My restricted Area"' >> "$HTACCESS_FILE"
echo "Require valid-user" >> "$HTACCESS_FILE"
echo "ErrorDocument 404 /404.html" >> "$HTACCESS_FILE"
# Enable php in html
echo "AddHandler application/x-httpd-php .html" >> "$HTACCESS_FILE"
echo

# Adjust '/etc/apache2/apache2.conf' file and restart web server
echo "Adjust '/etc/apache2/apache2.conf' file and restart web server."
sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' "/etc/apache2/apache2.conf"
a2enmod rewrite
service apache2 restart
echo

# Check if apache2 web server is running
if service apache2 status | grep -q "active (running)"; then
    echo "Apache2 web server set up successfully."
    echo "Local IP address: $(hostname -I)"
else
    echo "Apache2 is not running."
fi
echo

# ------
# Set USB permissions
usermod -aG dialout www-data

# ------
# Initialize DB and chmod and group of IoT.db
echo "Create sqlite3 db and set various file and owner permissions."
usermod -aG pidb www-data
mkdir -p /home/$USER/code/logs
cd /home/$USER/code
python3 /home/$USER/code/initialize_DB_Tables.py
cd - > /dev/null 2>&1
chown pidb:pidb /home/$USER/code/ /home/$USER/code/* 
chmod -R 774 /home/$USER/code/
echo

# ------
# Reboot
echo "Initiate reboot - establish a new ssh connection with the rpi to access the device."
reboot
