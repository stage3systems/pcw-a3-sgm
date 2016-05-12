#! /bin/sh

cd /home/ubuntu/pce
cp ../config/*.yml config/
sudo chown -R ubuntu:ubuntu /home/ubuntu
sudo service pce start
