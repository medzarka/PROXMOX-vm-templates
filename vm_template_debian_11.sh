#!/bin/bash

echo "-----------------------------------------------------------------"
echo "Create a Debian Linux 11 template VM"
echo "-----------------------------------------------------------------"

# [x] Load common configs from the common scripts
echo "Load common configs from the common scripts"
source lib/common_vm_scripts.sh

# [x] Specific VM template configurations
# Specific configs
TEMPLATE_VM_ID=5211
TEMPLATE_TYPE=template
TEMPLATE_OS=debian
TEMPLATE_VERSION=11
RAM=1024
CORES=1
IP=192.168.50.20/24
# RECHECK check the size
SYSTEM_DISK_SIZE=3G


IMAGE_URL=https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.raw
IMAGE_NAME=debian-11-generic-amd64.raw
IMAGE_PATH=/var/lib/vz/template/cache/$IMAGE_NAME

# [x] Load common VM template configurations

create_retrive_common_variable_from_pass "default_domain"
MAIN_DOMAIN=$RETURN_VALUE

create_retrive_common_variable_from_pass "default_user"
DEFAULT_USER=$RETURN_VALUE

create_retrive_common_variable_from_pass "default_password_length"
DEFAULT_PASSWORD_LENGTH=$RETURN_VALUE

create_retrive_specific_template_user_password_from_pass $TEMPLATE_VM_ID $DEFAULT_PASSWORD_LENGTH
USER_PASSWORD=$RETURN_VALUE

TEMPLATE_NAME=${TEMPLATE_TYPE}-${TEMPLATE_OS}-${TEMPLATE_VERSION} 
TAGS=_template,os_${TEMPLATE_OS},v_${TEMPLATE_VERSION} 

#############################################################
### Download the VM disk image
download_vm_disk_image $IMAGE_URL $IMAGE_PATH $DISKIMAGE_SIZE

#############################################################
### Destroy the old VM if it exists
destroy_old_vm $TEMPLATE_VM_ID

#############################################################
### Create new Template
create_new_template

#############################################################
### Start the VM template, wait it to start, and then execute the setup script 
template_os_setup

#############################################################
### Convert the VM to a template
convert_vm_to_template

#############################################################
echo "----------------------------------------------------------------------------------------"
echo "Done for Debian 11 VM template ..."
echo "----------------------------------------------------------------------------------------"