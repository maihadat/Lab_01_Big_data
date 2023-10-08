#!/bin/bash

SCRN=$(basename "$0")
echo "$SCRN: removing bloats"

sudo apt purge -y libreoffice-*
sudo apt autoremove -y

echo "$SCRN: done removing bloats"

exit
