#!/bin/bash 
# 
## script 1
## Author: ash
echo "frontrow" | sudo -S kill `ps awwx | grep [F]inder | awk '{print $1}'`

