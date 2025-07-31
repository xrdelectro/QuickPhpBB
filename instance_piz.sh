#!/bin/bash

# Fail if any command fails
set -e

# Welcome message
echo "Welcome to the PHPBB Installer for Raspberry Pi Zero!"

# Prompt for MySQL root password
read -sp 'Enter MySQL root password (you will need this later): ' mysql_root_password
echo

# Prompt for PHPBB database name, username, and password
read -p 'Enter the name of the database for PHPBB (e.g., phpbb): ' phpbb_database
read -p 'Enter the MySQL username for PHPBB (e.g., phpbbuser): ' phpbb_user
read -sp 'Enter the MySQL user password for PHPBB: ' phpbb_password
echo

# Prompt for PHPBB admin email
read -p 'Enter your admin email (for PHPBB configuration): ' admin_email

# Update and upgrade system packages
echo "Updating and upgrading system packages..."
sudo apt update && sudo apt upgrade -y

# Install necessary packages
echo "Installing necessary packages: Apache2, PHP, MariaDB, and required PHP extensions..."
sudo apt install apache2 php php-mbstring php-xml php-bcmath php-json php-curl php-gd php-mysql mariadb-server wget unzip -y

# Download PHPBB
echo "Downloading PHPBB latest release..."
FN=phpBB-3.3.15.tar.bz2
wget https://download.phpbb.com/pub/release/3.3/3.3.15/$FN

# Unzip and move to /var/www/html
echo "Extracting PHPBB..."
tar -xf $FN -C /var/www/html/phpbb
#sudo mv phpBB3 /var/www/html/phpbb

# Set permissions for the web server
echo "Setting permissions..."
sudo chown -R www-data:www-data /var/www/html/phpbb
sudo chmod -R 755 /var/www/html/phpbb

# Configure MariaDB
echo "Configuring MariaDB..."
sudo systemctl start mariadb
sudo mysql_secure_installation <<EOF

y
$mysql_root_password
$mysql_root_password
y
y
y
y
EOF

# Create MariaDB database and user
echo "Creating PHPBB database and user..."
sudo mysql -u root -p"$mysql_root_password" <<MYSQL_SCRIPT
CREATE DATABASE $phpbb_database CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER '$phpbb_user'@'localhost' IDENTIFIED BY '$phpbb_password';
GRANT ALL PRIVILEGES ON $phpbb_database.* TO '$phpbb_user'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Configure Apache for PHPBB
echo "Configuring Apache2..."
sudo bash -c "cat > /etc/apache2/sites-available/phpbb.conf <<EOF
<VirtualHost *:80>
    ServerAdmin $admin_email
    DocumentRoot /var/www/html/phpbb/
    DirectoryIndex index.php

    <Directory /var/www/html/phpbb/>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/phpbb_error.log
    CustomLog \${APACHE_LOG_DIR}/phpbb_access.log combined
</VirtualHost>
EOF"

# Enable PHPBB site and Apache rewrite module
echo "Enabling PHPBB site and Apache rewrite module..."
sudo a2ensite phpbb.conf
sudo a2enmod rewrite

# Restart Apache
echo "Restarting Apache server..."
sudo systemctl restart apache2

# Final instructions
echo "PHPBB installed successfully!"
echo "Access PHPBB at http://<your-pi-ip-address>/phpbb to complete the installation."
echo "During installation, use the following details for database setup:"
echo "  Database name: $phpbb_database"
echo "  Database user: $phpbb_user"
echo "  Database password: $phpbb_password"
