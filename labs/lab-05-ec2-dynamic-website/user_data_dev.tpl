#!/bin/bash
yum update -y
yum install -y httpd mariadb-server php

systemctl start httpd
systemctl enable httpd
systemctl start mariadb
systemctl enable mariadb

DB_ROOT_PASSWORD=${db_root_password}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
DB_NAME=${db_name}

mysql -u root <<EOF
UPDATE mysql.user SET Password=PASSWORD('$DB_ROOT_PASSWORD') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
FLUSH PRIVILEGES;
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

cd /tmp
wget ${cafe_zip_url}
unzip cafe.zip -d /var/www/html/
wget ${db_zip_url}
unzip db.zip
mysql -u $DB_USER -p$DB_PASSWORD $DB_NAME < db/db-script.sql

cd /var/www/html/cafe/
wget https://docs.aws.amazon.com/aws-sdk-php/v3/download/aws.zip
unzip aws.zip
chmod -R 755 /var/www/html/cafe

sed -i 's/;date.timezone =/date.timezone = "America\/New_York"/' /etc/php.ini

systemctl restart httpd