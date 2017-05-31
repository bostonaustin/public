#!/bin/bash
# run installation commands to configure as a WordPress webserver

#!# OR replace all these lines below with this single line to pull from file(s) in S3
#aws s3 sync --delete s3://bostonaustin-nginx/ /var/www/html/

yum update -y
yum install httpd php php-mysql stress nmap -y
cd /etc/httpd/conf
cp httpd.conf httpd_conf.backup
rm -rf httpd.conf
wget https://s3.amazonaws.com/bostonaustin-wp/httpd.conf
cd /var/www/html
wget https://s3.amazonaws.com/bostonaustin-wp/healthcheck.html
cp healthcheck.html /var/www/html/healthcheck.html
wget https://s3.amazonaws.com/bostonaustin-wp/htaccess
cp htaccess .htaccess
wget https://s3.amazonaws.com/bostonaustin-wp/crontab
mkdir /etc/cron.d/wordpress/
cp crontab /etc/cron.d/wordpress
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* /var/www/html/
rm -rf wordpress
rm -rf latest.tar.gz
chmod -R 755 wp-content
chown -R apache.apache wp-content
service httpd start
chkconfig httpd on
