#!/bin/bash

echo "-----------------------------------------------------------------"
echo "Create a Rocky Linux 9 template VM"
echo "-----------------------------------------------------------------"

# [x] Load common configs from the common scripts
echo "Load common configs from the common scripts"
source lib/common_vm_scripts.sh

# [x] Specific VM template configurations
# Specific configs
TEMPLATE_VM_ID=5021
TEMPLATE_TYPE=template
TEMPLATE_OS=rocky
TEMPLATE_VERSION=9
RAM=1024
CORES=1
IP=192.168.50.21/24
# RECHECK check the size
DISKIMAGE_SIZE=0G

IMAGE_URL=https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
IMAGE_NAME=Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
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
STORAGE=local-zfs     
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
### Start the VM template, wait it to start, and then execute the setup script 
template_os_setup

#############################################################
### Convert the VM to a template
convert_vm_to_template

#############################################################
echo "----------------------------------------------------------------------------------------"
echo "Done for Rocky Linux 9 VM template ..."
echo "----------------------------------------------------------------------------------------"