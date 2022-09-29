#!/bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo service httpd start
echo "this is apache server" > /var/www/html/apache