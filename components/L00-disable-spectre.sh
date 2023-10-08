#!/bin/bash
SCRN=$(basename "$0")
echo "$SCRN: disabling Spectre/Meltdown mitigations for performance"

TARGET=/etc/default/grub
CMDLINE=$(cat $TARGET | grep "GRUB_CMDLINE_LINUX_DEFAULT" | awk '{print substr($0, 28)}')

if [[ ! ${CMDLINE} == *"mitigations=off"* ]] ;
then
	sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 mitigations=off"/' ${TARGET}
	echo "$SCRN: added the necessary bootarg"
	sudo update-grub
else
	echo "$SCRN: already patched, skipping..."
fi
 
exit
