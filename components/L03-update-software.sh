#!/bin/bash

SCRN=$(basename "$0")
echo "$SCRN: updating system software"
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
