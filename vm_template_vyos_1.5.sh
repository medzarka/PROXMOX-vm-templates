#!/bin/bash

#### To create a vyos image, we can proceed as follows but on machine different to proxmox:
#sudo apt update
#sudo apt install -y ansible python3
#sudo apt  install docker.io
#sudo wget https://raw.githubusercontent.com/vyos/vyos-vm-images/current/Dockerfile
#sudo docker build --tag vyos-vm-images:latest -f ./Dockerfile .
#mkdir vyos-build
#chmod -R 777 vyos-build 
#sudo docker run --rm -it --privileged -v $(pwd)/vyos-build:/tmp -v $(pwd):/vm-build -v $(pwd)/images:/images -w /vm-build vyos-vm-images:latest bash


## Start inside the docker image: --------------------------------------------------------------------
#wget https://github.com/vyos/vyos-rolling-nightly-builds/releases/download/1.5-rolling-202402220022/vyos-1.5-rolling-202402220022-amd64.iso \
#    -O /tmp/vyos.iso
#git clone https://github.com/vyos/vyos-vm-images.git && cd vyos-vm-images
#ansible-playbook qemu.yml -e disk_size=2 \
#    -e iso_local=/tmp/vyos.iso -e grub_console=serial -e vyos_version=1.5.0 -e enable_ssh=true \
#    -e cloud_init=true -e cloud_init_ds=NoCloud -e guest_agent=qemu -e keep_user=true
#exit
## End inside the docker image: --------------------------------------------------------------------
# --> the image is now available in the vyos-build folder.



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

IMAGE_URL=https://filedn.com/luEnu9wIDvzholR0Mi4tGLb/linux_images/vyos-1.5.0-cloud-init-2G-qemu.qcow2
IMAGE_NAME=vyos-1.5.0-cloud-init-2G-qemu.qcow2
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
#cloud-config
vyos_config_commands:
  - configure
  - set system host-name 'vyos-1.5-template'
  - set service ntp server 1.pool.ntp.org
  - set service ntp server 2.pool.ntp.org
  - delete interfaces ethernet eth0 address 'dhcp'
  - set interfaces ethernet eth0 address '192.168.10.252/24'
  - set interfaces ethernet eth0 description 'VYOS-TEMPLATE'
  - set protocols static route 0.0.0.0/0 next-hop '192.168.10.254'
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

mkisofs -joliet -rock -volid "cidata" -output /tmp/seed.iso meta-data user-data network-config
rm -rf /var/lib/vz/template/iso/seed.iso
mv /tmp/seed.iso /var/lib/vz/template/iso/
qm set $TEMPLATE_VM_ID --ide2 none
qm set $TEMPLATE_VM_ID --ide2 media=cdrom,file=local:iso/seed.iso

#############################################################
### Convert the VM to a template
convert_vm_to_template

#qm start $TEMPLATE_VM_ID
#qm shutdown $TEMPLATE_VM_ID --forceStop 1 --timeout 60
#vzdump $TEMPLATE_VM_ID --mode stop --mailto root 
#qm template $TEMPLATE_VM_ID


#rm -rf user-data
#rm -rf network-config
#rm -rf meta-data

#############################################################
echo "----------------------------------------------------------------------------------------"
echo "Done for Vyos 1.5 VM template ..."
echo "----------------------------------------------------------------------------------------"