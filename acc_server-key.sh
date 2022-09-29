#!/bin/bash
aws s3 cp s3://lau-aws-m1-secret/server-key.pem /home/ec2-user
chmod 0600 server-key.pem
