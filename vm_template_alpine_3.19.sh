#!/bin/bash

echo "-----------------------------------------------------------------"
echo "Create a Linux alpine 3.19 template VM"
echo "-----------------------------------------------------------------"

# [x] Load common configs from the common scripts
echo "Load common configs from the common scripts"
source lib/common_vm_scripts.sh

# [x] Specific VM template configurations
# Specific configs
TEMPLATE_VM_ID=5001
TEMPLATE_TYPE=template
TEMPLATE_OS=alpine
TEMPLATE_VERSION=3.19
RAM=512
CORES=1
IP=192.168.50.2/24
DISKIMAGE_SIZE=1 

IMAGE_URL=https://filedn.com/luEnu9wIDvzholR0Mi4tGLb/linux_images/alpine_3.19_image.raw
IMAGE_NAME=alpine_3.19_image.raw
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
### Start the VM template, wait it to start, and then execute the setup script 
sudo qm start $TEMPLATE_VM_ID
sleep 30
ssh $DEFAULT_USER@$IP 'sh -s' < os_system_setup.sh
ssh abc@192.168.50.2 'sh -s' < os_system_setup.sh




#############################################################
echo "----------------------------------------------------------------------------------------"
echo "Install Alpine linux VM template ..."
echo "----------------------------------------------------------------------------------------"
echo "Post-task: login to the ubuntu user, copy the setup file, and run it."
echo "----------------------------------------------------------------------------------------"


# TODO

#doas apk add parted
#doas parted -s -a opt /dev/sda "print free" "resizepart 3 100%" "print free"

#pvresize /dev/sda2 # extend the physical volume /dev/sda2
#pvdisplay # to check
#lvextend -l +100%FREE  /dev/vg0/lv_root
#resize2fs /dev/vg0/lv_root
# ---> in the VM:
