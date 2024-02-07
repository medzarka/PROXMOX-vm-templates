#!/bin/bash

echo "-----------------------------------------------------------------"
echo "Create a Ubuntu Linux 22.04 template VM"
echo "-----------------------------------------------------------------"

# [x] Load common configs from the common scripts
echo "Load common configs from the common scripts"
source ../lib/common_vm_scripts.sh

# [x] Specific VM template configurations
# Specific configs
TEMPLATE_VM_ID=5122
TEMPLATE_TYPE=template
TEMPLATE_OS=ubuntu
TEMPLATE_VERSION=22.04
RAM=1024
CORES=1
IP=192.168.50.11/24
# RECHECK check the size
DISKIMAGE_SIZE=4 

IMAGE_URL=https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
IMAGE_NAME=jammy-server-cloudimg-amd64.img
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
STORAGE=local-lvm  
GW=192.168.50.1 
DNS=192.168.50.1
VLAN=50
BRIDGE=vmbr1 
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
echo "----------------------------------------------------------------------------------------"
echo "Install Ubuntu 22.04 VM template ..."
echo "----------------------------------------------------------------------------------------"
echo "Post-task: login to the ubuntu user, copy the setup file, and run it."
echo "----------------------------------------------------------------------------------------"