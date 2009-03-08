#!/bin/bash 
# 
## script 1
## Author: ash
echo "frontrow" | sudo osputil -l 3:2
sleep 2

echo "frontrow" | sudo -S reboot
