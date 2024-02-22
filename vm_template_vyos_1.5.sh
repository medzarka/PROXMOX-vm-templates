#!/bin/bash

echo "-----------------------------------------------------------------"
echo "Create a VyOS 1.5 template VM"
echo "-----------------------------------------------------------------"

# [x] Load common configs from the common scripts
echo "Load common configs from the common scripts"
source lib/common_vm_scripts.sh

# [x] Specific VM template configurations
# Specific configs
TEMPLATE_VM_ID=5350
TEMPLATE_TYPE=template
TEMPLATE_OS=vyos
TEMPLATE_VERSION=1.5
RAM=1024
CORES=1
IP=192.168.10.253/24
# RECHECK check the size
DISKIMAGE_SIZE=2G 

IMAGE_URL=https://filedn.com/luEnu9wIDvzholR0Mi4tGLb/linux_images/vyos_1.5_image.raw
IMAGE_NAME=vyos_1.5_image.raw
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
GW=192.168.10.254
DNS=8.8.8.8
VLAN=10
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
#template_os_setup

sudo tee user-data >/dev/null <<EOF
vyos_config_commands:
  - set system host-name 'vyos-1.5-template'
  - delete interfaces ethernet eth0 address 'dhcp'
  - set system login user "$DEFAULT_USER" authentication encrypted-password "$(openssl passwd -6 $USER_PASSWORD)"
  - set interfaces ethernet eth0 address "$IP"
  - set interfaces ethernet eth0 description 'MGMT'
  - set protocols static route 0.0.0.0/0 next-hop "$GW"
  - set system login user vyos disable
EOF

sudo tee network-config >/dev/null <<EOF
version: 2
ethernets:
  eth0:
    dhcp4: false
    dhcp6: false
EOF

sudo tee meta-data >/dev/null <<EOF
EOF

mkisofs -joliet -rock -volid "cidata" -output seed.iso meta-data user-data network-config
rm -rf /var/lib/vz/template/iso/seed.iso
mv seed.iso /var/lib/vz/template/iso/
qm set $TEMPLATE_VM_ID --ide2 none
qm set $TEMPLATE_VM_ID --ide2 media=cdrom,file=local:iso/seed.iso

#############################################################
### Convert the VM to a template
#convert_vm_to_template

qm start $TEMPLATE_VM_ID
#qm shutdown $TEMPLATE_VM_ID --forceStop 1 --timeout 60
#vzdump $TEMPLATE_VM_ID --mode stop --mailto root 
#qm template $TEMPLATE_VM_ID


rm -rf user-data
rm -rf network-config
rm -rf meta-data

#############################################################
echo "----------------------------------------------------------------------------------------"
echo "Done for Vyos 1.5 VM template ..."
echo "----------------------------------------------------------------------------------------"