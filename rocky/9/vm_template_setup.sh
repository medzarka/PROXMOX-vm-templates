#!/bin/bash

# Create a Rocky Linux 9 based VM
IMAGE_URL=https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
IMAGE_NAME=Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
IMAGE_PATH=/var/lib/vz/template/cache/$IMAGE_NAME
TEMPLATE_VM_ID=5401
TEMPLATE_NAME=template-rocky-9
RAM=1024
CORES=1
BRIDGE=vmbr1
VLAN=30
DISKIMAGE_SIZE=4G
STORAGE=local-lvm
TAGS=_template,os_rocky,v-9
USER_NAME=rocky
DNS=192.168.30.1
DOMAIN=xxxxxxxxxxxxxxxxxx
USER_PASSWORD=$(pass pve01/vms/"$TEMPLATE_VM_ID")
if [[ -z "$USER_PASSWORD" ]]; then
    # $USER_PASSWORD is empty, create new one
    pass generate pve01/vms/"$TEMPLATE_VM_ID" $PASSWORD_LENGTH 50 -n
    USER_PASSWORD=$(pass pve01/vms/"$TEMPLATE_VM_ID")
fi

#############################################################
echo "Destroy the old template..."
sudo qm stop $TEMPLATE_VM_ID
sudo qm destroy $TEMPLATE_VM_ID --destroy-unreferenced-disks 1 --purge 1

#############################################################
echo "Download the Rocky cloudInit image ..."
if [ -e $IMAGE_PATH ]
then
    echo "The CloudInit image is already downloaded."
else
    wget -O $IMAGE_PATH  $IMAGE_URL
    du -sh $IMAGE_PATH
    qemu-img resize $IMAGE_PATH $DISKIMAGE_SIZE
    du -sh $IMAGE_PATH
fi

#############################################################
echo "Create the new machine ..."
sudo qm create $TEMPLATE_VM_ID --name $TEMPLATE_NAME 
sudo qm set $TEMPLATE_VM_ID --net0 virtio,bridge=$BRIDGE,tag=$VLAN
sudo qm set $TEMPLATE_VM_ID --memory $RAM
sudo qm set $TEMPLATE_VM_ID --machine q35
sudo qm set $TEMPLATE_VM_ID --numa 1
sudo qm set $TEMPLATE_VM_ID --bios ovmf
sudo qm set $TEMPLATE_VM_ID --efidisk0 local-lvm:0,pre-enrolled-keys=0
sudo qm set $TEMPLATE_VM_ID --ostype l26
sudo qm set $TEMPLATE_VM_ID --cores $CORES --cpu cputype=host
sudo qm set $TEMPLATE_VM_ID --scsihw virtio-scsi-single 
#sudo pvesm alloc $STORAGE $TEMPLATE_VM_ID '' $DISKIMAGE_SIZE 
sudo qm importdisk $TEMPLATE_VM_ID $IMAGE_PATH $STORAGE
sudo qm set $TEMPLATE_VM_ID --scsi0 $STORAGE:vm-$TEMPLATE_VM_ID-disk-1,aio=io_uring,cache=unsafe,discard=on,iothread=1,ssd=1
sudo qm set $TEMPLATE_VM_ID --boot c --bootdisk scsi0
sudo qm set $TEMPLATE_VM_ID --tablet 0
sudo qm set $TEMPLATE_VM_ID --serial0 socket --vga serial0
sudo qm set $TEMPLATE_VM_ID --agent enabled=1 # optional but recommened
sudo qm set $TEMPLATE_VM_ID --tags $TAGS
sudo qm set $TEMPLATE_VM_ID --ide2 local-lvm:cloudinit
sudo qm set $TEMPLATE_VM_ID --ciuser $USER_NAME
sudo qm set $TEMPLATE_VM_ID --cipassword $(openssl passwd -6 $USER_PASSWORD)
sudo qm set $TEMPLATE_VM_ID --sshkey /root/.ssh/id_rsa.pub
sudo qm set $TEMPLATE_VM_ID --ipconfig0 ip=dhcp,ip6=auto
#qm set 101 --ipconfig0 ip=192.168.30.2/24,gw=192.168.30.1,ip6=auto
sudo qm set $TEMPLATE_VM_ID --nameserver $DNS
sudo qm set $TEMPLATE_VM_ID --searchdomain $DOMAIN 


#############################################################
echo "Install Rocky Linux 9 ..."
echo "----------------------------------------------------------------------------------------"
echo "Post-task: login to the rocky user, copy the setup file, and run it."
echo "----------------------------------------------------------------------------------------"