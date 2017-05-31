#!/bin/bash
# create a PHP web server

yum install httpd php php-mysql -y
yum update -y
chkconfig httpd on
service httpd start
echo "<?php phpinfo();?>" > /var/www/html/index.php
wget https://s3-us-east-1.amazonaws.com/bostonaustin/connect.php