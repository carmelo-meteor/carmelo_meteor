#!/usr/bin/env bash

cd /home/pi/carmelo_meteor
git pull origin main
cp *.py ../
sudo reboot