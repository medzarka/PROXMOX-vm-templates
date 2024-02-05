#!/bin/bash

echo "-----------------------------------------------------------------"
echo "Create a Linux alpine 3.19 template VM"
echo "-----------------------------------------------------------------"

# [x] Load common configs from the common scripts
echo "Load common configs from the common scripts"
source ../lib/common_vm_scripts.sh

# [x] Specific VM template configurations
# Specific configs
TEMPLATE_VM_ID=5001
TEMPLATE_TYPE=template
TEMPLATE_OS=alpine
TEMPLATE_VERSION=3.19
RAM=512
CORES=1
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
echo "Install alpine 3.19 ..."
echo "----------------------------------------------------------------------------------------"
echo "This process is manual:"
echo "     -  In the boot process, press ESC to select boot. Then select the install cdrom,"
echo "     -  Login with root username (no password will be required),"
echo "     -  Type: setup-alpine,"
echo "     -  As a hostname, select: template-alpine-3.19,"
echo "     -  As network interface, type eth0,"
echo "     -  As network address, type dhcp,"
echo "     -  As network interface, type eth0, then no,"
echo "     -  Type a password for the root user,"
echo "     -  Type Asia/Riyadh as a timezone"
echo "     -  If it asks to create new user, answer with no,"
echo "     -  Select openssh as an ssh server,"
echo "     -  For the install disk, type sda, then lvm, and finally sys,"
echo "     -  Reboot."
echo "----------------------------------------------------------------------------------------"
echo "Notice: you can delete the Install CROM after the install."
echo "----------------------------------------------------------------------------------------"
echo "Post-task: login to the root user, copy the setup file, and run it (using qm terminal VMID)."
echo "----------------------------------------------------------------------------------------"

#doas apk add parted
#doas parted -s -a opt /dev/sda "print free" "resizepart 2 100%" "print free"

#pvresize /dev/sda2 # extend the physical volume /dev/sda2
#pvdisplay # to check
#lvextend -l +100%FREE  /dev/vg0/lv_root
#resize2fs /dev/vg0/lv_root
# ---> in the VM:

