#!/bin/bash

# Exit on non-zero ret
set -e

echo $(dirname "$0")
COMPONENTS_DIR=$(dirname "$0")/components

# Check the number of command-line arguments
if [ $# -ne 1 ] ;
then
	echo "Error: 0 or Hostname required."
	exit 1
fi

DOMAIN_NAME=$1

bash ${COMPONENTS_DIR}/L00-disable-spectre.sh
bash ${COMPONENTS_DIR}/L01-remove-bloats.sh
bash ${COMPONENTS_DIR}/L02-network-conf.sh ${DOMAIN_NAME}
bash ${COMPONENTS_DIR}/L03-update-software.sh
bash ${COMPONENTS_DIR}/H00-download-hadoop.sh
bash ${COMPONENTS_DIR}/H01-setup-cluster.sh

exit
