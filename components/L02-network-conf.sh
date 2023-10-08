#!/bin/bash
# NOTE: DEBIAN/UBUNTU-base OSes only (Debian 11/Ubuntu 22.04 rcm-ed)
# ARGS:
#	domain: name of domain to conf this VM
#
SCRN=$(basename "$0")

#### PREM-CHECKS ####
function helper() {
	echo "Usage: ./$SCRN <name of the node, such as namenode, datanode1>"
	echo "E.g: ./$SCRN datanode1"
	echo
	echo "NOTE: to disable domain name change, input 0 as argument instead."
	echo "NOTE: to run namenode-only portions, input 1 as argument instead."
	echo
}

# Check the number of command-line arguments
if [ $# -ne 1 ]; then
	echo "Error: Exactly one argument is required."
	helper
	exit 1
fi

if [[ "$1" == *" "* ]];
then
	echo "Error: Argument '$1' contains spaces. Spaces are not allowed."
	exit 1
fi

INPUT_ARG=$1
echo $INPUT_ARG

#### START SCRIPT ####
echo "$SCRN: configuring network/routing"

# Delete 127.0.1.1 entry of namenode, because Hadoop would set itself up on 127.0.1.1:9000 otherwise
# rendering the whole thing useless
# Ubuntu/Debian quirks btw
echo "$SCRN: hosts: removing 127.0.1.1 entry"
sudo sed -i '/^127\.0\.1\.1/d' /etc/hosts

## Change domain
CUR_DOMAIN=$(cat /etc/hostname)

if [[ "${INPUT_ARG}" != "0" && "${INPUT_ARG}" != "1" ]] ;
then
	echo "$SCRN: hostname: changing hostname to ${INPUT_ARG}"
	# sudo sed -i "s/^\(127.0.1.1\s*\).*$/\1$new_hostname/" /etc/hosts
	hostnamectl set-hostname ${INPUT_ARG}
	echo "$SCRN: hostname: done"
fi

## Add nodes to hosts for pinging each other
echo "$SCRN: hosts: adding additional hosts to /etc/hosts"
[[ ! $(grep 10.0.0.2 /etc/hosts) ]] && echo "
10.0.0.2	namenode
10.0.0.10	datanode1
10.0.0.11	datanode2
" | sudo tee -a /etc/hosts >/dev/null

## Generate SSH keys, on NAMENODE only
if [[ $INPUT_ARG -eq 1 ]] ;
then
	echo "$SCRN: SSH: generating SSH keys, please read keygen instructions"
	ssh-keygen -t rsa -P ""
	
	echo "$SCRN: SSH: copying SSH public key to authorized space"
	cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys

	echo "$SCRN: SSH: copying SSG public key to other (data)nodes"
	ssh-copy-id -i $HOME/.ssh/id_rsa.pub hduser@datanode1
	ssh-copy-id -i $HOME/.ssh/id_rsa.pub hduser@datanode2
fi

exit
