#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install nginx1 -y
sudo service nginx start
echo "echo this is nginx server" > /usr/share/nginx/html/nginx.html
chown nginx:nginx /usr/share/nginx/html/nginx.html