#!/bin/sh
mysql -h moodle.mysql.database.azure.com  -u mysqladmin@moodle  -p  <<EOF
CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'moodle'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON moodle.* TO 'lms'@'%';
flush privileges;
EOF
echo "Moodle Database Created succesfully"
mount -t nfs -o rw,hard,rsize=1048576,wsize=1048576,vers=3,tcp serverip:/moodlevolume /var/www/moodledata
echo "serverip:/moodlevolume /var/www/moodledata nfs rw,hard,rsize=1048576,wsize=1048576,sec=sys,vers=3,tcp,_netdev" >> /etc/fstab
echo "NetApp Volume Mounted Succesfully"
cd /var/www/html 
/usr/bin/php admin/cli/install.php --lang=en --wwwroot=http://serverip --dataroot=/var/www/moodledata --dbtype=mysqli --dbhost=moodle.mysql.database.azure.com  --dbname=moodle --dbuser=moodle@moodle --dbpass=password --dbport=3306 --prefix=mdl_ --fullname=Moodle --shortname=LMS --adminuser=admin --adminpass=password --adminemail=amr@me.me --non-interactive --agree-license
chmod -R 755 /var/www/html/
echo "Moodle has finished installation now"
